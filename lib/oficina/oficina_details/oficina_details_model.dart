import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'oficina_details_widget.dart' show OficinaDetailsWidget;
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class OficinaDetailsModel extends FlutterFlowModel<OficinaDetailsWidget> {
  ///  Local state fields for this page.

  bool edit = false;

  ///  State fields for stateful widgets in this page.

  // State field(s) for TFFullnameOficina widget.
  FocusNode? tFFullnameOficinaFocusNode;
  TextEditingController? tFFullnameOficinaTextController;
  String? Function(BuildContext, String?)?
      tFFullnameOficinaTextControllerValidator;
  // State field(s) for TFCnpjOficina widget.
  FocusNode? tFCnpjOficinaFocusNode;
  TextEditingController? tFCnpjOficinaTextController;
  late MaskTextInputFormatter tFCnpjOficinaMask;
  String? Function(BuildContext, String?)? tFCnpjOficinaTextControllerValidator;
  // State field(s) for TFPhoneOficina widget.
  FocusNode? tFPhoneOficinaFocusNode;
  TextEditingController? tFPhoneOficinaTextController;
  late MaskTextInputFormatter tFPhoneOficinaMask;
  String? Function(BuildContext, String?)?
      tFPhoneOficinaTextControllerValidator;
  // State field(s) for TFEmailOficina widget.
  FocusNode? tFEmailOficinaFocusNode;
  TextEditingController? tFEmailOficinaTextController;
  String? Function(BuildContext, String?)?
      tFEmailOficinaTextControllerValidator;

  // State field(s) for TFCity widget.
  FocusNode? tFCityFocusNode;
  TextEditingController? tFCityTextController;
  String? Function(BuildContext, String?)? tFCityTextControllerValidator;
  String? _tFCityTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Campo obrigatório';
    }
    return null;
  }

  // State field(s) for TFUf widget.
  FocusNode? tFUfFocusNode;
  TextEditingController? tFUfTextController;
  late MaskTextInputFormatter tFUfMask;
  String? Function(BuildContext, String?)? tFUfTextControllerValidator;
  String? _tFUfTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Obrigatório';
    }
    if (val.trim().length != 2) return 'UF';
    return null;
  }

  // State field(s) for TFCep widget. (CEP real, integrado com ViaCEP.)
  FocusNode? tFCepFocusNode;
  TextEditingController? tFCepTextController;
  late MaskTextInputFormatter tFCepMask;
  String? Function(BuildContext, String?)? tFCepTextControllerValidator;
  String? _tFCepTextControllerValidator(BuildContext context, String? val) {
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

  @override
  void initState(BuildContext context) {
    tFCityTextControllerValidator = _tFCityTextControllerValidator;
    tFUfTextControllerValidator = _tFUfTextControllerValidator;
    tFCepTextControllerValidator = _tFCepTextControllerValidator;
  }

  @override
  void dispose() {
    tFFullnameOficinaFocusNode?.dispose();
    tFFullnameOficinaTextController?.dispose();

    tFCnpjOficinaFocusNode?.dispose();
    tFCnpjOficinaTextController?.dispose();

    tFPhoneOficinaFocusNode?.dispose();
    tFPhoneOficinaTextController?.dispose();

    tFEmailOficinaFocusNode?.dispose();
    tFEmailOficinaTextController?.dispose();

    tFCityFocusNode?.dispose();
    tFCityTextController?.dispose();

    tFUfFocusNode?.dispose();
    tFUfTextController?.dispose();

    tFCepFocusNode?.dispose();
    tFCepTextController?.dispose();
  }
}
