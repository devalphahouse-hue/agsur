import '/auth/supabase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import 'modal_register_lead_widget.dart' show ModalRegisterLeadWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

class ModalRegisterLeadModel extends FlutterFlowModel<ModalRegisterLeadWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // State field(s) for TFName widget.
  FocusNode? tFNameFocusNode;
  TextEditingController? tFNameTextController;
  String? Function(BuildContext, String?)? tFNameTextControllerValidator;
  String? _tFNameTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFLastName widget.
  FocusNode? tFLastNameFocusNode;
  TextEditingController? tFLastNameTextController;
  String? Function(BuildContext, String?)? tFLastNameTextControllerValidator;
  // State field(s) for TFCpf widget.
  FocusNode? tFCpfFocusNode;
  TextEditingController? tFCpfTextController;
  late MaskTextInputFormatter tFCpfMask;
  String? Function(BuildContext, String?)? tFCpfTextControllerValidator;
  String? _tFCpfTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFEmpresa widget.
  FocusNode? tFEmpresaFocusNode;
  TextEditingController? tFEmpresaTextController;
  String? Function(BuildContext, String?)? tFEmpresaTextControllerValidator;
  // State field(s) for TFCargo widget.
  FocusNode? tFCargoFocusNode;
  TextEditingController? tFCargoTextController;
  String? Function(BuildContext, String?)? tFCargoTextControllerValidator;
  // State field(s) for TFEmail widget.
  FocusNode? tFEmailFocusNode;
  TextEditingController? tFEmailTextController;
  String? Function(BuildContext, String?)? tFEmailTextControllerValidator;
  // State field(s) for TFPhone widget.
  FocusNode? tFPhoneFocusNode;
  TextEditingController? tFPhoneTextController;
  late MaskTextInputFormatter tFPhoneMask;
  String? Function(BuildContext, String?)? tFPhoneTextControllerValidator;
  // State field(s) for TFCity widget.
  FocusNode? tFCityFocusNode;
  TextEditingController? tFCityTextController;
  String? Function(BuildContext, String?)? tFCityTextControllerValidator;
  // State field(s) for TFZipCode widget.
  FocusNode? tFZipCodeFocusNode;
  TextEditingController? tFZipCodeTextController;
  late MaskTextInputFormatter tFZipCodeMask;
  String? Function(BuildContext, String?)? tFZipCodeTextControllerValidator;
  // Stores action output result for [Validate Form] action in BTNRegisterLead widget.
  bool? formRLead;

  @override
  void initState(BuildContext context) {
    tFNameTextControllerValidator = _tFNameTextControllerValidator;
    tFCpfTextControllerValidator = _tFCpfTextControllerValidator;
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
  }
}
