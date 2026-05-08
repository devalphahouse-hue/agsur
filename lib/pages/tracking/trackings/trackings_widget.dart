import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/app_constants.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'trackings_model.dart';

export 'trackings_model.dart';

class TrackingsWidget extends StatefulWidget {
  const TrackingsWidget({super.key});

  static String routeName = 'Trackings';
  static String routePath = '/trackings';

  @override
  State<TrackingsWidget> createState() => _TrackingsWidgetState();
}

class _TrackingsWidgetState extends State<TrackingsWidget> {
  late TrackingsModel _model;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TrackingsModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _refresh() => safeSetState(() => _model.requestCompleter = null);

  /// Agrupa as linhas de tracking por userAircraftId e calcula o progresso
  /// (etapas concluídas / total). Retorna lista pronta pra renderização.
  List<_AircraftProgress> _groupByAircraft(List<VwAllTrackingRow> rows) {
    final map = <String, List<VwAllTrackingRow>>{};
    for (final r in rows) {
      final id = r.userAircraftId ?? '';
      if (id.isEmpty) continue;
      map.putIfAbsent(id, () => []).add(r);
    }

    final totalEtapas = FFAppConstants.TrackingDescription.length;

    final list = map.entries.map((e) {
      final items = e.value;
      // Ordena por `order` pra pegar a próxima etapa pendente
      items.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      final concluidas =
          items.where((r) => (r.isCheck ?? false) == true).length;
      final pendentes = items
          .where((r) => (r.isCheck ?? false) == false)
          .map((r) => r.trackingDescription ?? '')
          .toList();

      // Pega o primeiro item para metadados da aeronave
      final first = items.first;
      return _AircraftProgress(
        userAircraftId: e.key,
        aircraftModel: first.aircraftModel ?? 'Aeronave',
        aircraftYear: first.aircraftYear,
        companyName: first.companyName ?? 'Empresa',
        proposalIdRef: first.proposalIdRef,
        sellerName: first.createdByFullname,
        concluidas: concluidas,
        total: totalEtapas,
        proximaEtapa: pendentes.isNotEmpty ? pendentes.first : null,
        userAircraftCreatedAt: first.userAircraftCreatedAt,
      );
    }).toList();

    list.sort((a, b) {
      final ad = a.userAircraftCreatedAt;
      final bd = b.userAircraftCreatedAt;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      eyebrow: 'Operação',
      title: 'Rastreamento',
      description:
          'Esteira de importação de aeronaves. Cada aeronave passa por '
          '${FFAppConstants.TrackingDescription.length} etapas.',
      search: AppSearchInput(
        value: _query,
        placeholder: 'Buscar por empresa, aeronave ou ID...',
        onChanged: (v) {
          setState(() => _query = v);
          _model.textController?.text = v;
        },
      ),
      body: FutureBuilder<List<VwAllTrackingRow>>(
        future: (_model.requestCompleter ??=
                Completer<List<VwAllTrackingRow>>()
                  ..complete(VwAllTrackingTable().queryRows(
                    queryFn: (q) => q.order('created_at'),
                  )))
            .future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return Column(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppSkeleton.box(height: 110),
                ),
              ),
            );
          }
          final all = _groupByAircraft(snap.data!);
          final list = _query.isEmpty
              ? all
              : all.where((a) {
                  final q = _query.toLowerCase();
                  return a.companyName.toLowerCase().contains(q) ||
                      a.aircraftModel.toLowerCase().contains(q) ||
                      (a.proposalIdRef ?? '').toLowerCase().contains(q);
                }).toList();
          if (list.isEmpty) {
            return AppCard(
              child: AppEmptyState(
                icon: Icons.timeline_rounded,
                title: _query.isEmpty
                    ? 'Nenhuma aeronave em rastreamento'
                    : 'Nenhuma aeronave encontrada',
                description: _query.isEmpty
                    ? 'Aeronaves vinculadas a contratos aparecem aqui.'
                    : 'Tente outro termo de busca.',
              ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TrackingRow(
                    item: list[i],
                    onTap: () => context.pushNamed(
                      ViewTrackingWidget.routeName,
                      queryParameters: {
                        'userAircraftId': serializeParam(
                            list[i].userAircraftId, ParamType.String),
                      }.withoutNulls,
                    ),
                  ).appStagger(i),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AircraftProgress {
  const _AircraftProgress({
    required this.userAircraftId,
    required this.aircraftModel,
    required this.aircraftYear,
    required this.companyName,
    required this.proposalIdRef,
    required this.sellerName,
    required this.concluidas,
    required this.total,
    required this.proximaEtapa,
    required this.userAircraftCreatedAt,
  });

  final String userAircraftId;
  final String aircraftModel;
  final String? aircraftYear;
  final String companyName;
  final String? proposalIdRef;
  final String? sellerName;
  final int concluidas;
  final int total;
  final String? proximaEtapa;
  final DateTime? userAircraftCreatedAt;

  double get progress => total == 0 ? 0 : concluidas / total;
  bool get isComplete => concluidas >= total && total > 0;
}

class _TrackingRow extends StatelessWidget {
  const _TrackingRow({required this.item, required this.onTap});
  final _AircraftProgress item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0x33C2D51C),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.flight_outlined,
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
                          item.aircraftModel,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if ((item.aircraftYear ?? '').isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            item.aircraftYear!,
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: const Color(0x99FFFFFF),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _Meta(Icons.business_outlined, item.companyName),
                        if ((item.proposalIdRef ?? '').isNotEmpty)
                          _Meta(Icons.tag_rounded,
                              'ID #${item.proposalIdRef!}'),
                        if ((item.sellerName ?? '').isNotEmpty)
                          _Meta(Icons.person_outline_rounded,
                              item.sellerName!),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppStatusBadge(
                label: item.isComplete
                    ? 'Concluído'
                    : '${item.concluidas}/${item.total}',
                icon: item.isComplete
                    ? Icons.check_circle_outline
                    : Icons.timeline_rounded,
                tone: item.isComplete
                    ? AppStatusTone.success
                    : AppStatusTone.brand,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 6,
              backgroundColor: const Color(0x14FFFFFF),
              valueColor: AlwaysStoppedAnimation<Color>(
                item.isComplete
                    ? const Color(0xFF4FBFA9)
                    : const Color(0xFFC2D51C),
              ),
            ),
          ),
          if (!item.isComplete && (item.proximaEtapa ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.arrow_forward_rounded,
                    size: 12, color: Color(0xFFC2D51C)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Próxima etapa: ${item.proximaEtapa}',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 11.5,
                      color: const Color(0xCCFFFFFF),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
        Text(
          text,
          style: GoogleFonts.roboto(
            fontSize: 11.5,
            color: const Color(0x99FFFFFF),
          ),
        ),
      ],
    );
  }
}
