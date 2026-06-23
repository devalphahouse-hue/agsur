import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '/backend/api_requests/api_calls.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/security/password_utils.dart';
import 'modal_register_seller_model.dart';

export 'modal_register_seller_model.dart';

class ModalRegisterSellerWidget extends StatefulWidget {
  const ModalRegisterSellerWidget({
    super.key,
    required this.refreshDatabase,
  });

  final Future Function()? refreshDatabase;

  @override
  State<ModalRegisterSellerWidget> createState() =>
      _ModalRegisterSellerWidgetState();
}

class _ModalRegisterSellerWidgetState
    extends State<ModalRegisterSellerWidget> {
  late ModalRegisterSellerModel _model;
  bool _showPwd = false;
  bool _busy = false;
  String _pwd = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ModalRegisterSellerModel());
    _model.tFNameTextController ??= TextEditingController();
    _model.tFNameFocusNode ??= FocusNode();
    _model.tFLastNameTextController ??= TextEditingController();
    _model.tFLastNameFocusNode ??= FocusNode();
    _model.tFCpfTextController ??= TextEditingController();
    _model.tFCpfFocusNode ??= FocusNode();
    _model.tFCpfMask = MaskTextInputFormatter(mask: '###.###.###-##');
    _model.tFEmailTextController ??= TextEditingController();
    _model.tFEmailFocusNode ??= FocusNode();
    _model.tFPhoneTextController ??= TextEditingController();
    _model.tFPhoneFocusNode ??= FocusNode();
    _model.tFPhoneMask = MaskTextInputFormatter(mask: '(##) # ####-####');
    _model.tFCityTextController ??= TextEditingController();
    _model.tFCityFocusNode ??= FocusNode();
    _model.tFZIpCodeTextController ??= TextEditingController();
    _model.tFZIpCodeFocusNode ??= FocusNode();
    _model.tFCepTextController ??= TextEditingController();
    _model.tFCepFocusNode ??= FocusNode();
    _model.tFCepMask = MaskTextInputFormatter(mask: '#####-###');
    _model.tFPasswordUserTextController ??= TextEditingController();
    _model.tFPasswordUserFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  void _fillStrongPassword() {
    final pwd = generateStrongPassword();
    setState(() {
      _model.tFPasswordUserTextController?.text = pwd;
      _pwd = pwd;
      _showPwd = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Senha forte gerada. Copie e repasse ao usuário — ele poderá trocá-la depois.'),
        backgroundColor: Color(0xFFC2D51C),
      ),
    );
  }

  Future<void> _onCepChanged(String val) async {
    final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 8 || _model.lastCepLookup == digits) return;
    _model.lastCepLookup = digits;
    try {
      final response = await ViaCepCall.call(cep: digits);
      if (!mounted) return;
      _model.cep = response;
      if (!response.succeeded) return;
      final body = response.jsonBody;
      final localidade = ViaCepCall.localidade(body);
      final uf = ViaCepCall.uf(body);
      if (localidade == null || localidade.isEmpty) return;
      setState(() {
        _model.tFCityTextController?.text = localidade;
        if (uf != null && uf.isNotEmpty) {
          _model.tFZIpCodeTextController?.text = uf;
        }
      });
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      _model.createAuthUserSeller = await CreateAccountAnotherUserCall.call(
        email: _model.tFEmailTextController!.text,
        password: _model.tFPasswordUserTextController!.text,
      );
      if (!(_model.createAuthUserSeller?.succeeded ?? false)) {
        if (!mounted) return;
        Navigator.of(context).pop();
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Erro'),
            content: const Text(
                'Algo de errado! Não foi possível criar a conta do vendedor, verifique e tente novamente!'),
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
      _model.createUserSeller = await UsersTable().insert({
        'id': CreateAccountAnotherUserCall.userID(
          _model.createAuthUserSeller?.jsonBody ?? '',
        ),
        'name': _model.tFNameTextController!.text,
        'email': CreateAccountAnotherUserCall.emailUser(
          _model.createAuthUserSeller?.jsonBody ?? '',
        ),
        'phone': _model.tFPhoneTextController!.text,
        'profile_type': ProfileType.Vendedor.name,
        'cpf': _model.tFCpfTextController!.text,
        'status': UserStatus.approved.name,
        'lastname': _model.tFLastNameTextController!.text,
        'fullname':
            '${_model.tFNameTextController!.text} ${_model.tFLastNameTextController!.text}'
                .trim(),
      });
      await widget.refreshDatabase?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vendedor cadastrado com sucesso!',
            style: GoogleFonts.roboto(color: const Color(0xFF313131)),
          ),
          backgroundColor: const Color(0xFFC2D51C),
          duration: const Duration(milliseconds: 4000),
        ),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.person_add_alt_1_rounded,
      title: 'Cadastrar vendedor',
      description:
          'Crie uma conta de vendedor com acesso ao painel administrativo.',
      maxWidth: 720,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          AppPrimaryButton(
            label: 'Cadastrar vendedor',
            icon: Icons.check_rounded,
            busy: _busy,
            onPressed: _submit,
          ),
        ],
      ),
      child: Form(
        key: _model.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UserSection(
                icon: Icons.person_outline_rounded, text: 'Dados pessoais'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppFormField(
                    controller: _model.tFNameTextController,
                    focusNode: _model.tFNameFocusNode,
                    label: 'Nome',
                    placeholder: 'Nome',
                    icon: Icons.person_outline_rounded,
                    required: true,
                    validator: (v) =>
                        _model.tFNameTextControllerValidator?.call(context, v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppFormField(
                    controller: _model.tFLastNameTextController,
                    focusNode: _model.tFLastNameFocusNode,
                    label: 'Sobrenome',
                    placeholder: 'Sobrenome',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppFormField(
              controller: _model.tFCpfTextController,
              focusNode: _model.tFCpfFocusNode,
              label: 'CPF',
              placeholder: '000.000.000-00',
              icon: Icons.badge_outlined,
              required: true,
              keyboardType: TextInputType.number,
              inputFormatters: [_model.tFCpfMask],
              validator: (v) =>
                  _model.tFCpfTextControllerValidator?.call(context, v),
            ),
            const SizedBox(height: 22),
            _UserSection(
                icon: Icons.contact_mail_outlined, text: 'Contato'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppFormField(
                    controller: _model.tFEmailTextController,
                    focusNode: _model.tFEmailFocusNode,
                    label: 'E-mail',
                    placeholder: 'vendedor@empresa.com',
                    icon: Icons.alternate_email_rounded,
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        _model.tFEmailTextControllerValidator?.call(context, v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppFormField(
                    controller: _model.tFPhoneTextController,
                    focusNode: _model.tFPhoneFocusNode,
                    label: 'Telefone',
                    placeholder: '(00) 9 0000-0000',
                    icon: Icons.phone_iphone_rounded,
                    required: true,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_model.tFPhoneMask],
                    validator: (v) =>
                        _model.tFPhoneTextControllerValidator?.call(context, v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppFormField(
              controller: _model.tFCepTextController,
              focusNode: _model.tFCepFocusNode,
              label: 'CEP',
              placeholder: '00000-000',
              icon: Icons.local_post_office_outlined,
              required: true,
              keyboardType: TextInputType.number,
              inputFormatters: [_model.tFCepMask],
              helper: 'Cidade e UF são preenchidos automaticamente.',
              onChanged: _onCepChanged,
              validator: (v) =>
                  _model.tFCepTextControllerValidator?.call(context, v),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppFormField(
                    controller: _model.tFCityTextController,
                    focusNode: _model.tFCityFocusNode,
                    label: 'Cidade',
                    placeholder: 'Cidade',
                    icon: Icons.location_city_rounded,
                    required: true,
                    validator: (v) =>
                        _model.tFCityTextControllerValidator?.call(context, v),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 88,
                  child: AppFormField(
                    controller: _model.tFZIpCodeTextController,
                    focusNode: _model.tFZIpCodeFocusNode,
                    label: 'UF',
                    placeholder: 'UF',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _UserSection(icon: Icons.lock_outline_rounded, text: 'Acesso'),
            const SizedBox(height: 12),
            AppFormField(
              controller: _model.tFPasswordUserTextController,
              focusNode: _model.tFPasswordUserFocusNode,
              label: 'Senha',
              placeholder: 'Crie uma senha forte',
              helper: kPasswordRuleHint,
              icon: Icons.lock_rounded,
              required: true,
              obscureText: !_showPwd,
              suffix: _Eye(
                visible: _showPwd,
                onTap: () => setState(() => _showPwd = !_showPwd),
              ),
              onChanged: (v) => setState(() => _pwd = v),
              validator: (v) => _model.tFPasswordUserTextControllerValidator
                  ?.call(context, v),
            ),
            PasswordStrengthMeter(password: _pwd),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _fillStrongPassword,
                icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                label: const Text('Gerar senha forte'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserSection extends StatelessWidget {
  const _UserSection({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0x33C2D51C),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: const Color(0xFFC2D51C)),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.92),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}

class _Eye extends StatefulWidget {
  const _Eye({required this.visible, required this.onTap});
  final bool visible;
  final VoidCallback onTap;

  @override
  State<_Eye> createState() => _EyeState();
}

class _EyeState extends State<_Eye> {
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
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _hover ? const Color(0x22C2D51C) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.visible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 15,
            color:
                _hover ? const Color(0xFFC2D51C) : const Color(0xCCFFFFFF),
          ),
        ),
      ),
    );
  }
}
