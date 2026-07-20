import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/cascade_delete.dart';
import '/security/action_feedback.dart';
import '/pages/shared/confirm_delete_dialog/confirm_delete_dialog.dart';
import '/backend/paged_query.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/security/access_control.dart';
import '/security/write_guard.dart';
import '/index.dart';
import '/pages/shared/alert_dialog/alert_dialog_widget.dart';
import 'proposals_model.dart';

export 'proposals_model.dart';

class ProposalsWidget extends StatefulWidget {
  const ProposalsWidget({super.key});

  static String routeName = 'Proposals';
  static String routePath = '/proposals';

  @override
  State<ProposalsWidget> createState() => _ProposalsWidgetState();
}

class _ProposalsWidgetState extends State<ProposalsWidget> {
  late ProposalsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _query = '';
  bool _disposed = false;
  Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProposalsModel());

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        final user = await QueryCache.fetch<List<UsersRow>>(
          key: 'proposals.currentUser:$currentUserUid',
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

  int _page = 1;
  int _perPage = kDefaultPerPage;

  void _refresh() => safeSetState(() {
        _model.requestCompleter = null;
        _selected = {};
      });

  void _goToPage(int p) => safeSetState(() {
        _page = p;
        _selected = {};
        _model.requestCompleter = null;
      });

  void _setPerPage(int n) => safeSetState(() {
        _perPage = n;
        _page = 1;
        _selected = {};
        _model.requestCompleter = null;
      });

  /// Busca no servidor: com paginação, filtrar em Dart só filtraria a página
  /// corrente — o termo "não acharia" propostas duas páginas adiante.
  Future<PagedResult<VwProposalDataRow>> _fetchPage() => queryPage(
        table: VwProposalDataTable(),
        page: _page,
        perPage: _perPage,
        queryFn: (q) {
          final f = _query.trim().isEmpty
              ? q
              : q.or(orIlike(
                  const [
                    'company_name',
                    'id_ref',
                    'aircraft_model',
                    'lead_fullname',
                  ],
                  _query,
                ));
          return f.order('created_at');
        },
      );

  Future<void> _confirmDeleteSelected(List<VwProposalDataRow> all) async {
    final alvos = all.where((p) => _selected.contains(p.id)).toList();
    if (alvos.isEmpty) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        alignment: Alignment.center,
        child: AlertDialogWidget(
          title: alvos.length == 1
              ? 'Deseja excluir 1 proposta?'
              : 'Deseja excluir ${alvos.length} propostas?',
          iconColor: const Color(0xFFFF5963),
          btnColor: const Color(0xFFFF5963),
          confirmBtnAction: () async {
            var ok = 0;
            for (final p in alvos) {
              final r = await guardWrite(
                context,
                () => ProposalTable().update(
                  data: {'is_deleted': true},
                  matchingRows: (rows) => rows.eqOrNull('id', p.id),
                  returnRows: true,
                ),
                silent: true,
              );
              if (r) ok++;
            }
            if (!mounted) return;
            Navigator.of(dialogContext).pop();
            _refresh();
            final falhou = alvos.length - ok;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  falhou == 0
                      ? '$ok ${ok == 1 ? 'proposta excluída' : 'propostas excluídas'}'
                      : '$ok excluída(s), $falhou sem permissão',
                  style: GoogleFonts.inter(color: const Color(0xFF313131)),
                ),
                backgroundColor: falhou == 0
                    ? const Color(0xFFC2D51C)
                    : const Color(0xFFF9CF58),
              ),
            );
          },
        ),
      ),
    );
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

  /// Exclusão de proposta com preview de impacto. Se ela já virou contrato, a
  /// modal avisa que o contrato e a esteira vão junto — a `vw_contract_data`
  /// filtra pelo `is_deleted` DA PROPOSTA, então não há como separar os dois.
  Future<void> _confirmDelete(VwProposalDataRow item) async {
    final ref = '#${item.idRef ?? '0000000'}';
    final id = item.id ?? '';
    if (id.isEmpty) return;

    final impacto = await runActionWithResult<DeletionImpact>(
      context,
      contexto: 'propostas.preverExclusao',
      failure: 'Não foi possível verificar o que está vinculado a esta proposta.',
      action: () => previewProposalDeletion(id),
    );
    if (impacto == null || !mounted) return;

    final ehContrato = item.isContract ?? false;
    final confirmou = await confirmDeleteWithImpact(
      context,
      titulo: ehContrato
          ? 'Excluir o contrato $ref?'
          : 'Excluir a proposta $ref?',
      impacto: impacto,
      principal: ehContrato
          ? 'O contrato $ref (e a proposta que o originou)'
          : 'A proposta $ref',
    );
    if (!confirmou || !mounted) return;

    final ok = await runAction(
      context,
      contexto: 'propostas.excluir',
      success: ehContrato ? 'Contrato excluído' : 'Proposta excluída',
      failure: ehContrato
          ? 'Não foi possível excluir o contrato.'
          : 'Não foi possível excluir a proposta.',
      action: () => executeCascadeDelete(impacto),
    );
    if (ok) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      eyebrow: 'Funil de vendas',
      title: 'Propostas',
      description:
          'Cotações enviadas a clientes. Quando aceitas, evoluem para contrato.',
      actions: [
        _PrimaryAction(
          icon: Icons.request_quote_outlined,
          label: 'Cadastrar proposta',
          onTap: () => context.pushNamed(CreateProposalWidget.routeName),
        ),
      ],
      search: AppSearchInput(
        value: _query,
        placeholder: 'Buscar por empresa, ID, aeronave ou lead...',
        onChanged: (v) {
          setState(() {
            _query = v;
            _page = 1;
            _selected = {};
          });
          _refresh();
        },
      ),
      body: FutureBuilder<PagedResult<VwProposalDataRow>>(
        future: (_model.requestCompleter ??=
                Completer<PagedResult<VwProposalDataRow>>()
                  ..complete(_fetchPage()))
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
          final paged = snap.data!;
          final list = paged.items;
          if (list.isEmpty) {
            return AppCard(
              child: AppEmptyState(
                icon: Icons.request_quote_outlined,
                title: _query.isEmpty
                    ? 'Nenhuma proposta cadastrada'
                    : 'Nenhuma proposta encontrada',
                description: _query.isEmpty
                    ? 'Crie a primeira proposta a partir de um lead qualificado.'
                    : 'Tente outro termo de busca.',
              ),
            );
          }
          // Proposta convertida agora PODE ser excluída — o que faltava era o
          // usuário saber o que isso derruba. A modal de impacto avisa que o
          // contrato e a esteira vão junto (a vw_contract_data filtra pelo
          // is_deleted DA PROPOSTA), então já não é destruição às cegas.
          bool podeExcluir(VwProposalDataRow p) => _canEdit;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDataTable<VwProposalDataRow>(
            items: list,
            // `id` da view é nullable no schema gerado; na prática nunca vem
            // nulo (é a PK da proposal), mas o fallback evita crash.
            rowId: (p) => p.id ?? '',
            selectedIds: _canEdit ? _selected : null,
            onSelectionChanged:
                _canEdit ? (ids) => safeSetState(() => _selected = ids) : null,
            onBulkAction: (_) => _confirmDeleteSelected(list),
            bulkActionLabel: 'Excluir selecionadas',
            isSelectable: podeExcluir,
            onRowTap: (p) => context.pushNamed(
              ViewEditProposalWidget.routeName,
              queryParameters: {
                'proposalId': serializeParam(p.id, ParamType.String),
                'typeAccess': serializeParam(
                    _canEdit ? 'edit' : 'view', ParamType.String),
                'companyName':
                    serializeParam(p.companyName, ParamType.String),
                'sellerName':
                    serializeParam(p.createdByName, ParamType.String),
              }.withoutNulls,
            ),
            columns: [
              AppDataColumn(
                label: 'ID',
                width: 96,
                cell: (p) => AppCellText('#${p.idRef ?? '0000000'}', bold: true),
              ),
              AppDataColumn(
                label: 'Aeronave',
                flex: 3,
                cell: (p) => AppCellText(
                  p.aircraftModel ?? 'Modelo não informado',
                  muted: true,
                ),
              ),
              AppDataColumn(
                label: 'Empresa',
                flex: 3,
                cell: (p) => AppCellText(
                  (p.companyName ?? '').isNotEmpty ? p.companyName! : '—',
                  muted: true,
                ),
              ),
              AppDataColumn(
                label: 'Vendedor',
                flex: 2,
                cell: (p) => AppCellText(
                  (p.createdByName ?? '').isNotEmpty ? p.createdByName! : '—',
                  muted: true,
                ),
              ),
              AppDataColumn(
                label: 'Valor/Status',
                width: 150,
                align: Alignment.centerRight,
                cell: (p) {
                  final c = p.isContract ?? false;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppStatusBadge(
                        label: c ? 'Contrato' : 'Proposta',
                        icon: c
                            ? Icons.verified_outlined
                            : Icons.edit_note_rounded,
                        tone: c ? AppStatusTone.success : AppStatusTone.brand,
                        dense: true,
                      ),
                      const SizedBox(height: 5),
                      AppCellText(_money(p.fullprice), bold: true),
                    ],
                  );
                },
              ),
              AppDataColumn(
                label: 'Ações',
                width: 64,
                align: Alignment.centerRight,
                cell: (p) => podeExcluir(p)
                    ? AppRowAction(
                        icon: Icons.delete_outline_rounded,
                        tooltip: 'Excluir',
                        danger: true,
                        onPressed: () => _confirmDelete(p),
                      )
                    : const SizedBox.shrink(),
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


class _PrimaryAction extends StatefulWidget {
  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_PrimaryAction> createState() => _PrimaryActionState();
}

class _PrimaryActionState extends State<_PrimaryAction> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC2D51C), Color(0xFFAEC117)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC2D51C)
                    .withValues(alpha: _hover ? 0.45 : 0.25),
                blurRadius: _hover ? 18 : 10,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: const Color(0xFF313131)),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF313131),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
