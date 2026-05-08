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

  // CPF
  FocusNode? tFCpfFocusNode;
  TextEditingController? tFCpfTextController;
  late MaskTextInputFormatter tFCpfMask;
  String? Function(BuildContext, String?)? tFCpfTextControllerValidator;
  String? _tFCpfTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) return 'Campo obrigatório';
    final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 11) return 'CPF inválido';
    return null;
  }

  // Empresa
  FocusNode? tFEmpresaFocusNode;
  TextEditingController? tFEmpresaTextController;
  String? Function(BuildContext, String?)? tFEmpresaTextControllerValidator;
  String? _tFEmpresaTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  // Cargo
  FocusNode? tFCargoFocusNode;
  TextEditingController? tFCargoTextController;
  String? Function(BuildContext, String?)? tFCargoTextControllerValidator;
  String? _tFCargoTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.trim().isEmpty) return 'Campo obrigatório';
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
    if (val == null || val.isEmpty) return 'Campo obrigatório';
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
    if (val == null || val.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  // UF (campo legado nomeado tFZipCode)
  FocusNode? tFZipCodeFocusNode;
  TextEditingController? tFZipCodeTextController;
  late MaskTextInputFormatter tFZipCodeMask;
  String? Function(BuildContext, String?)? tFZipCodeTextControllerValidator;
  String? _tFZipCodeTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.trim().isEmpty) return 'Obrigatório';
    if (val.trim().length != 2) return 'UF';
    return null;
  }

  bool? formRLead;

  @override
  void initState(BuildContext context) {
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
  }
}
