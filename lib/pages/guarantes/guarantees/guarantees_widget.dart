import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'guarantees_model.dart';

export 'guarantees_model.dart';

/// Status de uma solicitação de garantia (enum warranty_request), com rótulo.
const List<MapEntry<String, String>> kGuaranteeStatuses = [
  MapEntry('requested', 'Solicitada'),
  MapEntry('in_progress', 'Em andamento'),
  MapEntry('sent', 'Enviada'),
  MapEntry('received', 'Recebida'),
  MapEntry('waiting_damaged_part', 'Aguardando peça'),
  MapEntry('finished', 'Concluída'),
  MapEntry('denied', 'Negada'),
];

String guaranteeStatusLabel(String s) => kGuaranteeStatuses
    .firstWhere((e) => e.key == s,
        orElse: () => MapEntry(s, s.isEmpty ? '—' : s))
    .value;

AppStatusTone guaranteeStatusTone(String s) {
  switch (s) {
    case 'denied':
      return AppStatusTone.danger;
    case 'finished':
    case 'received':
      return AppStatusTone.success;
    case 'requested':
      return AppStatusTone.warning;
    default:
      return AppStatusTone.brand;
  }
}

class GuaranteesWidget extends StatefulWidget {
  const GuaranteesWidget({super.key});

  static String routeName = 'Guarantees';
  static String routePath = '/guarantees';

  @override
  State<GuaranteesWidget> createState() => _GuaranteesWidgetState();
}

class _GuaranteesWidgetState extends State<GuaranteesWidget> {
  late GuaranteesModel _model;
  Completer<List<GuaranteeRow>>? _completer;
  String _query = '';
  String _status = 'all';
  Map<String, String> _requesterNames = {};

  static const _statusOptions = [
    MapEntry('all', 'Todas'),
    MapEntry('requested', 'Solicitada'),
    MapEntry('in_progress', 'Em andamento'),
    MapEntry('finished', 'Concluída'),
    MapEntry('denied', 'Negada'),
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GuaranteesModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _refresh() => safeSetState(() => _completer = null);

  Future<List<GuaranteeRow>> _load() async {
    final rows = await GuaranteeTable().queryRows(
      queryFn: (q) =>
          q.eqOrNull('deleted', false).order('created_at', ascending: false),
    );
    final ids = rows.map((r) => r.userId).toSet().toList();
    if (ids.isNotEmpty) {
      final users = await UsersTable().queryRows(
        queryFn: (q) => q.inFilter('id', ids),
      );
      _requesterNames = {
        for (final u in users) u.id: (u.fullname ?? u.name ?? '—'),
      };
    }
    return rows;
  }

  Future<void> _openReview(GuaranteeRow g) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        alignment: Alignment.center,
        child: _GuaranteeReviewModal(
          guarantee: g,
          requester: _requesterNames[g.userId] ?? '—',
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
      title: 'Garantias',
      description:
          'Solicitações de garantia enviadas pelas oficinas/clientes no app. '
          'Abra para revisar as informações e atualizar o status.',
      search: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppSearchInput(
            value: _query,
            placeholder: 'Buscar por solicitante, aeronave, peça ou ID...',
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
      body: FutureBuilder<List<GuaranteeRow>>(
        future: (_completer ??= Completer<List<GuaranteeRow>>()
              ..complete(_load()))
            .future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return Column(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppSkeleton.box(height: 92),
                ),
              ),
            );
          }
          final all = snap.data!;
          final list = all.where((g) {
            if (_status != 'all' && g.status != _status) return false;
            if (_query.isEmpty) return true;
            final q = _query.toLowerCase();
            final name = (_requesterNames[g.userId] ?? '').toLowerCase();
            return name.contains(q) ||
                g.nameAircraft.toLowerCase().contains(q) ||
                g.partNumber.toLowerCase().contains(q) ||
                g.idRef.toLowerCase().contains(q);
          }).toList();
          if (list.isEmpty) {
            return AppCard(
              child: AppEmptyState(
                icon: Icons.verified_user_outlined,
                title: _query.isEmpty
                    ? 'Nenhuma garantia ainda'
                    : 'Nenhuma garantia encontrada',
                description: _query.isEmpty
                    ? 'Solicitações de garantia das oficinas/clientes aparecem aqui.'
                    : 'Tente outro termo de busca.',
              ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _GuaranteeRow(
                    item: list[i],
                    requester: _requesterNames[list[i].userId] ?? '—',
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

class _GuaranteeRow extends StatelessWidget {
  const _GuaranteeRow({
    required this.item,
    required this.requester,
    required this.onTap,
  });
  final GuaranteeRow item;
  final String requester;
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
            child: const Icon(Icons.verified_user_outlined,
                color: Color(0xFFC2D51C), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'ID ${item.idRef}',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        requester,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                            fontSize: 12.5, color: const Color(0xCCFFFFFF)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (item.nameAircraft.isNotEmpty)
                      _Meta(Icons.flight_outlined, item.nameAircraft),
                    if (item.partNumber.isNotEmpty)
                      _Meta(Icons.tag_rounded, 'P/N ${item.partNumber}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppStatusBadge(
            label: guaranteeStatusLabel(item.status),
            tone: guaranteeStatusTone(item.status),
            dense: true,
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Color(0x99FFFFFF)),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0x99FFFFFF)),
        const SizedBox(width: 4),
        Text(text,
            style: GoogleFonts.roboto(
                fontSize: 11.5, color: const Color(0x99FFFFFF))),
      ],
    );
  }
}

class _GuaranteeReviewModal extends StatefulWidget {
  const _GuaranteeReviewModal({
    required this.guarantee,
    required this.requester,
    required this.onSaved,
  });
  final GuaranteeRow guarantee;
  final String requester;
  final void Function(String message) onSaved;

  @override
  State<_GuaranteeReviewModal> createState() => _GuaranteeReviewModalState();
}

class _GuaranteeReviewModalState extends State<_GuaranteeReviewModal> {
  late String _status = widget.guarantee.status;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await GuaranteeTable().update(
        data: {'status': _status},
        matchingRows: (rows) => rows.eqOrNull('id', widget.guarantee.id),
      );
      widget.onSaved(
          'Garantia atualizada para "${guaranteeStatusLabel(_status)}".');
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
    final g = widget.guarantee;
    return AppModal(
      icon: Icons.verified_user_outlined,
      title: 'Revisar garantia',
      description: '${widget.requester} · ID ${g.idRef} · '
          '${dateTimeFormat('dd/MM/yyyy', g.createdAt)}',
      maxWidth: 680,
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
          _Section('Aeronave'),
          _DetailRow('Modelo', g.nameAircraft),
          _DetailRow('Prefixo', g.aircraftPrefix),
          _DetailRow('Serial', g.aircraftSerialKey),
          const SizedBox(height: 14),
          _Section('Peça'),
          _DetailRow('Part Number', g.partNumber),
          _DetailRow('Serial da peça', g.partSerialNumber),
          _DetailRow('Descrição', g.partDescription),
          const SizedBox(height: 14),
          _Section('Falha'),
          _DetailRow('Data', dateTimeFormat('dd/MM/yyyy', g.failureDate)),
          _DetailRow('Descrição', g.failureDescription),
          if ((g.observations ?? '').isNotEmpty)
            _DetailRow('Observações', g.observations ?? ''),
          const SizedBox(height: 14),
          _Section('Mecânico responsável'),
          _DetailRow('Oficina', g.mechanicShopName),
          _DetailRow('Nome', g.mechanicName),
          _DetailRow('Registro', g.mechanicId),
          const SizedBox(height: 18),
          _Section('Status'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in kGuaranteeStatuses)
                _StatusChip(
                  label: s.value,
                  selected: _status == s.key,
                  onTap: () => setState(() => _status = s.key),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: GoogleFonts.roboto(
                    fontSize: 12, color: const Color(0xFFFF7B82))),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFC2D51C),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: GoogleFonts.roboto(
                    fontSize: 12.5, color: const Color(0x88FFFFFF))),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: GoogleFonts.roboto(
                  fontSize: 12.5,
                  color: const Color(0xEEFFFFFF),
                  fontWeight: FontWeight.w500),
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
          Text('$label:',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0x99FFFFFF),
                  letterSpacing: 0.6)),
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
                  color: Colors.white),
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
