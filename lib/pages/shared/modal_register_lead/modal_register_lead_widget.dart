import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'modal_register_lead_model.dart';

export 'modal_register_lead_model.dart';

class ModalRegisterLeadWidget extends StatefulWidget {
  const ModalRegisterLeadWidget({
    super.key,
    required this.btnAction,
  });

  final Future Function(
    String name,
    String lastname,
    String cpf,
    String company,
    String jobTitle,
    String email,
    String phone,
    String city,
    String uf,
    String createdBy,
  )? btnAction;

  @override
  State<ModalRegisterLeadWidget> createState() =>
      _ModalRegisterLeadWidgetState();
}

class _ModalRegisterLeadWidgetState extends State<ModalRegisterLeadWidget> {
  late ModalRegisterLeadModel _model;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ModalRegisterLeadModel());

    _model.tFNameTextController ??= TextEditingController();
    _model.tFNameFocusNode ??= FocusNode();

    _model.tFLastNameTextController ??= TextEditingController();
    _model.tFLastNameFocusNode ??= FocusNode();

    _model.tFCpfTextController ??= TextEditingController();
    _model.tFCpfFocusNode ??= FocusNode();
    _model.tFCpfMask = MaskTextInputFormatter(mask: '###.###.###-##');

    _model.tFEmpresaTextController ??= TextEditingController();
    _model.tFEmpresaFocusNode ??= FocusNode();

    _model.tFCargoTextController ??= TextEditingController();
    _model.tFCargoFocusNode ??= FocusNode();

    _model.tFEmailTextController ??= TextEditingController();
    _model.tFEmailFocusNode ??= FocusNode();

    _model.tFPhoneTextController ??= TextEditingController();
    _model.tFPhoneFocusNode ??= FocusNode();
    _model.tFPhoneMask = MaskTextInputFormatter(mask: '(##) # ####.####');

    _model.tFCityTextController ??= TextEditingController();
    _model.tFCityFocusNode ??= FocusNode();

    _model.tFZipCodeTextController ??= TextEditingController();
    _model.tFZipCodeFocusNode ??= FocusNode();
    _model.tFZipCodeMask = MaskTextInputFormatter(mask: 'AA');

    _model.tFCepTextController ??= TextEditingController();
    _model.tFCepFocusNode ??= FocusNode();
    _model.tFCepMask = MaskTextInputFormatter(mask: '#####-###');
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
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
          _model.tFZipCodeTextController?.text = uf;
        }
      });
    } catch (_) {
      // CEP inexistente / sem rede — silencia
    }
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
        _model.tFNameTextController!.text,
        _model.tFLastNameTextController!.text,
        _model.tFCpfTextController!.text,
        _model.tFEmpresaTextController!.text,
        _model.tFCargoTextController!.text,
        _model.tFEmailTextController!.text,
        _model.tFPhoneTextController!.text,
        _model.tFCityTextController!.text,
        _model.tFZipCodeTextController!.text,
        currentUserUid,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.person_add_alt_1_rounded,
      title: 'Cadastrar lead',
      description:
          'Adicione um novo contato comercial. Os campos com * são obrigatórios.',
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
            label: 'Cadastrar lead',
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
            const _SectionLabel(
              icon: Icons.badge_outlined,
              text: 'Dados pessoais',
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppFormField(
                    controller: _model.tFNameTextController,
                    focusNode: _model.tFNameFocusNode,
                    label: 'Nome',
                    placeholder: 'Ex.: Marina',
                    icon: Icons.person_outline_rounded,
                    required: true,
                    textInputAction: TextInputAction.next,
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
                    placeholder: 'Ex.: Silva',
                    required: true,
                    textInputAction: TextInputAction.next,
                    validator: (v) => _model.tFLastNameTextControllerValidator
                        ?.call(context, v),
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
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  _model.tFCpfTextControllerValidator?.call(context, v),
            ),
            const SizedBox(height: 22),
            const _SectionLabel(
              icon: Icons.business_center_outlined,
              text: 'Empresa',
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppFormField(
                    controller: _model.tFEmpresaTextController,
                    focusNode: _model.tFEmpresaFocusNode,
                    label: 'Empresa',
                    placeholder: 'Razão social ou marca',
                    icon: Icons.apartment_outlined,
                    required: true,
                    textInputAction: TextInputAction.next,
                    validator: (v) => _model.tFEmpresaTextControllerValidator
                        ?.call(context, v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppFormField(
                    controller: _model.tFCargoTextController,
                    focusNode: _model.tFCargoFocusNode,
                    label: 'Cargo',
                    placeholder: 'Ex.: Diretor',
                    required: true,
                    textInputAction: TextInputAction.next,
                    validator: (v) => _model.tFCargoTextControllerValidator
                        ?.call(context, v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionLabel(
              icon: Icons.contact_mail_outlined,
              text: 'Contato',
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppFormField(
                    controller: _model.tFEmailTextController,
                    focusNode: _model.tFEmailFocusNode,
                    label: 'E-mail',
                    placeholder: 'nome@empresa.com',
                    icon: Icons.alternate_email_rounded,
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
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
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        _model.tFPhoneTextControllerValidator?.call(context, v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionLabel(
              icon: Icons.location_on_outlined,
              text: 'Endereço',
            ),
            const SizedBox(height: 12),
            AppFormField(
              controller: _model.tFCepTextController,
              focusNode: _model.tFCepFocusNode,
              label: 'CEP',
              placeholder: '00000-000',
              icon: Icons.local_post_office_outlined,
              helper: 'Cidade e UF são preenchidos automaticamente.',
              required: true,
              keyboardType: TextInputType.number,
              inputFormatters: [_model.tFCepMask],
              textInputAction: TextInputAction.next,
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
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        _model.tFCityTextControllerValidator?.call(context, v),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 88,
                  child: AppFormField(
                    controller: _model.tFZipCodeTextController,
                    focusNode: _model.tFZipCodeFocusNode,
                    label: 'UF',
                    placeholder: 'UF',
                    required: true,
                    inputFormatters: [_model.tFZipCodeMask],
                    textInputAction: TextInputAction.done,
                    validator: (v) => _model.tFZipCodeTextControllerValidator
                        ?.call(context, v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});

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

