import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ModalRegisterLeadModel
    extends FlutterFlowModel<StatefulWidget> {
  final formKey = GlobalKey<FormState>();

  // Nome
  FocusNode? tFNameFocusNode;
  TextEditingController? tFNameTextController;
  String? Function(BuildContext, String?)? tFNameTextControllerValidator;
  String? _tFNameTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) return 'Campo obrigatório';
    return null;
  }

  // Sobrenome
  FocusNode? tFLastNameFocusNode;
  TextEditingController? tFLastNameTextController;
  String? Function(BuildContext, String?)? tFLastNameTextControllerValidator;
  String? _tFLastNameTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  // CPF — opcional no cadastro (captura de feira): o vendedor precisa registrar
  // o contato em segundos e completa o cadastro depois, em `view_edit_lead`.
  // Continua validando o formato de quem for preenchido.
  FocusNode? tFCpfFocusNode;
  TextEditingController? tFCpfTextController;
  late MaskTextInputFormatter tFCpfMask;
  String? Function(BuildContext, String?)? tFCpfTextControllerValidator;
  String? _tFCpfTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 11) return 'CPF inválido';
    return null;
  }

  // Empresa — opcional. Lead pessoa física não tem empresa; quando fica em
  // branco o submit grava "Nome Sobrenome" (ver `_submit`), porque
  // `company_name` é uma das colunas da busca das listagens de lead.
  FocusNode? tFEmpresaFocusNode;
  TextEditingController? tFEmpresaTextController;
  String? Function(BuildContext, String?)? tFEmpresaTextControllerValidator;
  String? _tFEmpresaTextControllerValidator(
      BuildContext context, String? val) {
    return null;
  }

  // Cargo — opcional (completado depois).
  FocusNode? tFCargoFocusNode;
  TextEditingController? tFCargoTextController;
  String? Function(BuildContext, String?)? tFCargoTextControllerValidator;
  String? _tFCargoTextControllerValidator(BuildContext context, String? val) {
    return null;
  }

  // E-mail
  FocusNode? tFEmailFocusNode;
  TextEditingController? tFEmailTextController;
  String? Function(BuildContext, String?)? tFEmailTextControllerValidator;
  String? _tFEmailTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.trim().isEmpty) return 'Campo obrigatório';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(val.trim());
    if (!ok) return 'E-mail inválido';
    return null;
  }

  // Telefone
  FocusNode? tFPhoneFocusNode;
  TextEditingController? tFPhoneTextController;
  late MaskTextInputFormatter tFPhoneMask;
  String? Function(BuildContext, String?)? tFPhoneTextControllerValidator;
  String? _tFPhoneTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.trim().isEmpty) return 'Campo obrigatório';
    final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) return 'Telefone inválido';
    return null;
  }

  // CEP (integrado com ViaCEP)
  FocusNode? tFCepFocusNode;
  TextEditingController? tFCepTextController;
  late MaskTextInputFormatter tFCepMask;
  String? Function(BuildContext, String?)? tFCepTextControllerValidator;
  String? _tFCepTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 8) return 'CEP inválido';
    return null;
  }

  ApiCallResponse? cep;
  String? lastCepLookup;

  // Cidade
  FocusNode? tFCityFocusNode;
  TextEditingController? tFCityTextController;
  String? Function(BuildContext, String?)? tFCityTextControllerValidator;
  String? _tFCityTextControllerValidator(BuildContext context, String? val) {
    return null;
  }

  // UF (campo legado nomeado tFZipCode)
  FocusNode? tFZipCodeFocusNode;
  TextEditingController? tFZipCodeTextController;
  late MaskTextInputFormatter tFZipCodeMask;
  String? Function(BuildContext, String?)? tFZipCodeTextControllerValidator;
  String? _tFZipCodeTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.trim().isEmpty) return null;
    if (val.trim().length != 2) return 'UF';
    return null;
  }

  // ---------------------------------------------------------------------
  // Indicação de venda (17/08/2026)
  //
  // Marcar a caixa troca a comissão do vendedor de US$ 7.500 para US$ 4.500 na
  // conversão — ver `lib/backend/commission.dart`. Por isso os campos moram no
  // LEAD: precisam existir antes da proposta virar contrato.
  // ---------------------------------------------------------------------
  bool isReferral = false;

  FocusNode? tFReferralNameFocusNode;
  TextEditingController? tFReferralNameTextController;
  String? Function(BuildContext, String?)? tFReferralNameTextControllerValidator;
  String? _tFReferralNameTextControllerValidator(
      BuildContext context, String? val) {
    // Só cobra quando a caixa está marcada. Espelha o CHECK
    // `leads_referral_coerente`: indicação sem quem indicou não entra.
    if (!isReferral) return null;
    if (val == null || val.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  FocusNode? tFReferralPhoneFocusNode;
  TextEditingController? tFReferralPhoneTextController;
  late MaskTextInputFormatter tFReferralPhoneMask;

  FocusNode? tFReferralEmailFocusNode;
  TextEditingController? tFReferralEmailTextController;
  String? Function(BuildContext, String?)?
      tFReferralEmailTextControllerValidator;
  String? _tFReferralEmailTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(val.trim());
    if (!ok) return 'E-mail inválido';
    return null;
  }

  FocusNode? tFReferralValueFocusNode;
  TextEditingController? tFReferralValueTextController;

  /// Valor acordado digitado, em dólar. `null` quando vazio ou ilegível —
  /// nunca 0, para não confundir "não combinado" com "combinado zero".
  double? get referralAgreedValue {
    final raw = tFReferralValueTextController?.text.trim() ?? '';
    if (raw.isEmpty) return null;
    // Aceita "4.500,00" e "4500.00": tira separador de milhar e normaliza a
    // vírgula decimal do pt-BR.
    final normalizado =
        raw.replaceAll(RegExp(r'[^0-9,.]'), '').replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalizado);
  }

  bool? formRLead;

  @override
  void initState(BuildContext context) {
    tFReferralNameTextControllerValidator =
        _tFReferralNameTextControllerValidator;
    tFReferralEmailTextControllerValidator =
        _tFReferralEmailTextControllerValidator;
    tFNameTextControllerValidator = _tFNameTextControllerValidator;
    tFLastNameTextControllerValidator = _tFLastNameTextControllerValidator;
    tFCpfTextControllerValidator = _tFCpfTextControllerValidator;
    tFEmpresaTextControllerValidator = _tFEmpresaTextControllerValidator;
    tFCargoTextControllerValidator = _tFCargoTextControllerValidator;
    tFEmailTextControllerValidator = _tFEmailTextControllerValidator;
    tFPhoneTextControllerValidator = _tFPhoneTextControllerValidator;
    tFCepTextControllerValidator = _tFCepTextControllerValidator;
    tFCityTextControllerValidator = _tFCityTextControllerValidator;
    tFZipCodeTextControllerValidator = _tFZipCodeTextControllerValidator;
  }

  @override
  void dispose() {
    tFNameFocusNode?.dispose();
    tFNameTextController?.dispose();
    tFLastNameFocusNode?.dispose();
    tFLastNameTextController?.dispose();
    tFCpfFocusNode?.dispose();
    tFCpfTextController?.dispose();
    tFEmpresaFocusNode?.dispose();
    tFEmpresaTextController?.dispose();
    tFCargoFocusNode?.dispose();
    tFCargoTextController?.dispose();
    tFEmailFocusNode?.dispose();
    tFEmailTextController?.dispose();
    tFPhoneFocusNode?.dispose();
    tFPhoneTextController?.dispose();
    tFCityFocusNode?.dispose();
    tFCityTextController?.dispose();
    tFZipCodeFocusNode?.dispose();
    tFZipCodeTextController?.dispose();
    tFCepFocusNode?.dispose();
    tFCepTextController?.dispose();
    tFReferralNameFocusNode?.dispose();
    tFReferralNameTextController?.dispose();
    tFReferralPhoneFocusNode?.dispose();
    tFReferralPhoneTextController?.dispose();
    tFReferralEmailFocusNode?.dispose();
    tFReferralEmailTextController?.dispose();
    tFReferralValueFocusNode?.dispose();
    tFReferralValueTextController?.dispose();
  }
}
