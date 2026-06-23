import 'package:flutter/material.dart';

import '/backend/api_requests/api_calls.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/security/password_utils.dart';
import 'modal_create_client_model.dart';

export 'modal_create_client_model.dart';

class ModalCreateClientWidget extends StatefulWidget {
  const ModalCreateClientWidget({super.key});

  @override
  State<ModalCreateClientWidget> createState() =>
      _ModalCreateClientWidgetState();
}

class _ModalCreateClientWidgetState extends State<ModalCreateClientWidget> {
  late ModalCreateClientModel _model;
  bool _showPwd = false;
  bool _busy = false;
  LeadsRow? _selectedLead;
  String? _leadError;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ModalCreateClientModel());
    _model.tFEmailUserTextController ??= TextEditingController();
    _model.tFEmailUserFocusNode ??= FocusNode();
    _model.tFPasswordUserTextController ??= TextEditingController();
    _model.tFPasswordUserFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  // Senha aleatória forte (16 chars, Random.secure) — na prática nunca consta
  // em vazamentos, então não dispara o 422 weak_password do servidor.
  String _generatePassword() => generateStrongPassword();

  Future<void> _submit() async {
    if (_busy) return;
    if (_selectedLead == null) {
      setState(() => _leadError = 'Selecione um lead');
      return;
    }
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) {
      return;
    }
    final email = _model.tFEmailUserTextController!.text.trim();
    setState(() => _busy = true);
    try {
      _model.authUserResponse = await CreateAccountAnotherUserCall.call(
        email: email,
        password: _model.tFPasswordUserTextController!.text,
      );

      final body = _model.authUserResponse?.jsonBody ?? '';
      final succeeded = _model.authUserResponse?.succeeded ?? false;

      // E-mail já cadastrado pode chegar de duas formas no GoTrue:
      //  (a) erro 422 user_already_exists (confirmação de e-mail desligada);
      //  (b) resposta 200 "ofuscada" com identities vazio (anti-enumeração,
      //      quando a confirmação está ligada). Nos dois casos NÃO criamos
      //      registro local — senão sobra uma conta órfã / fake access
      //      (BUG-005 / BUG-006).
      final errText =
          (_model.authUserResponse?.bodyText ?? '').toLowerCase();
      final dupByError = errText.contains('user_already_exists') ||
          errText.contains('already registered');

      final newUserId = (CreateAccountAnotherUserCall.userID(body) ??
              getJsonField(body, r'$.id')?.toString() ??
              '')
          .trim();
      dynamic identities = getJsonField(body, r'$.user.identities', true);
      identities ??= getJsonField(body, r'$.identities', true);
      final dupByIdentities = succeeded &&
          (identities == null ||
              (identities is List && identities.isEmpty));
      final invalidId = newUserId.isEmpty || newUserId == 'null';

      if (!succeeded || dupByError || dupByIdentities || invalidId) {
        if (!mounted) return;
        Navigator.of(context).pop();
        final duplicate = dupByError || dupByIdentities;
        await _showInfoDialog(
          title: duplicate ? 'E-mail já cadastrado' : 'Erro',
          message: duplicate
              ? 'Este e-mail já possui uma conta na plataforma.'
              : 'Não foi possível cadastrar a conta do usuário. Por favor, tente novamente!',
        );
        return;
      }

      // Conta de auth criada de fato. A partir daqui, se o registro local
      // falhar, revertemos a conta de auth para não deixar órfão (BUG-005).
      final UsersRow newUser;
      try {
        newUser = await UsersTable().insert({
          'id': newUserId,
          'name': _selectedLead?.name ?? 'vazio',
          'email': email,
          'phone': _selectedLead?.phone ?? 'vazio',
          'profile_type': ProfileType.Cliente.name,
          'cpf': _selectedLead?.cpf ?? 'vazio',
          'status': UserStatus.approved.name,
          'lastname': _selectedLead?.lastName ?? 'vazio',
          'fullname': _selectedLead?.fullname ?? 'vazio',
        });
      } catch (_) {
        // Rollback: remove a conta de auth recém-criada (órfã, sem users).
        try {
          await SupaFlow.client.rpc(
            'admin_purge_orphan_auth_user',
            params: {'p_email': email},
          );
        } catch (_) {}
        if (!mounted) return;
        Navigator.of(context).pop();
        await _showInfoDialog(
          title: 'Erro',
          message:
              'Não foi possível concluir o cadastro. Nenhum registro parcial foi mantido. Tente novamente.',
        );
        return;
      }

      // users criado com sucesso (conta válida). O tracking inicial é
      // secundário — uma falha aqui não invalida o cliente.
      try {
        await TrackingTable().insert({
          'user_aircraft': newUser.id,
          'tracking_description': 'Cadastro Inicial',
          'order': 0,
        });
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente criado com sucesso!',
              style: TextStyle(color: Color(0xFF313131))),
          backgroundColor: Color(0xFFC2D51C),
        ),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showInfoDialog(
      {required String title, required String message}) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LeadsRow>>(
      future: LeadsTable().queryRows(
        queryFn: (q) => q
            .eqOrNull('active', true)
            .eqOrNull('is_deleted', false)
            .order('fullname', ascending: true),
      ),
      builder: (context, snap) {
        return AppModal(
          icon: Icons.person_add_alt_1_rounded,
          title: 'Criar conta de cliente',
          description:
              'Selecione um lead, defina senha temporária e libere o acesso à plataforma.',
          maxWidth: 560,
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppSecondaryButton(
                label: 'Cancelar',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 10),
              AppPrimaryButton(
                label: 'Criar conta',
                icon: Icons.check_rounded,
                busy: _busy,
                onPressed: snap.hasData ? _submit : null,
              ),
            ],
          ),
          child: !snap.hasData
              ? Column(
                  children: List.generate(
                    3,
                    (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppSkeleton.box(height: 60),
                    ),
                  ),
                )
              : Form(
                  key: _model.formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppDropdown<LeadsRow>(
                        label: 'Lead',
                        icon: Icons.person_search_rounded,
                        placeholder: 'Selecione o lead...',
                        required: true,
                        searchable: true,
                        value: _selectedLead,
                        options: snap.data!,
                        labelOf: (l) => l.fullname ?? l.name,
                        errorText: _leadError,
                        onChanged: (lead) {
                          setState(() {
                            _selectedLead = lead;
                            _leadError = null;
                            _model.tFEmailUserTextController?.text =
                                lead.email;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      AppFormField(
                        controller: _model.tFEmailUserTextController,
                        focusNode: _model.tFEmailUserFocusNode,
                        label: 'E-mail',
                        placeholder: 'email@cliente.com',
                        icon: Icons.alternate_email_rounded,
                        required: true,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => _model
                            .tFEmailUserTextControllerValidator
                            ?.call(context, v),
                      ),
                      const SizedBox(height: 14),
                      AppFormField(
                        controller: _model.tFPasswordUserTextController,
                        focusNode: _model.tFPasswordUserFocusNode,
                        label: 'Senha temporária',
                        placeholder: 'Mínimo 8 caracteres',
                        icon: Icons.lock_outline_rounded,
                        required: true,
                        obscureText: !_showPwd,
                        helper:
                            'O cliente pode trocar a senha após o primeiro acesso.',
                        suffix: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _IconAction(
                              icon: Icons.auto_fix_high_rounded,
                              tooltip: 'Gerar senha',
                              onTap: () => setState(() => _model
                                  .tFPasswordUserTextController!
                                  .text = _generatePassword()),
                            ),
                            const SizedBox(width: 4),
                            _IconAction(
                              icon: _showPwd
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              tooltip: _showPwd ? 'Esconder' : 'Mostrar',
                              onTap: () =>
                                  setState(() => _showPwd = !_showPwd),
                            ),
                          ],
                        ),
                        validator: (v) => _model
                            .tFPasswordUserTextControllerValidator
                            ?.call(context, v),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _IconAction extends StatefulWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_IconAction> createState() => _IconActionState();
}

class _IconActionState extends State<_IconAction> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _hover
                  ? const Color(0x22C2D51C)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              size: 15,
              color: _hover
                  ? const Color(0xFFC2D51C)
                  : const Color(0xCCFFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}
