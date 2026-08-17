import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/commission.dart';
import '/security/access_control.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'modal_register_lead_model.dart';

export 'modal_register_lead_model.dart';

class ModalRegisterLeadWidget extends StatefulWidget {
  const ModalRegisterLeadWidget({
    super.key,
    required this.btnAction,
  });

  /// [referral] é `null` quando a caixa "Indicação de venda" fica desmarcada.
  /// Quem persiste deve passá-lo por `leadReferralColumns` — ele também LIMPA
  /// os campos quando é null.
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
    ReferralInfo? referral,
  )? btnAction;

  @override
  State<ModalRegisterLeadWidget> createState() =>
      _ModalRegisterLeadWidgetState();
}

class _ModalRegisterLeadWidgetState extends State<ModalRegisterLeadWidget> {
  late ModalRegisterLeadModel _model;
  bool _busy = false;

  /// Mesma régua da trigger no banco (master + documentação). Vendedor não
  /// registra indicação: avisa quem registra.
  bool get _canEditReferral =>
      AccessControl.canEditFunil(AccessControl.current);

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

    _model.tFReferralNameTextController ??= TextEditingController();
    _model.tFReferralNameFocusNode ??= FocusNode();

    _model.tFReferralPhoneTextController ??= TextEditingController();
    _model.tFReferralPhoneFocusNode ??= FocusNode();
    _model.tFReferralPhoneMask =
        MaskTextInputFormatter(mask: '(##) # ####.####');

    _model.tFReferralEmailTextController ??= TextEditingController();
    _model.tFReferralEmailFocusNode ??= FocusNode();

    _model.tFReferralValueTextController ??= TextEditingController();
    _model.tFReferralValueFocusNode ??= FocusNode();

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
      final nome = _model.tFNameTextController!.text.trim();
      final sobrenome = _model.tFLastNameTextController!.text.trim();
      // Lead pessoa física / captura de feira: sem empresa, `company_name`
      // recebe o nome do lead. A coluna é uma das que a busca das listagens
      // varre (ver `orIlike` em leads_widget) — deixá-la vazia tornaria o
      // lead inencontrável por lá.
      final empresa = _model.tFEmpresaTextController!.text.trim().isEmpty
          ? '$nome $sobrenome'.trim()
          : _model.tFEmpresaTextController!.text;

      // Desmarcado = null, e `leadReferralColumns` limpa o que houver. Não
      // basta ignorar: um lead que deixou de ser indicação com nome de
      // indicador pendurado viola o CHECK do banco.
      final referral = _model.isReferral
          ? ReferralInfo(
              name: _model.tFReferralNameTextController!.text.trim(),
              phone: _model.tFReferralPhoneTextController!.text.trim(),
              email: _model.tFReferralEmailTextController!.text.trim(),
              agreedValue: _model.referralAgreedValue,
            )
          : null;

      await widget.btnAction?.call(
        _model.tFNameTextController!.text,
        _model.tFLastNameTextController!.text,
        _model.tFCpfTextController!.text,
        empresa,
        _model.tFCargoTextController!.text,
        _model.tFEmailTextController!.text,
        _model.tFPhoneTextController!.text,
        _model.tFCityTextController!.text,
        _model.tFZipCodeTextController!.text,
        currentUserUid,
        referral,
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
                    helper: 'Em branco, usa o nome do lead.',
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
                    inputFormatters: [_model.tFZipCodeMask],
                    textInputAction: TextInputAction.done,
                    validator: (v) => _model.tFZipCodeTextControllerValidator
                        ?.call(context, v),
                  ),
                ),
              ],
            ),
            // A trigger `hardening_leads_referral_guard` (migration
            // 20260817121000) recusa INSERT com indicação de quem não é
            // master/documentação. Esconder a caixa aqui evita prometer um
            // campo que o save devolveria como 42501 — mesma regra do e-mail
            // somente-leitura na tela da oficina.
            if (_canEditReferral) ...[
            const SizedBox(height: 22),
            const _SectionLabel(
              icon: Icons.campaign_outlined,
              text: 'Indicação de venda',
            ),
            const SizedBox(height: 4),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() {
                _model.isReferral = !_model.isReferral;
                // Revalida na hora: desmarcar tem que apagar o vermelho do
                // "Nome de quem indicou" que ficou obrigatório enquanto
                // estava marcado.
                _model.formKey.currentState?.validate();
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Checkbox(
                      value: _model.isReferral,
                      onChanged: (v) => setState(() {
                        _model.isReferral = v ?? false;
                        _model.formKey.currentState?.validate();
                      }),
                      side: const BorderSide(
                          color: Color(0x66FFFFFF), width: 1.4),
                      activeColor: const Color(0xFFC2D51C),
                      checkColor: const Color(0xFF313131),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta venda veio de indicação de terceiro',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_model.isReferral) ...[
              const SizedBox(height: 12),
              AppFormField(
                controller: _model.tFReferralNameTextController,
                focusNode: _model.tFReferralNameFocusNode,
                label: 'Nome de quem indicou',
                placeholder: 'Ex.: João Pereira',
                icon: Icons.person_pin_circle_outlined,
                required: true,
                textInputAction: TextInputAction.next,
                validator: (v) => _model.tFReferralNameTextControllerValidator
                    ?.call(context, v),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppFormField(
                      controller: _model.tFReferralPhoneTextController,
                      focusNode: _model.tFReferralPhoneFocusNode,
                      label: 'Telefone',
                      placeholder: '(00) 9 0000.0000',
                      icon: Icons.phone_iphone_rounded,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_model.tFReferralPhoneMask],
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppFormField(
                      controller: _model.tFReferralEmailTextController,
                      focusNode: _model.tFReferralEmailFocusNode,
                      label: 'E-mail',
                      placeholder: 'nome@email.com',
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) => _model
                          .tFReferralEmailTextControllerValidator
                          ?.call(context, v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppFormField(
                controller: _model.tFReferralValueTextController,
                focusNode: _model.tFReferralValueFocusNode,
                label: 'Valor acordado (US\$)',
                placeholder: '0,00',
                icon: Icons.attach_money_rounded,
                helper:
                    'Quanto foi combinado com quem indicou. A comissão do vendedor nesta venda passa a ser US\$ 4.500,00.',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
              ),
            ],
            ],
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

