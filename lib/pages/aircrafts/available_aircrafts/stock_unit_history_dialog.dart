import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/backend/stock.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import 'stock_widgets.dart';

/// Linha do tempo de UMA unidade: movimentações do livro-razão
/// (`vw_stock_movements`) intercaladas com as alterações de campo
/// (`available_aircraft_logs`), mais recentes primeiro.
class StockUnitHistoryDialog extends StatefulWidget {
  const StockUnitHistoryDialog({super.key, required this.unit});

  final VwStockUnitsRow unit;

  @override
  State<StockUnitHistoryDialog> createState() => _StockUnitHistoryDialogState();
}

class _Event {
  _Event(this.at, this.icon, this.color, this.title, this.detail);
  final DateTime at;
  final IconData icon;
  final Color color;
  final String title;
  final String? detail;
}

// Rótulos das colunas que aparecem no log de alteração.
const _kFieldLabels = {
  'serial_number': 'Nº de série',
  'registration_prefix': 'Prefixo',
  'status': 'Status',
  'aircraft_model': 'Modelo',
  'manufacture_date': 'Fabricação',
  'configuration_deadline': 'Prazo de configuração',
  'delivery_date': 'Entrega',
  'entry_year': 'Ano base',
};

class _StockUnitHistoryDialogState extends State<StockUnitHistoryDialog> {
  late final Future<List<_Event>> _events = _load();

  Future<List<_Event>> _load() async {
    try {
      final results = await Future.wait([
        VwStockMovementsTable().queryRows(
          queryFn: (q) => q
              .eqOrNull('available_aircraft_id', widget.unit.id)
              .order('created_at'),
        ),
        AvailableAircraftLogsTable().queryRows(
          queryFn: (q) => q
              .eqOrNull('available_aircraft_id', widget.unit.id)
              .eqOrNull('action', 'update')
              .order('changed_at'),
        ),
      ]);
      final moves = results[0] as List<VwStockMovementsRow>;
      final logs = results[1] as List<AvailableAircraftLogsRow>;
      final events = <_Event>[
        for (final m in moves)
          _Event(
            m.createdAt,
            m.isEntrada ? Icons.south_west_rounded : Icons.north_east_rounded,
            m.isEntrada ? const Color(0xFF4ADE80) : const Color(0xFFFF7B82),
            '${m.isEntrada ? 'Entrada' : 'Saída'} · ${stockReasonLabel(m.reason)}',
            [
              if ((m.note ?? '').isNotEmpty) m.note!,
              if ((m.createdByName ?? '').isNotEmpty) 'por ${m.createdByName}',
            ].join(' — '),
          ),
        for (final l in logs)
          // Mudança de status que acompanha um lançamento já aparece como
          // movimentação — aqui só o que alguém editou à mão.
          if (l.changes.keys.any((k) => k != 'status') ||
              !moves.any((m) =>
                  (m.createdAt.difference(l.changedAt).inSeconds).abs() < 2))
            _Event(
              l.changedAt,
              Icons.edit_outlined,
              const Color(0xFFC2D51C),
              'Alteração',
              l.changes.entries.map((e) {
                final v = e.value as Map? ?? const {};
                return '${_kFieldLabels[e.key] ?? e.key}: '
                    '${_fmt(v['old'])} → ${_fmt(v['new'])}';
              }).join('\n'),
            ),
      ]..sort((a, b) => b.at.compareTo(a.at));
      return events;
    } catch (e, st) {
      Sentry.captureException(e,
          stackTrace: st,
          withScope: (s) => s.setTag('acao', 'estoque.historico_unidade'));
      rethrow;
    }
  }

  String _fmt(Object? v) {
    if (v == null || (v is String && v.isEmpty)) return '—';
    final s = v.toString();
    final d = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s) ? DateTime.tryParse(s) : null;
    return d != null ? formatStockDate(d) : s;
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.unit;
    return AppModal(
      icon: Icons.history_rounded,
      title: 'Histórico da aeronave',
      description: '${u.aircraftModelName} · S/N ${u.serialNumber}',
      maxWidth: 620,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Fechar',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      child: FutureBuilder<List<_Event>>(
        future: _events,
        builder: (context, snap) {
          if (snap.hasError) {
            return const AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Não foi possível carregar o histórico',
              compact: true,
            );
          }
          if (!snap.hasData) {
            return Column(
              children: List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppSkeleton.box(height: 52),
                ),
              ),
            );
          }
          final events = snap.data!;
          if (events.isEmpty) {
            return const AppEmptyState(
              icon: Icons.history_rounded,
              title: 'Sem registros',
              compact: true,
            );
          }
          return ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _tile(events[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _tile(_Event e) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: e.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(e.icon, size: 16, color: e.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e.title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if ((e.detail ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    e.detail!,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xB3FFFFFF),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatStockDateTime(e.at),
            style: GoogleFonts.roboto(
              fontSize: 11,
              color: const Color(0x99FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}
