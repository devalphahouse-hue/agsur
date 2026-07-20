import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/api_requests/api_calls.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/security/write_guard.dart';
import '/security/action_feedback.dart';
import '/security/credentials_email.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/pages/shared/alert_dialog/alert_dialog_widget.dart';
import '/pages/shared/register_oficina/register_oficina_widget.dart';
import '/pages/shared/switch_component/switch_component_widget.dart';
import 'oficina_model.dart';

export 'oficina_model.dart';

class OficinaWidget extends StatefulWidget {
  const OficinaWidget({super.key});

  static String routeName = 'oficina';
  static String routePath = '/oficina';

  @override
  State<OficinaWidget> createState() => _OficinaWidgetState();
}

class _OficinaWidgetState extends State<OficinaWidget> {
  late OficinaModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OficinaModel());
    _model.tFSearchMechanicShopTextController ??= TextEditingController();
    _model.tFSearchMechanicShopFocusNode ??= FocusNode();
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
          child: RegisterOficinaWidget(
            title: 'Cadastrar Oficina',
            btnAction: (email, name, cnpj, telefone, city, uf, cep, password,
                clientIds) async {
              _model.apiResultlcj = await CreateAccountAnotherUserCall.call(
                email: email,
                password: password,
              );
              if ((_model.apiResultlcj?.succeeded ?? true)) {
                final newUserId = CreateAccountAnotherUserCall.userID(
                  (_model.apiResultlcj?.jsonBody ?? ''),
                );
                await UsersTable().insert({
                  'id': newUserId,
                  'name': name,
                  'email': email,
                  'phone': telefone,
                  'profile_type': ProfileType.Oficina.name,
                  'is_active': true,
                  'is_deleted': false,
                  'is_admin': false,
                  'cpf': cnpj,
                  'fullname': name,
                  'status': UserStatus.approved.name,
                });
                if (newUserId != null && clientIds.isNotEmpty) {
                  for (final cid in clientIds) {
                    try {
                      await OficinaClientsTable().insert({
                        'oficina_id': newUserId,
                        'client_id': cid,
                      });
                    } catch (_) {}
                  }
                }
                final emailSent = await sendCredentialsEmail(
                  email: email,
                  password: password,
                  profileType: 'Oficina',
                  name: name,
                );
                if (!mounted) return;
                if (!emailSent) showCredentialsEmailWarning(context);
                _refresh();
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Oficina cadastrada com sucesso!',
                      style: GoogleFonts.inter(color: const Color(0xFF313131)),
                    ),
                    backgroundColor: const Color(0xFFC2D51C),
                  ),
                );
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ocorreu um erro, tente novamente'),
                    backgroundColor: Color(0xFFFF5963),
                  ),
                );
              }
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
            title: 'Deseja excluir esta oficina?',
            iconColor: const Color(0xFFFF5963),
            btnColor: const Color(0xFFFF5963),
            confirmBtnAction: () async {
              // A RPC exige Admin Master e LANÇA para os demais perfis.
              // Sem o runAction a exceção subia pelo handler async: o
              // diálogo ficava aberto e o usuário não recebia explicação.
              final ok = await runAction(
                context,
                dialogContext: dialogContext,
                contexto: 'oficinas.excluir',
                success: 'Oficina excluída',
                failure: 'Não foi possível excluir a oficina.',
                action: () => SupaFlow.client.rpc(
                  'admin_delete_app_user',
                  params: {'p_user_id': item.id},
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
      title: 'Oficinas',
      description:
          'Oficinas atuam em manutenção e podem cotar peças vinculadas a clientes.',
      actions: [
        _PrimaryAction(
          icon: Icons.build_outlined,
          label: 'Cadastrar oficina',
          onTap: _openCreate,
        ),
      ],
      search: AppSearchInput(
        value: _query,
        placeholder: 'Buscar por nome da oficina...',
        onChanged: (v) {
          setState(() => _query = v);
          _model.tFSearchMechanicShopTextController?.text = v;
          _refresh();
        },
      ),
      body: FutureBuilder<List<UsersRow>>(
        future: (_model.requestCompleter ??= Completer<List<UsersRow>>()
              ..complete(UsersTable().queryRows(
                queryFn: (q) => q
                    .eqOrNull('profile_type', ProfileType.Oficina.name)
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
                icon: Icons.build_outlined,
                title: _query.isEmpty
                    ? 'Nenhuma oficina cadastrada'
                    : 'Nenhuma oficina encontrada',
                description: _query.isEmpty
                    ? 'Crie a primeira oficina para começar.'
                    : 'Tente outro termo de busca.',
              ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OficinaRow(
                    item: list[i],
                    model: _model,
                    index: i,
                    onTap: () => context.pushNamed(
                      OficinaDetailsWidget.routeName,
                      queryParameters: {
                        'isEdit': serializeParam(false, ParamType.bool),
                        'userId':
                            serializeParam(list[i].id, ParamType.String),
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

class _OficinaRow extends StatelessWidget {
  const _OficinaRow({
    required this.item,
    required this.model,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  final UsersRow item;
  final OficinaModel model;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppPersonCard(
      name: item.fullname ?? 'Oficina sem nome',
      subtitle: item.email,
      avatarIcon: Icons.build_outlined,
      isActive: item.isActive ?? false,
      onTap: onTap,
      metas: [
        if ((item.phone ?? '').isNotEmpty)
          AppPersonMeta(Icons.phone_outlined, item.phone!),
        if ((item.cpf ?? '').isNotEmpty)
          AppPersonMeta(Icons.badge_outlined, 'CNPJ ${item.cpf!}'),
      ],
      trailing: [
        wrapWithModel(
          model: model.switchComponentModels.getModel(
            item.id ?? '$index',
            index,
          ),
          updateCallback: () {},
          child: SwitchComponentWidget(
            key: Key('ofc_switch_${item.id ?? index}'),
            initialValue: item.isActive ?? false,
            activeAction: () async {
              // guardWrite + returnRows: a RLS filtra em silêncio num
              // UPDATE (2xx com 0 linhas), então sem isso o switch virava na
              // tela e o toast confirmava algo que não foi gravado.
              final ok = await guardWrite(
                context,
                () => UsersTable().update(
                  data: {'is_active': true},
                  matchingRows: (rows) => rows.eqOrNull('id', item.id),
                  returnRows: true,
                ),
              );
              if (!ok || !context.mounted) return;
              _toast(context, 'Oficina ativada');
            },
            disableAction: () async {
              // guardWrite + returnRows: a RLS filtra em silêncio num
              // UPDATE (2xx com 0 linhas), então sem isso o switch virava na
              // tela e o toast confirmava algo que não foi gravado.
              final ok = await guardWrite(
                context,
                () => UsersTable().update(
                  data: {'is_active': false},
                  matchingRows: (rows) => rows.eqOrNull('id', item.id),
                  returnRows: true,
                ),
              );
              if (!ok || !context.mounted) return;
              _toast(context, 'Oficina desativada');
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
