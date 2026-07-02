import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
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
    safeSetState(() => _model.requestCompleter = null);
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
              await SupaFlow.client.rpc(
                'admin_delete_app_user',
                params: {'p_user_id': item.userId},
              );
              if (!mounted) return;
              Navigator.of(dialogContext).pop();
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Cliente excluído',
                    style: GoogleFonts.inter(color: const Color(0xFF313131)),
                  ),
                  backgroundColor: const Color(0xFFC2D51C),
                  duration: const Duration(seconds: 3),
                ),
              );
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
          setState(() => _query = v);
          _model.textController?.text = v;
          _refresh();
        },
      ),
      body: FutureBuilder<List<VwGetClientsRow>>(
        future: (_model.requestCompleter ??= Completer<List<VwGetClientsRow>>()
              ..complete(VwGetClientsTable().queryRows(
                queryFn: (q) => q
                    .ilike('client_fullname', '%$_query%')
                    .order('created_at'),
              )))
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
          final list = snap.data!;
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
          return Column(
            children: [
              for (int i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ClientRow(
                    item: list[i],
                    model: _model,
                    index: i,
                    onTap: () => context.pushNamed(
                      ViewEditClientWidget.routeName,
                      queryParameters: {
                        'leadId':
                            serializeParam(list[i].leadId, ParamType.String),
                        'typeAccess': serializeParam('view', ParamType.String),
                        'fullname': serializeParam(
                            list[i].clientFullname, ParamType.String),
                      }.withoutNulls,
                    ),
                    onDelete: () => _confirmDelete(list[i]),
                  ).appStagger(i),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({
    required this.item,
    required this.model,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  final VwGetClientsRow item;
  final ClientsModel model;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppPersonCard(
      name: item.clientFullname ?? 'Cliente sem nome',
      subtitle: item.jobTitle,
      isActive: item.isActive ?? false,
      onTap: onTap,
      metas: [
        if ((item.companyName ?? '').isNotEmpty)
          AppPersonMeta(Icons.business_outlined, item.companyName!),
      ],
      trailing: [
        wrapWithModel(
          model: model.switchComponentModels.getModel(
            item.userId ?? '$index',
            index,
          ),
          updateCallback: () {},
          child: SwitchComponentWidget(
            key: Key('cli_switch_${item.userId ?? index}'),
            initialValue: item.isActive ?? false,
            activeAction: () async {
              await UsersTable().update(
                data: {'is_active': true},
                matchingRows: (rows) => rows.eqOrNull('id', item.userId),
              );
              _toast(context, 'Cliente ativado');
            },
            disableAction: () async {
              await UsersTable().update(
                data: {'is_active': false},
                matchingRows: (rows) => rows.eqOrNull('id', item.userId),
              );
              _toast(context, 'Cliente desativado');
            },
          ),
        ),
        AppRowAction(
          icon: Icons.delete_outline_rounded,
          tooltip: 'Excluir',
          danger: true,
          onPressed: onDelete,
        ),
      ],
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.inter(color: const Color(0xFF313131)),
        ),
        backgroundColor: const Color(0xFFC2D51C),
        duration: const Duration(seconds: 2),
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
