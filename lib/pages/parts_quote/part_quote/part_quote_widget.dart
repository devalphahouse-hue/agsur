import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'part_quote_model.dart';

export 'part_quote_model.dart';

/// Status possíveis de uma cotação de peças (order_parts), com rótulo pt-BR.
/// Os valores batem com o enum PartsQuote usado pelo app cliente.
const List<MapEntry<String, String>> kPartsStatuses = [
  MapEntry('pending', 'Pendente'),
  MapEntry('started', 'Aprovada'),
  MapEntry('waiting_part', 'Aguardando peça'),
  MapEntry('part_sent', 'Peça enviada'),
  MapEntry('finished', 'Concluída'),
  MapEntry('refused', 'Recusada'),
];

String partsStatusLabel(String s) => kPartsStatuses
    .firstWhere((e) => e.key == s, orElse: () => MapEntry(s, s.isEmpty ? '—' : s))
    .value;

AppStatusTone partsStatusTone(String s) {
  switch (s) {
    case 'refused':
      return AppStatusTone.danger;
    case 'finished':
    case 'part_sent':
      return AppStatusTone.success;
    case 'pending':
      return AppStatusTone.warning;
    default:
      return AppStatusTone.brand;
  }
}

class PartQuoteWidget extends StatefulWidget {
  const PartQuoteWidget({super.key});

  static String routeName = 'PartQuote';
  static String routePath = '/partQuote';

  @override
  State<PartQuoteWidget> createState() => _PartQuoteWidgetState();
}

class _PartQuoteWidgetState extends State<PartQuoteWidget> {
  late PartQuoteModel _model;
  Completer<List<OrderPartsRow>>? _completer;
  String _query = '';
  String _status = 'all';
  Map<String, String> _oficinaNames = {};

  static const _statusOptions = [
    MapEntry('all', 'Todos'),
    MapEntry('pending', 'Pendente'),
    MapEntry('started', 'Aprovada'),
    MapEntry('refused', 'Recusada'),
    MapEntry('finished', 'Concluída'),
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PartQuoteModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _refresh() => safeSetState(() => _completer = null);

  Future<List<OrderPartsRow>> _load() async {
    final orders = await OrderPartsTable().queryRows(
      queryFn: (q) => q.order('created_at', ascending: false),
    );
    final ids = orders.map((o) => o.userId).toSet().toList();
    if (ids.isNotEmpty) {
      final users = await UsersTable().queryRows(
        queryFn: (q) => q.inFilter('id', ids),
      );
      _oficinaNames = {
        for (final u in users) u.id: (u.fullname ?? u.name ?? '—'),
      };
    }
    return orders;
  }

  Future<void> _openReview(OrderPartsRow order) async {
    final parts = await RequestedPartsTable().queryRows(
      queryFn: (q) => q.eqOrNull('order_id', order.id).order('created_at'),
    );
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        alignment: Alignment.center,
        child: _ReviewModal(
          order: order,
          parts: parts,
          oficina: _oficinaNames[order.userId] ?? '—',
          onSaved: (msg) {
            Navigator.of(dialogContext).pop();
            _refresh();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg,
                    style: const TextStyle(color: Color(0xFF313131))),
                backgroundColor: const Color(0xFFC2D51C),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      eyebrow: 'Operação',
      title: 'Cotação de peças',
      description:
          'Cotações enviadas pelas oficinas no app. Abra para revisar as '
          'peças e aprovar, recusar (com motivo) ou atualizar o status.',
      search: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppSearchInput(
            value: _query,
            placeholder: 'Buscar por oficina ou ID...',
            onChanged: (v) => setState(() => _query = v),
          ),
          _FilterChips(
            label: 'Status',
            options: _statusOptions,
            value: _status,
            onChanged: (v) => setState(() => _status = v),
          ),
        ],
      ),
      body: FutureBuilder<List<OrderPartsRow>>(
        future: (_completer ??= Completer<List<OrderPartsRow>>()
              ..complete(_load()))
            .future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return Column(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppSkeleton.box(height: 86),
                ),
              ),
            );
          }
          final all = snap.data!;
          final list = all.where((o) {
            if (_status != 'all' && o.status != _status) return false;
            if (_query.isEmpty) return true;
            final q = _query.toLowerCase();
            final name = (_oficinaNames[o.userId] ?? '').toLowerCase();
            return name.contains(q) || o.id.toLowerCase().contains(q);
          }).toList();
          if (list.isEmpty) {
            return AppCard(
              child: AppEmptyState(
                icon: Icons.precision_manufacturing_outlined,
                title: _query.isEmpty
                    ? 'Nenhuma cotação ainda'
                    : 'Nenhuma cotação encontrada',
                description: _query.isEmpty
                    ? 'Cotações enviadas pelas oficinas aparecem aqui.'
                    : 'Tente outro termo de busca.',
              ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PartQuoteRow(
                    item: list[i],
                    oficina: _oficinaNames[list[i].userId] ?? '—',
                    onTap: () => _openReview(list[i]),
                  ).appStagger(i),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PartQuoteRow extends StatelessWidget {
  const _PartQuoteRow({
    required this.item,
    required this.oficina,
    required this.onTap,
  });
  final OrderPartsRow item;
  final String oficina;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x33C2D51C),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.precision_manufacturing_outlined,
                color: Color(0xFFC2D51C), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  oficina,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enviada em ${dateTimeFormat('dd/MM/yyyy', item.createdAt)}',
                  style: GoogleFonts.roboto(
                    fontSize: 11.5,
                    color: const Color(0x99FFFFFF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppStatusBadge(
            label: partsStatusLabel(item.status),
            tone: partsStatusTone(item.status),
            dense: true,
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Color(0x99FFFFFF)),
        ],
      ),
    );
  }
}

class _ReviewModal extends StatefulWidget {
  const _ReviewModal({
    required this.order,
    required this.parts,
    required this.oficina,
    required this.onSaved,
  });
  final OrderPartsRow order;
  final List<RequestedPartsRow> parts;
  final String oficina;
  final void Function(String message) onSaved;

  @override
  State<_ReviewModal> createState() => _ReviewModalState();
}

class _ReviewModalState extends State<_ReviewModal> {
  late String _status = widget.order.status;
  late final TextEditingController _reason =
      TextEditingController(text: widget.order.reason ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_status == 'refused' && _reason.text.trim().isEmpty) {
      setState(() => _error = 'Informe o motivo da recusa.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await OrderPartsTable().update(
        data: {
          'status': _status,
          'reason': _reason.text.trim().isEmpty ? null : _reason.text.trim(),
        },
        matchingRows: (rows) => rows.eqOrNull('id', widget.order.id),
      );
      widget.onSaved('Cotação atualizada para "${partsStatusLabel(_status)}".');
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Não foi possível salvar. Tente novamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.precision_manufacturing_outlined,
      title: 'Revisar cotação',
      description: '${widget.oficina} · enviada em '
          '${dateTimeFormat('dd/MM/yyyy', widget.order.createdAt)}',
      maxWidth: 640,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          AppPrimaryButton(
            label: 'Salvar',
            icon: Icons.check_rounded,
            busy: _saving,
            onPressed: _save,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label('Peças solicitadas (${widget.parts.length})'),
          const SizedBox(height: 8),
          if (widget.parts.isEmpty)
            Text(
              'Nenhuma peça nesta cotação.',
              style: GoogleFonts.roboto(
                  fontSize: 12.5, color: const Color(0x99FFFFFF)),
            )
          else
            ...widget.parts.map((p) => _PartLine(p)),
          const SizedBox(height: 18),
          _Label('Status'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in kPartsStatuses)
                _StatusChip(
                  label: s.value,
                  selected: _status == s.key,
                  onTap: () => setState(() => _status = s.key),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _Label('Motivo / observação'),
          const SizedBox(height: 6),
          TextField(
            controller: _reason,
            maxLines: 3,
            style: GoogleFonts.roboto(color: Colors.white, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: _status == 'refused'
                  ? 'Obrigatório ao recusar — explique o porquê'
                  : 'Opcional — visível para a oficina no app',
              hintStyle: GoogleFonts.roboto(
                  color: const Color(0x66FFFFFF), fontSize: 13),
              filled: true,
              fillColor: const Color(0x14FFFFFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: GoogleFonts.roboto(
                  fontSize: 12, color: const Color(0xFFFF7B82)),
            ),
          ],
        ],
      ),
    );
  }
}

class _PartLine extends StatelessWidget {
  const _PartLine(this.p);
  final RequestedPartsRow p;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF313131),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'P/N ${p.pn}',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                if ((p.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    p.description!,
                    style: GoogleFonts.roboto(
                        fontSize: 12, color: const Color(0xCCFFFFFF)),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x33C2D51C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Qtd ${p.qty}',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFC2D51C)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0x33C2D51C) : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? const Color(0xFFC2D51C) : const Color(0x22FFFFFF),
            width: 1.4,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFFC2D51C) : const Color(0xCCFFFFFF),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: const Color(0x88FFFFFF),
        letterSpacing: 0.6,
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<MapEntry<String, String>> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0x99FFFFFF),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              dropdownColor: const Color(0xFF2A2A2A),
              icon: const Icon(Icons.expand_more_rounded,
                  color: Color(0xFFC2D51C), size: 18),
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              items: [
                for (final opt in options)
                  DropdownMenuItem(value: opt.key, child: Text(opt.value)),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
