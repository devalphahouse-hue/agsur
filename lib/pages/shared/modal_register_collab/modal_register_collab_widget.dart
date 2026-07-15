import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '/backend/api_requests/api_calls.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/security/credentials_email.dart';
import '/security/password_utils.dart';
import 'modal_register_collab_model.dart';

export 'modal_register_collab_model.dart';

class ModalRegisterCollabWidget extends StatefulWidget {
  const ModalRegisterCollabWidget({
    super.key,
    required this.databaseRefresh,
  });

  final Future Function()? databaseRefresh;

  @override
  State<ModalRegisterCollabWidget> createState() =>
      _ModalRegisterCollabWidgetState();
}

class _ModalRegisterCollabWidgetState
    extends State<ModalRegisterCollabWidget> {
  late ModalRegisterCollabModel _model;
  bool _showPwd = false;
  bool _busy = false;
  String _pwd = '';
  // Nível de acesso do colaborador: 'admin_master' | 'recepcao' | 'documentacao'.
  String _accessLevel = 'recepcao';

  static const List<String> _levelOptions = [
    'admin_master',
    'recepcao',
    'documentacao',
  ];

  String _levelLabel(String v) {
    switch (v) {
      case 'admin_master':
        return 'Admin master — acesso total';
      case 'documentacao':
        return 'Admin documentação';
      default:
        return 'Admin recepção';
    }
  }

  // Dropdown compacto (menu ancorado ao campo) para o nível de acesso — o
  // AppDropdown padrão abre um bottom sheet de tela cheia, ruim no desktop.
  Widget _buildLevelField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Nível de acesso',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            Text(' *',
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: const Color(0xFFE05656))),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF232323),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined,
                  size: 18, color: Color(0xCCFFFFFF)),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _accessLevel,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF262626),
                    borderRadius: BorderRadius.circular(12),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0xCCFFFFFF)),
                    style: GoogleFonts.roboto(
                        color: Colors.white, fontSize: 14),
                    items: _levelOptions
                        .map((v) => DropdownMenuItem(
                            value: v, child: Text(_levelLabel(v))))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _accessLevel = v ?? _accessLevel),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Define quais telas do painel o colaborador poderá acessar.',
          style: GoogleFonts.roboto(
            fontSize: 11.5,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ModalRegisterCollabModel());
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
    _model.tFPhoneMask = MaskTextInputFormatter(mask: '(##) # ####.####');
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
      final auth = await CreateAccountAnotherUserCall.call(
        email: _model.tFEmailTextController!.text,
        password: _model.tFPasswordUserTextController!.text,
      );
      if (!(auth.succeeded)) {
        if (!mounted) return;
        Navigator.of(context).pop();
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Erro'),
            content: const Text(
                'Não foi possível criar a conta do colaborador. Verifique e tente novamente!'),
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
      final isMaster = _accessLevel == 'admin_master';
      await UsersTable().insert({
        'id': CreateAccountAnotherUserCall.userID(auth.jsonBody),
        'name': _model.tFNameTextController!.text,
        'email': CreateAccountAnotherUserCall.emailUser(auth.jsonBody),
        'phone': _model.tFPhoneTextController!.text,
        'profile_type': isMaster ? 'Admin Master' : ProfileType.Admin.name,
        'access_level': isMaster ? null : _accessLevel,
        'cpf': _model.tFCpfTextController!.text,
        'status': UserStatus.approved.name,
        'lastname': _model.tFLastNameTextController!.text,
        'fullname':
            '${_model.tFNameTextController!.text} ${_model.tFLastNameTextController!.text}'
                .trim(),
      });
      final emailSent = await sendCredentialsEmail(
        email: _model.tFEmailTextController!.text,
        password: _model.tFPasswordUserTextController!.text,
        profileType: 'Colaborador',
        name: _model.tFNameTextController!.text,
      );
      await widget.databaseRefresh?.call();
      if (!mounted) return;
      if (!emailSent) showCredentialsEmailWarning(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Colaborador cadastrado com sucesso!',
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
      icon: Icons.badge_outlined,
      title: 'Cadastrar colaborador',
      description:
          'Crie uma conta interna com perfil administrativo no painel.',
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
            label: 'Cadastrar colaborador',
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
            _CollabSection(
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
            _CollabSection(
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
                    placeholder: 'colab@empresa.com',
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
                    placeholder: '(00) 9 0000.0000',
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
            _CollabSection(icon: Icons.lock_outline_rounded, text: 'Acesso'),
            const SizedBox(height: 12),
            _buildLevelField(),
            const SizedBox(height: 14),
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

class _CollabSection extends StatelessWidget {
  const _CollabSection({required this.icon, required this.text});
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
