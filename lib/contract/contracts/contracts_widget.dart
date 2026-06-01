import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'contracts_model.dart';

export 'contracts_model.dart';

class ContractsWidget extends StatefulWidget {
  const ContractsWidget({super.key});

  static String routeName = 'Contracts';
  static String routePath = '/contracts';

  @override
  State<ContractsWidget> createState() => _ContractsWidgetState();
}

class _ContractsWidgetState extends State<ContractsWidget> {
  late ContractsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _query = '';
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ContractsModel());

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        final user = await QueryCache.fetch<List<UsersRow>>(
          key: 'contracts.currentUser:$currentUserUid',
          ttl: const Duration(minutes: 5),
          fetcher: () => UsersTable().queryRows(
            queryFn: (q) => q.eqOrNull('id', currentUserUid),
          ),
        );
        if (_disposed) return;
        _model.user = user;
        safeSetState(() {});
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _model.dispose();
    super.dispose();
  }

  bool get _isAdmin =>
      _model.user?.firstOrNull?.profileType == 'Admin Master';

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      eyebrow: 'Funil de vendas',
      title: 'Contratos',
      description:
          'Propostas que viraram contrato fechado. Disparam a esteira de tracking.',
      search: AppSearchInput(
        value: _query,
        placeholder: 'Buscar por empresa, ID ou aeronave...',
        onChanged: (v) => setState(() => _query = v),
      ),
      body: FutureBuilder<List<VwContractDataRow>>(
        future: VwContractDataTable().queryRows(
          queryFn: (q) => q.order('created_at'),
        ),
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
          final all = snap.data!.where((c) => c.isContract == true).toList();
          final list = _query.isEmpty
              ? all
              : all.where((c) {
                  final q = _query.toLowerCase();
                  return (c.companyName ?? '').toLowerCase().contains(q) ||
                      (c.idRef ?? '').toLowerCase().contains(q) ||
                      (c.aircraftModel ?? '').toLowerCase().contains(q);
                }).toList();
          if (list.isEmpty) {
            return AppCard(
              child: AppEmptyState(
                icon: Icons.description_outlined,
                title: _query.isEmpty
                    ? 'Nenhum contrato fechado ainda'
                    : 'Nenhum contrato encontrado',
                description: _query.isEmpty
                    ? 'Quando uma proposta vira contrato, ela aparece aqui.'
                    : 'Tente outro termo de busca.',
              ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ContractRow(
                    item: list[i],
                    onTap: () => context.pushNamed(
                      ViewContractWidget.routeName,
                      queryParameters: {
                        'proposalId':
                            serializeParam(list[i].id, ParamType.String),
                        'typeAccess': serializeParam(
                            _isAdmin ? 'edit' : 'view', ParamType.String),
                        'companyName': serializeParam(
                            list[i].companyName, ParamType.String),
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

class _ContractRow extends StatelessWidget {
  const _ContractRow({required this.item, required this.onTap});
  final VwContractDataRow item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC2D51C), Color(0xFF8FA113)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC2D51C).withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: const Icon(Icons.description_outlined,
                color: Color(0xFF313131), size: 20),
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
                      'ID #${item.idRef ?? '0000000'}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0x55FFFFFF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        item.aircraftModel ?? 'Modelo não informado',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xCCFFFFFF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (context, c) => Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      if ((item.companyName ?? '').isNotEmpty)
                        _Meta(Icons.business_outlined, item.companyName!,
                            maxWidth: c.maxWidth),
                      if ((item.createdByName ?? '').isNotEmpty)
                        _Meta(Icons.person_outline_rounded, item.createdByName!,
                            maxWidth: c.maxWidth),
                      if (item.createdAt != null)
                        _Meta(Icons.calendar_today_outlined,
                            dateTimeFormat('d/M/y', item.createdAt),
                            maxWidth: c.maxWidth),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _money(item.fullprice),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const AppStatusBadge(
                label: 'Contrato',
                icon: Icons.verified_outlined,
                tone: AppStatusTone.success,
                dense: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _money(num? v) {
    if (v == null) return r'$ 0';
    return formatNumber(v,
        formatType: FormatType.decimal,
        decimalType: DecimalType.periodDecimal,
        currency: r'$ ');
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text, {this.maxWidth = double.infinity});
  final IconData icon;
  final String text;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0x99FFFFFF)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: 11.5,
                color: const Color(0x99FFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
