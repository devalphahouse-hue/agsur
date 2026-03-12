import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import 'modal_register_company_widget.dart' show ModalRegisterCompanyWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

class ModalRegisterCompanyModel
    extends FlutterFlowModel<ModalRegisterCompanyWidget> {
  ///  Local state fields for this component.

  int docType = 1;

  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // State field(s) for TFCompanyName widget.
  FocusNode? tFCompanyNameFocusNode;
  TextEditingController? tFCompanyNameTextController;
  String? Function(BuildContext, String?)? tFCompanyNameTextControllerValidator;
  String? _tFCompanyNameTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFPhoneCompany widget.
  FocusNode? tFPhoneCompanyFocusNode;
  TextEditingController? tFPhoneCompanyTextController;
  late MaskTextInputFormatter tFPhoneCompanyMask;
  String? Function(BuildContext, String?)?
      tFPhoneCompanyTextControllerValidator;
  String? _tFPhoneCompanyTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFCnpjCompany widget.
  FocusNode? tFCnpjCompanyFocusNode;
  TextEditingController? tFCnpjCompanyTextController;
  late MaskTextInputFormatter tFCnpjCompanyMask;
  String? Function(BuildContext, String?)? tFCnpjCompanyTextControllerValidator;
  String? _tFCnpjCompanyTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFCpfCompany widget.
  FocusNode? tFCpfCompanyFocusNode;
  TextEditingController? tFCpfCompanyTextController;
  late MaskTextInputFormatter tFCpfCompanyMask;
  String? Function(BuildContext, String?)? tFCpfCompanyTextControllerValidator;
  // State field(s) for TFIncricCompany widget.
  FocusNode? tFIncricCompanyFocusNode;
  TextEditingController? tFIncricCompanyTextController;
  String? Function(BuildContext, String?)?
      tFIncricCompanyTextControllerValidator;
  // Stores action output result for [Validate Form] action in BTNRegisterLead widget.
  bool? formCollab;

  @override
  void initState(BuildContext context) {
    tFCompanyNameTextControllerValidator =
        _tFCompanyNameTextControllerValidator;
    tFPhoneCompanyTextControllerValidator =
        _tFPhoneCompanyTextControllerValidator;
    tFCnpjCompanyTextControllerValidator =
        _tFCnpjCompanyTextControllerValidator;
  }

  @override
  void dispose() {
    tFCompanyNameFocusNode?.dispose();
    tFCompanyNameTextController?.dispose();

    tFPhoneCompanyFocusNode?.dispose();
    tFPhoneCompanyTextController?.dispose();

    tFCnpjCompanyFocusNode?.dispose();
    tFCnpjCompanyTextController?.dispose();

    tFCpfCompanyFocusNode?.dispose();
    tFCpfCompanyTextController?.dispose();

    tFIncricCompanyFocusNode?.dispose();
    tFIncricCompanyTextController?.dispose();
  }
}
