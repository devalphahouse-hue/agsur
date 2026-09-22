import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/stock.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import 'stock_widgets.dart';

/// Entrada de estoque: um modelo do catálogo, N aeronaves (um nº de série por
/// linha — obrigatório) e as datas comuns ao lote. Grava pela RPC
/// `stock_entry` (migration 20260922120000), que cria as unidades e lança uma
/// movimentação de entrada para cada, no mesmo lote (`batch_id`).
///
/// Devolve a quantidade de aeronaves que entraram (ou `null` se cancelou).
class StockEntryModal extends StatefulWidget {
  const StockEntryModal({super.key});

  @override
  State<StockEntryModal> createState() => _StockEntryModalState();
}

class _StockEntryModalState extends State<StockEntryModal> {
  final _serials = TextEditingController();
  final _prefix = TextEditingController();
  final _note = TextEditingController();

  late final Future<List<AircraftsRow>> _catalog = AircraftsTable().queryRows(
    queryFn: (q) => q
        .eqOrNull('active', true)
        .eqOrNull('deleted', false)
        .order('aircraft_model', ascending: true),
  );

  AircraftsRow? _model;
  String _reason = kStockEntryReasons.first;
  DateTime? _manufacture;
  DateTime? _configDeadline;
  DateTime? _delivery;
  String _entryYear = DateTime.now().year.toString();
  bool _busy = false;
  bool _tried = false;

  List<String> get _years => List.generate(
      DateTime.now().year - 2018 + 3, (i) => (2018 + i).toString());

  @override
  void dispose() {
    _serials.dispose();
    _prefix.dispose();
    _note.dispose();
    super.dispose();
  }

  ParsedSerials get _parsed => parseSerials(_serials.text);

  String? get _serialError {
    final p = _parsed;
    if (p.serials.isEmpty) return 'Informe o número de série de cada aeronave';
    if (p.duplicates.isNotEmpty) {
      return 'Repetido no lote: ${p.duplicates.join(', ')}';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() => _tried = true);
    if (_model == null ||
        _serialError != null ||
        _manufacture == null ||
        _configDeadline == null ||
        _delivery == null) {
      return;
    }
    final serials = _parsed.serials;
    final prefix = serials.length == 1 ? _prefix.text.trim() : '';
    setState(() => _busy = true);
    try {
      await SupaFlow.client.rpc('stock_entry', params: {
        'p_aircraft_model': _model!.id,
        'p_reason': _reason,
        'p_note': _note.text.trim(),
        'p_units': [
          for (final s in serials)
            {
              'serial_number': s,
              if (prefix.isNotEmpty) 'registration_prefix': prefix,
              'manufacture_date': stockDateParam(_manufacture),
              'configuration_deadline': stockDateParam(_configDeadline),
              'delivery_date': stockDateParam(_delivery),
              'entry_year': _entryYear,
            },
        ],
      });
      // Quem abriu mostra o sucesso: o contexto do modal morre no pop.
      if (mounted) Navigator.of(context).pop(serials.length);
    } catch (e, st) {
      // O modal fica aberto (preserva os seriais digitados) e explica o erro —
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
    final count = _parsed.serials.length;
    return AppModal(
      icon: Icons.move_to_inbox_rounded,
      title: 'Registrar entrada',
      description:
          'Cada aeronave entra com o próprio número de série. A quantidade do '
          'modelo no estoque sobe na hora e a entrada fica no histórico.',
      maxWidth: 640,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Cancelar',
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 10),
          AppPrimaryButton(
            label: count > 1 ? 'Dar entrada em $count' : 'Dar entrada',
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
                      labelOf: (a) => a.featured
                          ? '★ ${a.aircraftModel}'
                          : a.aircraftModel,
                      errorText: _tried && _model == null
                          ? 'Selecione o modelo'
                          : null,
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
                maxLines: 5,
                onChanged: (_) => setState(() {}),
              ),
              if (_tried && _serialError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _serialError!,
                  style: GoogleFonts.roboto(
                    fontSize: 11.5,
                    color: const Color(0xFFFF7B82),
                  ),
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
                      errorText: _tried && _manufacture == null
                          ? 'Obrigatório'
                          : null,
                      onChanged: (d) => setState(() => _manufacture = d),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StockDateField(
                      label: 'Prazo de configuração',
                      date: _configDeadline,
                      errorText: _tried && _configDeadline == null
                          ? 'Obrigatório'
                          : null,
                      onChanged: (d) => setState(() => _configDeadline = d),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StockDateField(
                      label: 'Entrega',
                      date: _delivery,
                      errorText:
                          _tried && _delivery == null ? 'Obrigatório' : null,
                      onChanged: (d) => setState(() => _delivery = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ResponsiveRow(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppDropdown<String>(
                      label: 'Ano base',
                      icon: Icons.calendar_today_rounded,
                      required: true,
                      value: _entryYear,
                      options: _years,
                      labelOf: (y) => y,
                      onChanged: (y) => setState(() => _entryYear = y),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: AppFormField(
                      controller: _note,
                      label: 'Observação',
                      placeholder: 'Nota fiscal, fornecedor, embarque...',
                      icon: Icons.notes_rounded,
                    ),
                  ),
                ],
              ),
              if (count > 1) ...[
                const SizedBox(height: 10),
                Text(
                  'As datas e o ano valem para as $count aeronaves. Prefixo e '
                  'ajustes individuais ficam na edição de cada uma.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0x99FFFFFF),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
