import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import 'modal_edit_address_widget.dart' show ModalEditAddressWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

class ModalEditAddressModel extends FlutterFlowModel<ModalEditAddressWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // State field(s) for TFZipCode widget.
  FocusNode? tFZipCodeFocusNode;
  TextEditingController? tFZipCodeTextController;
  late MaskTextInputFormatter tFZipCodeMask;
  String? Function(BuildContext, String?)? tFZipCodeTextControllerValidator;
  String? _tFZipCodeTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // Stores action output result for [Backend Call - API (via cep)] action in Button widget.
  ApiCallResponse? cep;
  // State field(s) for TFStreet widget.
  FocusNode? tFStreetFocusNode;
  TextEditingController? tFStreetTextController;
  String? Function(BuildContext, String?)? tFStreetTextControllerValidator;
  String? _tFStreetTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFNumber widget.
  FocusNode? tFNumberFocusNode;
  TextEditingController? tFNumberTextController;
  String? Function(BuildContext, String?)? tFNumberTextControllerValidator;
  // State field(s) for TFNeibh widget.
  FocusNode? tFNeibhFocusNode;
  TextEditingController? tFNeibhTextController;
  String? Function(BuildContext, String?)? tFNeibhTextControllerValidator;
  String? _tFNeibhTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFCity widget.
  FocusNode? tFCityFocusNode;
  TextEditingController? tFCityTextController;
  String? Function(BuildContext, String?)? tFCityTextControllerValidator;
  String? _tFCityTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFuf widget.
  FocusNode? tFufFocusNode;
  TextEditingController? tFufTextController;
  String? Function(BuildContext, String?)? tFufTextControllerValidator;
  String? _tFufTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFComplement widget.
  FocusNode? tFComplementFocusNode;
  TextEditingController? tFComplementTextController;
  String? Function(BuildContext, String?)? tFComplementTextControllerValidator;
  // Stores action output result for [Validate Form] action in BTNRegisterLead widget.
  bool? formAddress;

  @override
  void initState(BuildContext context) {
    tFZipCodeTextControllerValidator = _tFZipCodeTextControllerValidator;
    tFStreetTextControllerValidator = _tFStreetTextControllerValidator;
    tFNeibhTextControllerValidator = _tFNeibhTextControllerValidator;
    tFCityTextControllerValidator = _tFCityTextControllerValidator;
    tFufTextControllerValidator = _tFufTextControllerValidator;
  }

  @override
  void dispose() {
    tFZipCodeFocusNode?.dispose();
    tFZipCodeTextController?.dispose();

    tFStreetFocusNode?.dispose();
    tFStreetTextController?.dispose();

    tFNumberFocusNode?.dispose();
    tFNumberTextController?.dispose();

    tFNeibhFocusNode?.dispose();
    tFNeibhTextController?.dispose();

    tFCityFocusNode?.dispose();
    tFCityTextController?.dispose();

    tFufFocusNode?.dispose();
    tFufTextController?.dispose();

    tFComplementFocusNode?.dispose();
    tFComplementTextController?.dispose();
  }
}
