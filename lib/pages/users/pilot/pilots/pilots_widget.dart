import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/api_requests/api_calls.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/pages/shared/alert_dialog/alert_dialog_widget.dart';
import '/pages/shared/modal_register_pilot/modal_register_pilot_widget.dart';
import '/pages/shared/switch_component/switch_component_widget.dart';
import 'pilots_model.dart';

export 'pilots_model.dart';

class PilotsWidget extends StatefulWidget {
  const PilotsWidget({super.key});

  static String routeName = 'Pilots';
  static String routePath = '/pilots';

  @override
  State<PilotsWidget> createState() => _PilotsWidgetState();
}

class _PilotsWidgetState extends State<PilotsWidget> {
  late PilotsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PilotsModel());
    _model.tFSearchPilotTextController ??= TextEditingController();
    _model.tFSearchPilotFocusNode ??= FocusNode();
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
          child: ModalRegisterPilotWidget(
            btnAction: (name, lastname, fullname, cpf, email, phone, city, uf,
                password, clientIds) async {
              _model.createAuthUserForColab =
                  await CreateAccountAnotherUserCall.call(
                email: email,
                password: password,
              );

              if ((_model.createAuthUserForColab?.succeeded ?? true)) {
                final newUserId = getJsonField(
                  (_model.createAuthUserForColab?.jsonBody ?? ''),
                  r'$.user.id',
                ).toString();
                _model.createUserPilot = await UsersTable().insert({
                  'id': newUserId,
                  'name': name,
                  'email': getJsonField(
                    (_model.createAuthUserForColab?.jsonBody ?? ''),
                    r'$.user.email',
                  ).toString(),
                  'phone': phone,
                  'profile_type': ProfileType.Piloto.name,
                  'cpf': cpf,
                  'status': UserStatus.approved.name,
                  'lastname': lastname,
                  'fullname': fullname,
                });
                if (clientIds.isNotEmpty) {
                  for (final cid in clientIds) {
                    try {
                      await PilotClientsTable().insert({
                        'pilot_id': newUserId,
                        'client_id': cid,
                      });
                    } catch (_) {}
                  }
                }
                if (!mounted) return;
                _refresh();
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Piloto cadastrado com sucesso!',
                      style: GoogleFonts.inter(color: const Color(0xFF313131)),
                    ),
                    backgroundColor: const Color(0xFFC2D51C),
                  ),
                );
              } else {
                final errBody =
                    (_model.createAuthUserForColab?.bodyText ?? '')
                        .toLowerCase();
                final isDuplicateEmail =
                    errBody.contains('user_already_exists') ||
                        errBody.contains('already registered');
                if (!mounted) return;
                Navigator.of(dialogContext).pop();
                await showDialog(
                  context: context,
                  builder: (alertCtx) => AlertDialog(
                    title: Text(
                        isDuplicateEmail ? 'E-mail já cadastrado' : 'Erro'),
                    content: Text(isDuplicateEmail
                        ? 'Este e-mail já possui uma conta na plataforma.'
                        : 'Não foi possível criar a conta do piloto.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(alertCtx),
                        child: const Text('Ok'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(VwGetPilotsRow item) async {
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
            title: 'Deseja excluir este piloto?',
            iconColor: const Color(0xFFFF5963),
            btnColor: const Color(0xFFFF5963),
            confirmBtnAction: () async {
              await UsersTable().update(
                data: {'is_deleted': true, 'is_active': false},
                matchingRows: (rows) => rows.eqOrNull('id', item.userId),
              );
              if (!mounted) return;
              Navigator.of(dialogContext).pop();
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Piloto excluído',
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
      title: 'Pilotos',
      description:
          'Pilotos cadastrados podem solicitar certificados de simulador e cartas de serviço.',
      actions: [
        _PrimaryAction(
          icon: Icons.flight_outlined,
          label: 'Cadastrar piloto',
          onTap: _openCreate,
        ),
      ],
      search: AppSearchInput(
        value: _query,
        placeholder: 'Buscar por nome do piloto...',
        onChanged: (v) {
          setState(() => _query = v);
          _model.tFSearchPilotTextController?.text = v;
          _refresh();
        },
      ),
      body: FutureBuilder<List<VwGetPilotsRow>>(
        future: (_model.requestCompleter ??= Completer<List<VwGetPilotsRow>>()
              ..complete(VwGetPilotsTable().queryRows(
                queryFn: (q) => q
                    .ilike('fullname', '%$_query%')
                    .eqOrNull('is_deleted', false)
                    .order('fullname', ascending: true),
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
                icon: Icons.flight_outlined,
                title: _query.isEmpty
                    ? 'Nenhum piloto cadastrado'
                    : 'Nenhum piloto encontrado',
                description: _query.isEmpty
                    ? 'Crie o primeiro piloto para começar.'
                    : 'Tente outro termo de busca.',
              ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PilotRow(
                    item: list[i],
                    model: _model,
                    index: i,
                    onTap: () => context.pushNamed(
                      ViewEditPilotsWidget.routeName,
                      queryParameters: {
                        'pilotId':
                            serializeParam(list[i].userId, ParamType.String),
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

class _PilotRow extends StatelessWidget {
  const _PilotRow({
    required this.item,
    required this.model,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  final VwGetPilotsRow item;
  final PilotsModel model;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppPersonCard(
      name: item.fullname ?? 'Piloto sem nome',
      subtitle: item.email,
      avatarIcon: Icons.flight_outlined,
      isActive: item.isActive ?? false,
      onTap: onTap,
      metas: [
        if ((item.phone ?? '').isNotEmpty)
          AppPersonMeta(Icons.phone_outlined, item.phone!),
      ],
      trailing: [
        wrapWithModel(
          model: model.switchComponentModels.getModel(
            item.userId ?? '$index',
            index,
          ),
          updateCallback: () {},
          child: SwitchComponentWidget(
            key: Key('pilot_switch_${item.userId ?? index}'),
            initialValue: item.isActive ?? false,
            activeAction: () async {
              await UsersTable().update(
                data: {'is_active': true},
                matchingRows: (rows) => rows.eqOrNull('id', item.userId),
              );
              _toast(context, 'Piloto ativado');
            },
            disableAction: () async {
              await UsersTable().update(
                data: {'is_active': false},
                matchingRows: (rows) => rows.eqOrNull('id', item.userId),
              );
              _toast(context, 'Piloto desativado');
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
