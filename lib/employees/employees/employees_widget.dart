import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/pages/shared/alert_dialog/alert_dialog_widget.dart';
import '/pages/shared/modal_register_collab/modal_register_collab_widget.dart';
import '/pages/shared/switch_component/switch_component_widget.dart';
import 'employees_model.dart';

export 'employees_model.dart';

class EmployeesWidget extends StatefulWidget {
  const EmployeesWidget({super.key});

  static String routeName = 'Employees';
  static String routePath = '/employees';

  @override
  State<EmployeesWidget> createState() => _EmployeesWidgetState();
}

class _EmployeesWidgetState extends State<EmployeesWidget> {
  late EmployeesModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EmployeesModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _refresh() => safeSetState(() => _model.requestCompleter = null);

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
          child: ModalRegisterCollabWidget(
            databaseRefresh: () async {
              _refresh();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(UsersRow item) async {
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
            title: 'Deseja excluir este colaborador?',
            iconColor: const Color(0xFFFF5963),
            btnColor: const Color(0xFFFF5963),
            confirmBtnAction: () async {
              // Soft-delete + ban no auth + libera o e-mail para recadastro
              // (BUG-008/009). Antes era UPDATE direto, sem ban e sem liberar
              // o e-mail.
              try {
                await SupaFlow.client.rpc(
                  'admin_delete_app_user',
                  params: {'p_user_id': item.id},
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.of(dialogContext).pop();
                final msg = item.profileType == 'Admin Master'
                    ? 'Admin Master não pode ser excluído. Altere o nível de acesso antes de excluir.'
                    : 'Não foi possível excluir o colaborador. Tente novamente.';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(msg,
                        style: GoogleFonts.inter(color: Colors.white)),
                    backgroundColor: const Color(0xFFCC3B45),
                  ),
                );
                return;
              }
              if (!mounted) return;
              Navigator.of(dialogContext).pop();
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Colaborador excluído',
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

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      eyebrow: 'Pessoas',
      title: 'Colaboradores',
      description:
          'Equipe interna com acesso administrativo ao painel.',
      actions: [
        _PrimaryAction(
          icon: Icons.badge_outlined,
          label: 'Cadastrar colaborador',
          onTap: _openCreate,
        ),
      ],
      search: AppSearchInput(
        value: _query,
        placeholder: 'Buscar por nome do colaborador...',
        onChanged: (v) => setState(() => _query = v),
      ),
      body: FutureBuilder<List<UsersRow>>(
        future: (_model.requestCompleter ??= Completer<List<UsersRow>>()
              ..complete(UsersTable().queryRows(
                queryFn: (q) => q
                    .inFilter('profile_type', const ['Admin', 'Admin Master'])
                    .eqOrNull('is_deleted', false),
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
          final all = snap.data!;
          final list = _query.isEmpty
              ? all
              : all
                  .where((u) => (u.fullname ?? '')
                      .toLowerCase()
                      .contains(_query.toLowerCase()))
                  .toList();
          if (list.isEmpty) {
            return AppCard(
              child: AppEmptyState(
                icon: Icons.badge_outlined,
                title: _query.isEmpty
                    ? 'Nenhum colaborador cadastrado'
                    : 'Nenhum colaborador encontrado',
                description: _query.isEmpty
                    ? 'Crie o primeiro colaborador para começar.'
                    : 'Tente outro termo de busca.',
              ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _EmployeeRow(
                    item: list[i],
                    model: _model,
                    index: i,
                    onTap: () => context.pushNamed(
                      ViewEditEmployeesWidget.routeName,
                      queryParameters: {
                        'employeId':
                            serializeParam(list[i].id, ParamType.String),
                        'typeAccess': serializeParam('view', ParamType.String),
                        'fullname': serializeParam(
                            list[i].fullname, ParamType.String),
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

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({
    required this.item,
    required this.model,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  final UsersRow item;
  final EmployeesModel model;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppPersonCard(
      name: item.fullname ?? 'Colaborador sem nome',
      subtitle: item.email,
      avatarIcon: Icons.badge_outlined,
      isActive: item.isActive ?? false,
      onTap: onTap,
      metas: [
        AppPersonMeta(Icons.shield_outlined, _levelLabel(item)),
        if ((item.phone ?? '').isNotEmpty)
          AppPersonMeta(Icons.phone_outlined, item.phone!),
      ],
      trailing: [
        wrapWithModel(
          model: model.switchComponentModels.getModel(
            item.id ?? '$index',
            index,
          ),
          updateCallback: () {},
          child: SwitchComponentWidget(
            key: Key('emp_switch_${item.id ?? index}'),
            initialValue: item.isActive ?? false,
            activeAction: () async {
              await UsersTable().update(
                data: {'is_active': true},
                matchingRows: (rows) => rows.eqOrNull('id', item.id),
              );
              _toast(context, 'Colaborador ativado');
            },
            disableAction: () async {
              await UsersTable().update(
                data: {'is_active': false},
                matchingRows: (rows) => rows.eqOrNull('id', item.id),
              );
              _toast(context, 'Colaborador desativado');
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

  String _levelLabel(UsersRow u) {
    if (u.profileType == 'Admin Master') return 'Admin master';
    if (u.accessLevel == 'documentacao') return 'Admin documentação';
    return 'Admin recepção';
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
