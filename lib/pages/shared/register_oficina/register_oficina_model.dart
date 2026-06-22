import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'register_oficina_widget.dart' show RegisterOficinaWidget;
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class RegisterOficinaModel extends FlutterFlowModel<RegisterOficinaWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // IDs dos clientes vinculados à oficina (multi-select).
  Set<String> selectedClientIds = <String>{};
  // State field(s) for TFEditName widget.
  FocusNode? tFEditNameFocusNode;
  TextEditingController? tFEditNameTextController;
  String? Function(BuildContext, String?)? tFEditNameTextControllerValidator;
  String? _tFEditNameTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFEditCpf widget. (CNPJ)
  FocusNode? tFEditCpfFocusNode;
  TextEditingController? tFEditCpfTextController;
  late MaskTextInputFormatter tFEditCpfMask;
  String? Function(BuildContext, String?)? tFEditCpfTextControllerValidator;
  String? _tFEditCpfTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }
    final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 14) {
      return 'CNPJ inválido';
    }
    return null;
  }

  // State field(s) for TFEditEmail widget.
  FocusNode? tFEditEmailFocusNode;
  TextEditingController? tFEditEmailTextController;
  String? Function(BuildContext, String?)? tFEditEmailTextControllerValidator;
  String? _tFEditEmailTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(val.trim());
    if (!ok) return 'E-mail inválido';
    return null;
  }

  // State field(s) for TFEditPhone widget.
  FocusNode? tFEditPhoneFocusNode;
  TextEditingController? tFEditPhoneTextController;
  late MaskTextInputFormatter tFEditPhoneMask;
  String? Function(BuildContext, String?)? tFEditPhoneTextControllerValidator;
  String? _tFEditPhoneTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }
    final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) return 'Telefone inválido';
    return null;
  }

  // State field(s) for TFEditCity widget.
  FocusNode? tFEditCityFocusNode;
  TextEditingController? tFEditCityTextController;
  String? Function(BuildContext, String?)? tFEditCityTextControllerValidator;
  String? _tFEditCityTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Campo obrigatório';
    }
    return null;
  }

  // State field(s) for TFEditZipCode widget. (UF — mantido o nome legado)
  FocusNode? tFEditZipCodeFocusNode;
  TextEditingController? tFEditZipCodeTextController;
  late MaskTextInputFormatter tFEditZipCodeMask;
  String? Function(BuildContext, String?)? tFEditZipCodeTextControllerValidator;
  String? _tFEditZipCodeTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Obrigatório';
    }
    if (val.trim().length != 2) return 'UF';
    return null;
  }

  // State field(s) for TFEditCep widget. (CEP real, integrado com ViaCEP.)
  FocusNode? tFEditCepFocusNode;
  TextEditingController? tFEditCepTextController;
  late MaskTextInputFormatter tFEditCepMask;
  String? Function(BuildContext, String?)? tFEditCepTextControllerValidator;
  String? _tFEditCepTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }
    final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 8) {
      return 'CEP inválido';
    }
    return null;
  }

  /// Última resposta do ViaCEP — usada pelo widget para preencher cidade/UF.
  ApiCallResponse? cep;
  /// Para evitar disparar ViaCEP repetidamente para o mesmo CEP.
  String? lastCepLookup;

  // State field(s) for TFEditPassword widget.
  FocusNode? tFEditPasswordFocusNode;
  TextEditingController? tFEditPasswordTextController;
  late bool tFEditPasswordVisibility;
  String? Function(BuildContext, String?)? tFEditPasswordTextControllerValidator;
  String? _tFEditPasswordTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }
    if (val.length < 8) return 'Mínimo 8 caracteres';
    return null;
  }

  @override
  void initState(BuildContext context) {
    tFEditNameTextControllerValidator = _tFEditNameTextControllerValidator;
    tFEditCpfTextControllerValidator = _tFEditCpfTextControllerValidator;
    tFEditEmailTextControllerValidator = _tFEditEmailTextControllerValidator;
    tFEditPhoneTextControllerValidator = _tFEditPhoneTextControllerValidator;
    tFEditCityTextControllerValidator = _tFEditCityTextControllerValidator;
    tFEditZipCodeTextControllerValidator =
        _tFEditZipCodeTextControllerValidator;
    tFEditCepTextControllerValidator = _tFEditCepTextControllerValidator;
    tFEditPasswordTextControllerValidator =
        _tFEditPasswordTextControllerValidator;
    tFEditPasswordVisibility = false;
  }

  @override
  void dispose() {
    tFEditNameFocusNode?.dispose();
    tFEditNameTextController?.dispose();

    tFEditCpfFocusNode?.dispose();
    tFEditCpfTextController?.dispose();

    tFEditEmailFocusNode?.dispose();
    tFEditEmailTextController?.dispose();

    tFEditPhoneFocusNode?.dispose();
    tFEditPhoneTextController?.dispose();

    tFEditCityFocusNode?.dispose();
    tFEditCityTextController?.dispose();

    tFEditZipCodeFocusNode?.dispose();
    tFEditZipCodeTextController?.dispose();

    tFEditCepFocusNode?.dispose();
    tFEditCepTextController?.dispose();

    tFEditPasswordFocusNode?.dispose();
    tFEditPasswordTextController?.dispose();
  }
}
