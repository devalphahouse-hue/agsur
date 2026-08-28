import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '/backend/api_requests/api_calls.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/shared/client_multi_select/client_multi_select_widget.dart';
import '/security/password_utils.dart';
import 'register_oficina_model.dart';

export 'register_oficina_model.dart';

class RegisterOficinaWidget extends StatefulWidget {
  const RegisterOficinaWidget({
    super.key,
    required this.title,
    required this.btnAction,
  });

  final String? title;
  final Future Function(
    String email,
    String name,
    String cnpj,
    String telefone,
    String city,
    String uf,
    String cep,
    String password,
    Set<String> clientIds,
  )? btnAction;

  @override
  State<RegisterOficinaWidget> createState() => _RegisterOficinaWidgetState();
}

class _RegisterOficinaWidgetState extends State<RegisterOficinaWidget> {
  late RegisterOficinaModel _model;
  bool _showPwd = false;
  bool _busy = false;
  String _pwd = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RegisterOficinaModel());

    _model.tFEditNameTextController ??= TextEditingController();
    _model.tFEditNameFocusNode ??= FocusNode();
    _model.tFEditCpfTextController ??= TextEditingController();
    _model.tFEditCpfFocusNode ??= FocusNode();
    _model.tFEditCpfMask = MaskTextInputFormatter(mask: '##.###.###/####-##');
    _model.tFEditEmailTextController ??= TextEditingController();
    _model.tFEditEmailFocusNode ??= FocusNode();
    _model.tFEditPhoneTextController ??= TextEditingController();
    _model.tFEditPhoneFocusNode ??= FocusNode();
    _model.tFEditPhoneMask = MaskTextInputFormatter(mask: '(##) # ####.####');
    _model.tFEditCityTextController ??= TextEditingController();
    _model.tFEditCityFocusNode ??= FocusNode();
    _model.tFEditZipCodeTextController ??= TextEditingController();
    _model.tFEditZipCodeFocusNode ??= FocusNode();
    _model.tFEditZipCodeMask = MaskTextInputFormatter(mask: 'AA');
    _model.tFEditCepTextController ??= TextEditingController();
    _model.tFEditCepFocusNode ??= FocusNode();
    _model.tFEditCepMask = MaskTextInputFormatter(mask: '#####-###');
    _model.tFEditPasswordTextController ??= TextEditingController();
    _model.tFEditPasswordFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  void _fillStrongPassword() {
    final pwd = generateAppUserPassword();
    setState(() {
      _model.tFEditPasswordTextController?.text = pwd;
      _pwd = pwd;
      _showPwd = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Senha forte gerada. Copie e repasse à oficina — ela poderá trocá-la depois.'),
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
        _model.tFEditCityTextController?.text = localidade;
        if (uf != null && uf.isNotEmpty) {
          _model.tFEditZipCodeTextController?.text = uf;
        }
      });
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.btnAction?.call(
        _model.tFEditEmailTextController!.text,
        _model.tFEditNameTextController!.text,
        _model.tFEditCpfTextController!.text,
        _model.tFEditPhoneTextController!.text,
        _model.tFEditCityTextController!.text,
        _model.tFEditZipCodeTextController!.text,
        _model.tFEditCepTextController!.text,
        _model.tFEditPasswordTextController!.text,
        _model.selectedClientIds,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.handyman_rounded,
      title: widget.title ?? 'Cadastrar oficina',
      description:
          'Cadastre uma oficina e vincule aos clientes que ela atende.',
      maxWidth: 760,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          AppPrimaryButton(
            label: 'Cadastrar oficina',
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
            _Section(icon: Icons.store_mall_directory_outlined, text: 'Oficina'),
            const SizedBox(height: 12),
            AppFormField(
              controller: _model.tFEditNameTextController,
              focusNode: _model.tFEditNameFocusNode,
              label: 'Razão social',
              placeholder: 'Nome da oficina',
              icon: Icons.business_rounded,
              required: true,
              validator: (v) => _model.tFEditNameTextControllerValidator
                  ?.call(context, v),
            ),
            const SizedBox(height: 14),
            AppFormField(
              controller: _model.tFEditCpfTextController,
              focusNode: _model.tFEditCpfFocusNode,
              label: 'CNPJ',
              placeholder: '00.000.000/0000-00',
              icon: Icons.badge_outlined,
              required: true,
              keyboardType: TextInputType.number,
              inputFormatters: [_model.tFEditCpfMask],
              validator: (v) =>
                  _model.tFEditCpfTextControllerValidator?.call(context, v),
            ),
            const SizedBox(height: 22),
            _Section(icon: Icons.contact_mail_outlined, text: 'Contato'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppFormField(
                    controller: _model.tFEditEmailTextController,
                    focusNode: _model.tFEditEmailFocusNode,
                    label: 'E-mail',
                    placeholder: 'oficina@empresa.com',
                    icon: Icons.alternate_email_rounded,
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => _model.tFEditEmailTextControllerValidator
                        ?.call(context, v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppFormField(
                    controller: _model.tFEditPhoneTextController,
                    focusNode: _model.tFEditPhoneFocusNode,
                    label: 'Telefone',
                    placeholder: '(00) 9 0000.0000',
                    icon: Icons.phone_iphone_rounded,
                    required: true,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_model.tFEditPhoneMask],
                    validator: (v) => _model.tFEditPhoneTextControllerValidator
                        ?.call(context, v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _Section(icon: Icons.location_on_outlined, text: 'Endereço'),
            const SizedBox(height: 12),
            AppFormField(
              controller: _model.tFEditCepTextController,
              focusNode: _model.tFEditCepFocusNode,
              label: 'CEP',
              placeholder: '00000-000',
              icon: Icons.local_post_office_outlined,
              required: true,
              keyboardType: TextInputType.number,
              inputFormatters: [_model.tFEditCepMask],
              helper: 'Cidade e UF são preenchidos automaticamente.',
              onChanged: _onCepChanged,
              validator: (v) =>
                  _model.tFEditCepTextControllerValidator?.call(context, v),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppFormField(
                    controller: _model.tFEditCityTextController,
                    focusNode: _model.tFEditCityFocusNode,
                    label: 'Cidade',
                    placeholder: 'Cidade',
                    icon: Icons.location_city_rounded,
                    required: true,
                    validator: (v) => _model.tFEditCityTextControllerValidator
                        ?.call(context, v),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 88,
                  child: AppFormField(
                    controller: _model.tFEditZipCodeTextController,
                    focusNode: _model.tFEditZipCodeFocusNode,
                    label: 'UF',
                    placeholder: 'UF',
                    required: true,
                    inputFormatters: [_model.tFEditZipCodeMask],
                    validator: (v) => _model
                        .tFEditZipCodeTextControllerValidator
                        ?.call(context, v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _Section(icon: Icons.lock_outline_rounded, text: 'Acesso'),
            const SizedBox(height: 12),
            AppFormField(
              controller: _model.tFEditPasswordTextController,
              focusNode: _model.tFEditPasswordFocusNode,
              label: 'Senha de acesso',
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
              validator: (v) => _model.tFEditPasswordTextControllerValidator
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
            const SizedBox(height: 22),
            _Section(icon: Icons.groups_outlined, text: 'Clientes vinculados'),
            const SizedBox(height: 12),
            ClientMultiSelectWidget(
              selectedIds: _model.selectedClientIds,
              onChanged: (ids) =>
                  setState(() => _model.selectedClientIds = ids),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.text});
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
