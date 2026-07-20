import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/paged_query.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/security/action_feedback.dart';
import '/security/write_guard.dart';
import '/index.dart';
import '/pages/shared/alert_dialog/alert_dialog_widget.dart';
import '/pages/shared/modal_create_client/modal_create_client_widget.dart';
import '/pages/shared/switch_component/switch_component_widget.dart';
import 'clients_model.dart';

export 'clients_model.dart';

/// Listagem de clientes — redesenho.
/// Mantém: routeName/routePath, ClientsModel, queries (vw_get_clients),
/// modal de criação, navegação para ViewEditClient e soft-delete via UsersTable.
class ClientsWidget extends StatefulWidget {
  const ClientsWidget({super.key});

  static String routeName = 'Clients';
  static String routePath = '/clients';

  @override
  State<ClientsWidget> createState() => _ClientsWidgetState();
}

class _ClientsWidgetState extends State<ClientsWidget> {
  late ClientsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _query = '';
  Set<String> _selected = {};
  int _page = 1;
  int _perPage = kDefaultPerPage;

  /// Traduz o erro do Postgres para algo que o usuário entenda. `42501` é o
  /// errcode que a RPC levanta quando quem chamou não é Admin Master.
  String _mensagemErroExclusao(Object e) {
    final texto = e.toString();
    if (texto.contains('42501') || texto.contains('Admin Master')) {
      return 'Só o Admin Master pode excluir clientes.';
    }
    return 'Não foi possível excluir o cliente. Tente novamente.';
  }

  void _toast(BuildContext context, String msg, {bool warn = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.inter(color: const Color(0xFF313131)),
        ),
        backgroundColor:
            warn ? const Color(0xFFF9CF58) : const Color(0xFFC2D51C),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Exclusão em lote de clientes. Vai pela RPC `admin_delete_app_user` (uma
  /// por vez), nunca por UPDATE direto: é ela que faz soft-delete + ban +
  /// libera o e-mail para recadastro. A RPC exige Admin Master e LANÇA para os
  /// demais, então cada chamada é isolada e o resultado é contado.
  Future<void> _confirmDeleteSelected(List<VwGetClientsRow> all) async {
    final alvos = all.where((c) => _selected.contains(c.userId ?? '')).toList();
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
              ? 'Deseja excluir 1 cliente?'
              : 'Deseja excluir ${alvos.length} clientes?',
          iconColor: const Color(0xFFFF5963),
          btnColor: const Color(0xFFFF5963),
          confirmBtnAction: () async {
            var ok = 0;
            Object? primeiroErro;
            for (final c in alvos) {
              try {
                await SupaFlow.client.rpc(
                  'admin_delete_app_user',
                  params: {'p_user_id': c.userId},
                );
                ok++;
              } catch (e) {
                // segue para os demais; o total honesto vai na mensagem
                primeiroErro ??= e;
              }
            }
            if (!mounted) return;
            Navigator.of(dialogContext).pop();
            _refresh();
            final falhou = alvos.length - ok;
            _toast(
              context,
              falhou == 0
                  ? '$ok ${ok == 1 ? 'cliente excluído' : 'clientes excluídos'}'
                  : '$ok excluído(s), $falhou não: '
                      '${_mensagemErroExclusao(primeiroErro!)}',
              warn: falhou > 0,
            );
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ClientsModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _refresh() {
    safeSetState(() {
      _model.requestCompleter = null;
      _selected = {};
    });
  }

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

  Future<PagedResult<VwGetClientsRow>> _fetchPage() => queryPage(
        table: VwGetClientsTable(),
        page: _page,
        perPage: _perPage,
        queryFn: (q) {
          final f = _query.trim().isEmpty
              ? q
              : q.or(orIlike(
                  const ['client_fullname', 'company_name'],
                  _query,
                ));
          return f.order('created_at');
        },
      );

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
          child: const ModalCreateClientWidget(),
        ),
      ),
    );
    _refresh();
  }

  Future<void> _confirmDelete(VwGetClientsRow item) async {
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
          child: AlertDialogWidget(
            title: 'Deseja excluir este cliente?',
            iconColor: const Color(0xFFFF5963),
            btnColor: const Color(0xFFFF5963),
            confirmBtnAction: () async {
              // A RPC exige Admin Master e LANÇA para os demais perfis. O
              // runAction garante que o diálogo feche e que o usuário veja o
              // motivo — antes a tela simplesmente não respondia.
              final ok = await runAction(
                context,
                dialogContext: dialogContext,
                contexto: 'clientes.excluir',
                success: 'Cliente excluído',
                failure: 'Não foi possível excluir o cliente.',
                action: () => SupaFlow.client.rpc(
                  'admin_delete_app_user',
                  params: {'p_user_id': item.userId},
                ),
              );
              if (ok) _refresh();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      eyebrow: 'Pessoas',
      title: 'Clientes',
      description:
          'Pessoas com acesso ao app que estão vinculadas a uma proposta ou contrato.',
      // Botão "Cadastrar cliente" ocultado: clientes passam a ser criados
      // automaticamente na conversão de proposta em contrato.
      actions: const [],
      search: AppSearchInput(
        value: _query,
        placeholder: 'Buscar por nome do cliente...',
        onChanged: (v) {
          setState(() {
            _query = v;
            _page = 1;
          });
          _model.textController?.text = v;
          _refresh();
        },
      ),
      body: FutureBuilder<PagedResult<VwGetClientsRow>>(
        future: (_model.requestCompleter ??=
                Completer<PagedResult<VwGetClientsRow>>()
                  ..complete(_fetchPage()))
            .future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return Column(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppSkeleton.box(height: 76),
                ),
              ),
            );
          }
          final paged = snap.data!;
          final list = paged.items;
          if (list.isEmpty) {
            return AppCard(
              child: AppEmptyState(
                icon: Icons.groups_outlined,
                title: _query.isEmpty
                    ? 'Nenhum cliente cadastrado'
                    : 'Nenhum cliente encontrado',
                description: _query.isEmpty
                    ? 'Crie o primeiro cliente para começar.'
                    : 'Tente outro termo de busca.',
              ),
            );
          }
          // O switch de ativo/inativo precisa do índice para achar o seu model
          // em switchComponentModels — a célula só recebe o item, então o
          // índice vem daqui.
          final indexById = <String, int>{
            for (int i = 0; i < list.length; i++) (list[i].userId ?? '$i'): i,
          };

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDataTable<VwGetClientsRow>(
            items: list,
            rowId: (c) => c.userId ?? '',
            selectedIds: _selected,
            onSelectionChanged: (ids) => safeSetState(() => _selected = ids),
            onBulkAction: (_) => _confirmDeleteSelected(list),
            bulkActionLabel: 'Excluir selecionados',
            onRowTap: (c) => context.pushNamed(
              ViewEditClientWidget.routeName,
              queryParameters: {
                'leadId': serializeParam(c.leadId, ParamType.String),
                'typeAccess': serializeParam('view', ParamType.String),
                'fullname':
                    serializeParam(c.clientFullname, ParamType.String),
              }.withoutNulls,
            ),
            columns: [
              AppDataColumn(
                label: 'Nome',
                flex: 3,
                cell: (c) => AppCellText(
                  c.clientFullname ?? 'Cliente sem nome',
                  bold: true,
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
                label: 'Cargo',
                flex: 2,
                cell: (c) => AppCellText(
                  (c.jobTitle ?? '').isNotEmpty ? c.jobTitle! : '—',
                  muted: true,
                ),
              ),
              AppDataColumn(
                label: 'Ativo',
                width: 88,
                cell: (c) {
                  final i = indexById[c.userId ?? ''] ?? 0;
                  return wrapWithModel(
                    model: _model.switchComponentModels.getModel(
                      c.userId ?? '$i',
                      i,
                    ),
                    updateCallback: () {},
                    child: SwitchComponentWidget(
                      key: Key('cli_switch_${c.userId ?? i}'),
                      initialValue: c.isActive ?? false,
                      activeAction: () async {
                        final ok = await guardWrite(
                          context,
                          () => UsersTable().update(
                            data: {'is_active': true},
                            matchingRows: (rows) =>
                                rows.eqOrNull('id', c.userId),
                            returnRows: true,
                          ),
                        );
                        if (!ok) return;
                        _toast(context, 'Cliente ativado');
                      },
                      disableAction: () async {
                        final ok = await guardWrite(
                          context,
                          () => UsersTable().update(
                            data: {'is_active': false},
                            matchingRows: (rows) =>
                                rows.eqOrNull('id', c.userId),
                            returnRows: true,
                          ),
                        );
                        if (!ok) return;
                        _toast(context, 'Cliente desativado');
                      },
                    ),
                  );
                },
              ),
              // Sem selo Ativo/Inativo ao lado: ele repetia exatamente o que o
              // switch já mostra. Diferente do par Valor/Status (duas
              // informações distintas), aqui o controle JÁ comunica o estado —
              // então some o selo em vez de empilhar os dois.
              AppDataColumn(
                label: 'Ações',
                width: 64,
                align: Alignment.centerRight,
                cell: (c) => AppRowAction(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Excluir',
                  danger: true,
                  onPressed: () => _confirmDelete(c),
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
                color: const Color(0xFFC2D51C).withValues(alpha: _hover ? 0.45 : 0.25),
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
