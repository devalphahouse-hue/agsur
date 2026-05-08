import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/shared/client_multi_select/client_multi_select_widget.dart';
import 'modal_register_pilot_model.dart';

export 'modal_register_pilot_model.dart';

class ModalRegisterPilotWidget extends StatefulWidget {
  const ModalRegisterPilotWidget({
    super.key,
    required this.btnAction,
  });

  final Future Function(
    String name,
    String lastname,
    String fullname,
    String cpf,
    String email,
    String phone,
    String city,
    String uf,
    String password,
    Set<String> clientIds,
  )? btnAction;

  @override
  State<ModalRegisterPilotWidget> createState() =>
      _ModalRegisterPilotWidgetState();
}

class _ModalRegisterPilotWidgetState extends State<ModalRegisterPilotWidget> {
  late ModalRegisterPilotModel _model;
  bool _showPwd = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ModalRegisterPilotModel());
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
    _model.tFPasswordUserTextController ??= TextEditingController();
    _model.tFPasswordUserFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final name = _model.tFNameTextController!.text;
      final last = _model.tFLastNameTextController!.text;
      await widget.btnAction?.call(
        name,
        last,
        '$name $last'.trim(),
        _model.tFCpfTextController!.text,
        _model.tFEmailTextController!.text,
        _model.tFPhoneTextController!.text,
        _model.tFCityTextController!.text,
        _model.tFZIpCodeTextController!.text,
        _model.tFPasswordUserTextController!.text,
        _model.selectedClientIds,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.flight_rounded,
      title: 'Cadastrar piloto',
      description:
          'Cadastre um piloto e vincule aos clientes que ele atende.',
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
            label: 'Cadastrar piloto',
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
            const _PilotSection(
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
            const _PilotSection(
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
                    placeholder: 'piloto@email.com',
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
            const _PilotSection(
                icon: Icons.lock_outline_rounded, text: 'Acesso'),
            const SizedBox(height: 12),
            AppFormField(
              controller: _model.tFPasswordUserTextController,
              focusNode: _model.tFPasswordUserFocusNode,
              label: 'Senha',
              placeholder: 'Mínimo 6 caracteres',
              icon: Icons.lock_rounded,
              required: true,
              obscureText: !_showPwd,
              suffix: _Eye(
                visible: _showPwd,
                onTap: () => setState(() => _showPwd = !_showPwd),
              ),
              validator: (v) => _model.tFPasswordUserTextControllerValidator
                  ?.call(context, v),
            ),
            const SizedBox(height: 22),
            const _PilotSection(
                icon: Icons.groups_outlined, text: 'Clientes vinculados'),
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

class _PilotSection extends StatelessWidget {
  const _PilotSection({required this.icon, required this.text});
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
