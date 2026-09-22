import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/stock.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import 'stock_widgets.dart';

/// Entrada de estoque, em dois modos:
///
/// - **Digitar:** um modelo, N números de série (um por linha) e as datas
///   comuns ao lote.
/// - **Colar da planilha:** uma aeronave por linha, com nº de série e data de
///   fabricação (reunião de 2026-09-22: popular o estoque pela planilha do
///   cliente, que só traz Modelo, Série e Fabricação).
///
/// A **entrega é calculada** como fabricação + [kStockDeliveryOffsetDays] e
/// fica editável; o prazo de configuração é opcional. Grava pela RPC
/// `stock_entry` (migrations 20260922120000 e 20260922160000), que aplica a
/// mesma regra de entrega quando a data não vem informada.
///
/// Devolve a quantidade de aeronaves que entraram (ou `null` se cancelou).
class StockEntryModal extends StatefulWidget {
  const StockEntryModal({super.key});

  @override
  State<StockEntryModal> createState() => _StockEntryModalState();
}

class _StockEntryModalState extends State<StockEntryModal> {
  final _serials = TextEditingController();
  final _sheet = TextEditingController();
  final _prefix = TextEditingController();
  final _note = TextEditingController();

  late final Future<List<AircraftsRow>> _catalog = AircraftsTable().queryRows(
    queryFn: (q) => q
        .eqOrNull('active', true)
        .eqOrNull('deleted', false)
        .order('aircraft_model', ascending: true),
  );

  bool _sheetMode = false;
  AircraftsRow? _model;
  String _reason = kStockEntryReasons.first;
  DateTime? _manufacture;
  DateTime? _configDeadline;
  DateTime? _delivery;
  bool _deliveryTouched = false;
  bool _busy = false;
  bool _tried = false;

  @override
  void dispose() {
    _serials.dispose();
    _sheet.dispose();
    _prefix.dispose();
    _note.dispose();
    super.dispose();
  }

  ParsedSerials get _parsed => parseSerials(_serials.text);
  ParsedSheet get _parsedSheet => parseStockSheet(_sheet.text);

  int get _count =>
      _sheetMode ? _parsedSheet.units.length : _parsed.serials.length;

  String? get _serialError {
    final p = _parsed;
    if (p.serials.isEmpty) return 'Informe o número de série de cada aeronave';
    if (p.duplicates.isNotEmpty) {
      return 'Repetido no lote: ${p.duplicates.join(', ')}';
    }
    return null;
  }

  /// Fabricação escolhida: a entrega acompanha, até alguém mexer nela.
  void _setManufacture(DateTime d) {
    setState(() {
      _manufacture = d;
      if (!_deliveryTouched) _delivery = estimateStockDelivery(d);
    });
  }

  Future<void> _submit() async {
    setState(() => _tried = true);
    final sheet = _parsedSheet;
    if (_model == null) return;
    if (_sheetMode) {
      if (sheet.units.isEmpty || sheet.problems.isNotEmpty) return;
    } else {
      if (_serialError != null || _manufacture == null) return;
    }

    final units = _sheetMode
        ? [
            for (final u in sheet.units)
              {
                'serial_number': u.serialNumber,
                'manufacture_date': stockDateParam(u.manufacture),
                // Entrega e ano base ficam com a regra do banco
                // (fabricação + 60 dias).
              },
          ]
        : [
            for (final s in _parsed.serials)
              {
                'serial_number': s,
                if (_parsed.serials.length == 1 &&
                    _prefix.text.trim().isNotEmpty)
                  'registration_prefix': _prefix.text.trim(),
                'manufacture_date': stockDateParam(_manufacture),
                if (_configDeadline != null)
                  'configuration_deadline': stockDateParam(_configDeadline),
                if (_delivery != null)
                  'delivery_date': stockDateParam(_delivery),
              },
          ];

    setState(() => _busy = true);
    try {
      await SupaFlow.client.rpc('stock_entry', params: {
        'p_aircraft_model': _model!.id,
        'p_reason': _reason,
        'p_note': _note.text.trim(),
        'p_units': units,
      });
      // Quem abriu mostra o sucesso: o contexto do modal morre no pop.
      if (mounted) Navigator.of(context).pop(units.length);
    } catch (e, st) {
      // O modal fica aberto (preserva o que foi digitado) e explica o erro —
      // o caso comum é serial que já existe no estoque (23505).
      if (!mounted) return;
      setState(() => _busy = false);
      reportStockError(context, e, st,
          fallback: 'Não foi possível registrar a entrada.',
          contexto: 'estoque.entrada');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.move_to_inbox_rounded,
      title: 'Registrar entrada',
      description:
          'Cada aeronave entra com o próprio número de série. A entrega é '
          'calculada como fabricação + $kStockDeliveryOffsetDays dias e pode '
          'ser ajustada.',
      maxWidth: 660,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Cancelar',
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 10),
          AppPrimaryButton(
            label: _count > 1 ? 'Dar entrada em $_count' : 'Dar entrada',
            icon: Icons.check_rounded,
            busy: _busy,
            onPressed: _submit,
          ),
        ],
      ),
      child: FutureBuilder<List<AircraftsRow>>(
        future: _catalog,
        builder: (context, snap) {
          if (!snap.hasData) {
            return Column(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppSkeleton.box(height: 60),
                ),
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveRow(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppDropdown<AircraftsRow>(
                      label: 'Modelo do catálogo',
                      icon: Icons.flight_outlined,
                      required: true,
                      searchable: true,
                      value: _model,
                      options: snap.data!,
                      labelOf: (a) =>
                          a.featured ? '★ ${a.aircraftModel}' : a.aircraftModel,
                      errorText:
                          _tried && _model == null ? 'Selecione o modelo' : null,
                      onChanged: (a) => setState(() => _model = a),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppDropdown<String>(
                      label: 'Motivo',
                      icon: Icons.label_outline_rounded,
                      required: true,
                      value: _reason,
                      options: kStockEntryReasons,
                      labelOf: stockReasonLabel,
                      onChanged: (r) => setState(() => _reason = r),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ModeTabs(
                sheetMode: _sheetMode,
                onChanged: (v) => setState(() {
                  _sheetMode = v;
                  _tried = false;
                }),
              ),
              const SizedBox(height: 12),
              if (_sheetMode) ..._sheetFields() else ..._manualFields(),
              const SizedBox(height: 14),
              AppFormField(
                controller: _note,
                label: 'Observação',
                placeholder: 'Nota fiscal, fornecedor, embarque...',
                icon: Icons.notes_rounded,
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Modo "colar da planilha" ─────────────────────────────────────────────

  List<Widget> _sheetFields() {
    final sheet = _parsedSheet;
    return [
      AppFormField(
        controller: _sheet,
        label: 'Uma aeronave por linha: nº de série e data de fabricação',
        placeholder: '402B-1560   10/03/2026\n402B-1561   01/04/2026',
        icon: Icons.table_rows_rounded,
        helper: 'Copie as colunas da planilha e cole aqui. Separador: '
            'tabulação, ponto e vírgula ou vírgula.',
        required: true,
        maxLines: 8,
        onChanged: (_) => setState(() {}),
      ),
      if (sheet.units.isNotEmpty) ...[
        const SizedBox(height: 10),
        _SheetPreview(units: sheet.units),
      ],
      if (_tried && sheet.problems.isNotEmpty) ...[
        const SizedBox(height: 8),
        for (final p in sheet.problems)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              p,
              style: GoogleFonts.roboto(
                  fontSize: 11.5, color: const Color(0xFFFF7B82)),
            ),
          ),
      ],
    ];
  }

  // ── Modo "digitar" ───────────────────────────────────────────────────────

  List<Widget> _manualFields() {
    final count = _parsed.serials.length;
    return [
      AppFormField(
        controller: _serials,
        label: 'Números de série',
        placeholder: 'Um por linha — ex.:\n402B-1560\n402B-1561',
        icon: Icons.tag_rounded,
        helper: count == 0
            ? 'Obrigatório. Cole vários de uma vez, um por linha.'
            : count == 1
                ? '1 aeronave'
                : '$count aeronaves',
        required: true,
        maxLines: 4,
        onChanged: (_) => setState(() {}),
      ),
      if (_tried && _serialError != null) ...[
        const SizedBox(height: 6),
        Text(
          _serialError!,
          style: GoogleFonts.roboto(
              fontSize: 11.5, color: const Color(0xFFFF7B82)),
        ),
      ],
      if (count == 1) ...[
        const SizedBox(height: 14),
        AppFormField(
          controller: _prefix,
          label: 'Prefixo (matrícula)',
          placeholder: 'Ex.: PR-ABC — deixe vazio se ainda não tem',
          icon: Icons.badge_outlined,
        ),
      ],
      const SizedBox(height: 14),
      ResponsiveRow(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: StockDateField(
              label: 'Fabricação',
              date: _manufacture,
              errorText: _tried && _manufacture == null ? 'Obrigatório' : null,
              onChanged: _setManufacture,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StockDateField(
              label: 'Entrega estimada',
              date: _delivery,
              required: false,
              onChanged: (d) => setState(() {
                _delivery = d;
                _deliveryTouched = true;
              }),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StockDateField(
              label: 'Prazo de configuração',
              date: _configDeadline,
              required: false,
              onChanged: (d) => setState(() => _configDeadline = d),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        _manufacture == null
            ? 'A entrega é preenchida sozinha com fabricação + '
                '$kStockDeliveryOffsetDays dias; o prazo de configuração é opcional.'
            : _deliveryTouched
                ? 'Entrega ajustada à mão.'
                : 'Entrega calculada: fabricação + $kStockDeliveryOffsetDays dias.',
        style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0x99FFFFFF)),
      ),
      if (count > 1) ...[
        const SizedBox(height: 6),
        Text(
          'As datas valem para as $count aeronaves. Datas diferentes por '
          'aeronave: use "Colar da planilha".',
          style:
              GoogleFonts.inter(fontSize: 11.5, color: const Color(0x99FFFFFF)),
        ),
      ],
    ];
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.sheetMode, required this.onChanged});

  final bool sheetMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, IconData icon, bool selected, VoidCallback onTap) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  selected ? const Color(0xFFC2D51C) : const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: selected
                    ? const Color(0xFFC2D51C)
                    : const Color(0x33FFFFFF),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 15,
                    color: selected
                        ? const Color(0xFF313131)
                        : const Color(0xCCFFFFFF)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? const Color(0xFF313131)
                        : const Color(0xCCFFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab('Digitar', Icons.keyboard_alt_outlined, !sheetMode,
            () => onChanged(false)),
        const SizedBox(width: 8),
        tab('Colar da planilha', Icons.content_paste_rounded, sheetMode,
            () => onChanged(true)),
      ],
    );
  }
}

/// Prévia do que será criado: o usuário confere antes de gravar, inclusive a
/// entrega calculada.
class _SheetPreview extends StatelessWidget {
  const _SheetPreview({required this.units});

  final List<SheetUnit> units;

  @override
  Widget build(BuildContext context) {
    final shown = units.take(6).toList();
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            units.length == 1
                ? '1 aeronave nesta lista'
                : '${units.length} aeronaves nesta lista',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          for (final u in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                'S/N ${u.serialNumber} · fab. ${formatStockDate(u.manufacture)} · '
                'entrega ${formatStockDate(estimateStockDelivery(u.manufacture))}',
                style: GoogleFonts.roboto(
                    fontSize: 11.5, color: const Color(0xB3FFFFFF)),
              ),
            ),
          if (units.length > shown.length)
            Text(
              '+ ${units.length - shown.length} outra(s)',
              style: GoogleFonts.roboto(
                  fontSize: 11.5, color: const Color(0x99FFFFFF)),
            ),
        ],
      ),
    );
  }
}
