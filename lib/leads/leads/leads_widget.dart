import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/cascade_delete.dart';
import '/security/action_feedback.dart';
import '/pages/shared/confirm_delete_dialog/confirm_delete_dialog.dart';
import '/backend/lead_conversion.dart';
import '/backend/paged_query.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/security/write_guard.dart';
import '/pages/shared/alert_dialog/alert_dialog_widget.dart';
import '/pages/shared/modal_register_lead/modal_register_lead_widget.dart';
import 'leads_model.dart';

export 'leads_model.dart';

class LeadsWidget extends StatefulWidget {
  const LeadsWidget({super.key});

  static String routeName = 'Leads';
  static String routePath = '/leads';

  @override
  State<LeadsWidget> createState() => _LeadsWidgetState();
}

class _LeadsWidgetState extends State<LeadsWidget> {
  late LeadsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _query = '';
  Set<String> _selected = {};
  int _page = 1;
  int _perPage = kDefaultPerPage;

  /// Troca de página/tamanho recarrega do servidor. A seleção é limpa junto:
  /// ela guarda ids da página anterior, e a barra de lote passaria a contar
  /// itens que não estão mais na tela.
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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LeadsModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _refresh() => safeSetState(() {
        _model.requestCompleter = null;
        _selected = {};
      });

  /// Exclusão em lote. Cada linha passa pelo mesmo guardWrite da exclusão
  /// individual — a RLS barra em silêncio, então sem o guard o painel diria
  /// "excluídos" sem ter gravado nada.
  Future<void> _confirmDeleteSelected(List<LeadsRow> all) async {
    final alvos = all.where((l) => _selected.contains(l.id)).toList();
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
              ? 'Deseja excluir 1 lead?'
              : 'Deseja excluir ${alvos.length} leads?',
          iconColor: const Color(0xFFFF5963),
          btnColor: const Color(0xFFFF5963),
          confirmBtnAction: () async {
            var ok = 0;
            for (final lead in alvos) {
              final r = await guardWrite(
                context,
                () => LeadsTable().update(
                  data: {'is_deleted': true},
                  matchingRows: (rows) => rows.eqOrNull('id', lead.id),
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
                      ? '$ok ${ok == 1 ? 'lead excluído' : 'leads excluídos'}'
                      : '$ok excluído(s), $falhou sem permissão',
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

  Future<void> _openCreate() async {
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {
            FocusScope.of(dialogContext).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: ModalRegisterLeadWidget(
            btnAction: (name, lastname, cpf, company, jobTitle, email, phone,
                city, uf, createdBy) async {
              _model.insertLead = await LeadsTable().insert({
                'name': name,
                'last_name': lastname,
                'cpf': cpf,
                'email': email,
                'phone': phone,
                'city': city,
                'state': uf,
                'created_by': createdBy,
                'job_title': jobTitle,
                'company_name': company,
              });
              if (!mounted) return;
              _refresh();
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Lead cadastrado com sucesso!',
                    style: GoogleFonts.inter(color: const Color(0xFF313131)),
                  ),
                  backgroundColor: const Color(0xFFC2D51C),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Leads ainda em aberto — quem já virou cliente sai da lista (o registro do
  /// lead continua intacto; ele é a chave de auth do cliente no app e o que
  /// liga uma recompra à mesma conta). Ver [LeadConversion].
  ///
  /// Busca E exclusão de convertidos vão no `queryFn`, não em Dart depois:
  /// com paginação no servidor, filtrar a página já recebida devolveria
  /// páginas curtas (pedir 25 e mostrar 18) e um total mentiroso.
  Future<PagedResult<LeadsRow>> _fetchOpenLeads() async {
    final converted = await LeadConversion.convertedLeadIds();
    return queryPage<LeadsRow>(
      table: LeadsTable(),
      page: _page,
      perPage: _perPage,
      queryFn: (q) {
        var f = q.eqOrNull('is_deleted', false);
        if (_query.trim().isNotEmpty) {
          f = f.or(orIlike(
            const ['fullname', 'email', 'company_name'],
            _query,
          ));
        }
        if (converted.isNotEmpty) {
          f = f.not('id', 'in', '(${converted.join(',')})');
        }
        return f.order('created_at');
      },
    );
  }

  /// Exclusão de lead em cascata: leva propostas, contratos e a esteira junto.
  /// A modal mostra o que será afetado ANTES de confirmar — excluir um lead
  /// com contrato nunca atinge só o lead.
  Future<void> _confirmDelete(LeadsRow item) async {
    final nome = item.fullname ?? '${item.name} ${item.lastName}'.trim();

    final impacto = await runActionWithResult<DeletionImpact>(
      context,
      contexto: 'leads.preverExclusao',
      failure: 'Não foi possível verificar o que está vinculado a este lead.',
      action: () => previewLeadDeletion(item.id),
    );
    if (impacto == null || !mounted) return;

    final confirmou = await confirmDeleteWithImpact(
      context,
      titulo: 'Excluir o lead "$nome"?',
      impacto: impacto,
      principal: 'O lead "$nome"',
    );
    if (!confirmou || !mounted) return;

    final ok = await runAction(
      context,
      contexto: 'leads.excluir',
      success: _mensagemSucesso(impacto, 'Lead excluído'),
      failure: 'Não foi possível excluir o lead.',
      action: () => executeCascadeDelete(impacto, leadId: item.id),
    );
    if (ok) _refresh();
  }

  String _mensagemSucesso(DeletionImpact i, String base) {
    if (!i.temAlgoAlemDoPrincipal) return base;
    final extras = <String>[
      if (i.propostas > 0) '${i.propostas} proposta(s)',
      if (i.contratos > 0) '${i.contratos} contrato(s)',
    ];
    return '$base com ${extras.join(' e ')}';
  }

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      eyebrow: 'Funil de vendas',
      title: 'Leads',
      description:
          'Prospects em aberto. Viram proposta e, quando o contrato fecha, passam para Clientes e saem desta lista.',
      actions: [
        _PrimaryAction(
          icon: Icons.person_add_alt_rounded,
          label: 'Cadastrar lead',
          onTap: _openCreate,
        ),
      ],
      search: AppSearchInput(
        value: _query,
        placeholder: 'Buscar por nome, e-mail ou empresa...',
        onChanged: (v) {
          // Buscar volta para a página 1: manter a página 5 com um filtro
          // novo daria tela vazia sem explicação.
          setState(() {
            _query = v;
            _page = 1;
            _selected = {};
          });
          _model.textController?.text = v;
          _refresh();
        },
      ),
      body: FutureBuilder<PagedResult<LeadsRow>>(
        future: (_model.requestCompleter ??=
                Completer<PagedResult<LeadsRow>>()..complete(_fetchOpenLeads()))
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
                icon: Icons.person_search_rounded,
                title: _query.isEmpty
                    ? 'Nenhum lead cadastrado'
                    : 'Nenhum lead encontrado',
                description: _query.isEmpty
                    ? 'Crie o primeiro lead para começar.'
                    : 'Tente outro termo de busca.',
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDataTable<LeadsRow>(
            items: list,
            rowId: (l) => l.id,
            selectedIds: _selected,
            onSelectionChanged: (ids) => safeSetState(() => _selected = ids),
            onBulkAction: (_) => _confirmDeleteSelected(list),
            bulkActionLabel: 'Excluir selecionados',
            onRowTap: (l) => context.pushNamed(
              ViewEditLeadWidget.routeName,
              queryParameters: {
                'leadId': serializeParam(l.id, ParamType.String),
                'typeAccess': serializeParam('view', ParamType.String),
                'fullname': serializeParam(l.fullname, ParamType.String),
              }.withoutNulls,
            ),
            columns: [
              AppDataColumn(
                label: 'Nome',
                flex: 3,
                cell: (l) => AppCellText(
                  l.fullname ?? '${l.name} ${l.lastName}'.trim(),
                  bold: true,
                ),
              ),
              AppDataColumn(
                label: 'Empresa',
                flex: 3,
                cell: (l) => AppCellText(
                  (l.companyName ?? '').isNotEmpty ? l.companyName! : '—',
                  muted: true,
                ),
              ),
              AppDataColumn(
                label: 'Contato',
                flex: 3,
                cell: (l) => AppCellText(
                  l.phone.isNotEmpty
                      ? l.phone
                      : (l.email.isNotEmpty ? l.email : '—'),
                  muted: true,
                ),
              ),
              AppDataColumn(
                label: 'Cidade',
                flex: 2,
                cell: (l) => AppCellText(
                  l.city.isNotEmpty
                      ? '${l.city}${l.state.isNotEmpty ? '/${l.state}' : ''}'
                      : '—',
                  muted: true,
                ),
              ),
              // Sem coluna "Status": desde que os convertidos saem da lista,
              // toda linha aqui é "Lead" — um selo constante só consome
              // largura sem informar nada.
              AppDataColumn(
                label: 'Ações',
                width: 64,
                align: Alignment.centerRight,
                cell: (l) => AppRowAction(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Excluir',
                  danger: true,
                  onPressed: () => _confirmDelete(l),
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
