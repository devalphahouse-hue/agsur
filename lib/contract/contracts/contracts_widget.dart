import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '/backend/paged_query.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/security/access_control.dart';
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
  int _page = 1;
  int _perPage = kDefaultPerPage;

  void _goToPage(int p) => safeSetState(() => _page = p);
  void _setPerPage(int n) => safeSetState(() {
        _perPage = n;
        _page = 1;
      });

  /// `is_contract=true` também vai para o servidor: filtrar em Dart depois de
  /// paginar devolveria páginas curtas e um total errado (a view traz
  /// propostas e contratos na mesma consulta).
  Future<PagedResult<VwContractDataRow>> _fetchPage() => queryPage(
        table: VwContractDataTable(),
        page: _page,
        perPage: _perPage,
        queryFn: (q) {
          var f = q.eq('is_contract', true);
          if (_query.trim().isNotEmpty) {
            f = f.or(orIlike(
              const ['company_name', 'id_ref', 'aircraft_model'],
              _query,
            ));
          }
          return f.order('created_at');
        },
      );

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

  bool get _canEdit => AccessControl.canEditFunil(
      AccessControl.roleOf(_model.user?.firstOrNull));

  String _money(num? v) {
    if (v == null) return r'$ 0';
    return formatNumber(v,
        formatType: FormatType.decimal,
        decimalType: DecimalType.periodDecimal,
        currency: r'$ ');
  }

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
        onChanged: (v) => setState(() {
          _query = v;
          _page = 1;
        }),
      ),
      body: FutureBuilder<PagedResult<VwContractDataRow>>(
        future: _fetchPage(),
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
          final paged = snap.data!;
          final list = paged.items;
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
          // Sem seleção/exclusão aqui de propósito: contrato é venda fechada e
          // hoje a tela não tem exclusão nenhuma. "Excluir contrato" seria, na
          // prática, marcar is_deleted na PROPOSTA (a contract não tem a
          // coluna) — o que também some com o histórico da proposta. Só
          // adicionar mediante decisão explícita.
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDataTable<VwContractDataRow>(
            items: list,
            rowId: (c) => c.id ?? '',
            onRowTap: (c) => context.pushNamed(
              ViewContractWidget.routeName,
              queryParameters: {
                'proposalId': serializeParam(c.id, ParamType.String),
                'typeAccess': serializeParam(
                    _canEdit ? 'edit' : 'view', ParamType.String),
                'companyName':
                    serializeParam(c.companyName, ParamType.String),
              }.withoutNulls,
            ),
            columns: [
              AppDataColumn(
                label: 'ID',
                width: 96,
                cell: (c) => AppCellText('#${c.idRef ?? '0000000'}', bold: true),
              ),
              AppDataColumn(
                label: 'Aeronave',
                flex: 3,
                cell: (c) => AppCellText(
                  c.aircraftModel ?? 'Modelo não informado',
                  muted: true,
                ),
              ),
              AppDataColumn(
                label: 'Empresa',
                flex: 3,
                cell: (c) => AppCellText(
                  (c.companyName ?? '').isNotEmpty ? c.companyName! : '—',
                  muted: true,
                ),
              ),
              AppDataColumn(
                label: 'Vendedor',
                flex: 2,
                cell: (c) => AppCellText(
                  (c.createdByName ?? '').isNotEmpty ? c.createdByName! : '—',
                  muted: true,
                ),
              ),
              AppDataColumn(
                label: 'Data',
                width: 100,
                cell: (c) => AppCellText(
                  c.createdAt != null
                      ? dateTimeFormat('d/M/y', c.createdAt)
                      : '—',
                  muted: true,
                ),
              ),
              AppDataColumn(
                label: 'Valor/Status',
                width: 150,
                align: Alignment.centerRight,
                cell: (c) => Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppStatusBadge(
                      label: 'Contrato',
                      icon: Icons.verified_outlined,
                      tone: AppStatusTone.success,
                      dense: true,
                    ),
                    const SizedBox(height: 5),
                    AppCellText(_money(c.fullprice), bold: true),
                  ],
                ),
              ),
            ],
              ),
              AppPagination(
                result: paged,
                onPageChanged: _goToPage,
                onPerPageChanged: _setPerPage,
              ),
            ],
          );
        },
      ),
    );
  }
}

