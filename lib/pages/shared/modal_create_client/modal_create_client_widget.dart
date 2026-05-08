import 'package:flutter/material.dart';

import '/backend/api_requests/api_calls.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
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

  String _generatePassword() {
    final src = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return 'Ag${src.substring(src.length - 6)}!';
  }

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
    setState(() => _busy = true);
    try {
      _model.authUserResponse = await CreateAccountAnotherUserCall.call(
        email: _model.tFEmailUserTextController!.text,
        password: _model.tFPasswordUserTextController!.text,
      );
      if (!(_model.authUserResponse?.succeeded ?? false)) {
        if (!mounted) return;
        Navigator.of(context).pop();
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Erro'),
            content: const Text(
                'Algo deu errado! Não foi possível cadastrar a conta do usuário. Por favor, tente novamente!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Ok'),
              ),
            ],
          ),
        );
        return;
      }
      final newUser = await UsersTable().insert({
        'id': getJsonField(
          _model.authUserResponse?.jsonBody ?? '',
          r'$.user.id',
        ).toString(),
        'name': _selectedLead?.name ?? 'vazio',
        'email': getJsonField(
          _model.authUserResponse?.jsonBody ?? '',
          r'$.user.email',
        ).toString(),
        'phone': _selectedLead?.phone ?? 'vazio',
        'profile_type': ProfileType.Cliente.name,
        'cpf': _selectedLead?.cpf ?? 'vazio',
        'status': UserStatus.approved.name,
        'lastname': _selectedLead?.lastName ?? 'vazio',
        'fullname': _selectedLead?.fullname ?? 'vazio',
      });
      await TrackingTable().insert({
        'user_aircraft': newUser.id,
        'tracking_description': 'Cadastro Inicial',
        'order': 0,
      });
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LeadsRow>>(
      future: LeadsTable().queryRows(
        queryFn: (q) =>
            q.eqOrNull('active', true).order('fullname', ascending: true),
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
                        placeholder: 'Mínimo 6 caracteres',
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
