import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import 'register_oficina_widget.dart' show RegisterOficinaWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

class RegisterOficinaModel extends FlutterFlowModel<RegisterOficinaWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
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

  // State field(s) for TFEditCpf widget.
  FocusNode? tFEditCpfFocusNode;
  TextEditingController? tFEditCpfTextController;
  late MaskTextInputFormatter tFEditCpfMask;
  String? Function(BuildContext, String?)? tFEditCpfTextControllerValidator;
  String? _tFEditCpfTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFEditEmail widget.
  FocusNode? tFEditEmailFocusNode;
  TextEditingController? tFEditEmailTextController;
  String? Function(BuildContext, String?)? tFEditEmailTextControllerValidator;
  // State field(s) for TFEditPhone widget.
  FocusNode? tFEditPhoneFocusNode;
  TextEditingController? tFEditPhoneTextController;
  late MaskTextInputFormatter tFEditPhoneMask;
  String? Function(BuildContext, String?)? tFEditPhoneTextControllerValidator;
  // State field(s) for TFEditCity widget.
  FocusNode? tFEditCityFocusNode;
  TextEditingController? tFEditCityTextController;
  String? Function(BuildContext, String?)? tFEditCityTextControllerValidator;
  // State field(s) for TFEditZipCode widget.
  FocusNode? tFEditZipCodeFocusNode;
  TextEditingController? tFEditZipCodeTextController;
  late MaskTextInputFormatter tFEditZipCodeMask;
  String? Function(BuildContext, String?)? tFEditZipCodeTextControllerValidator;

  @override
  void initState(BuildContext context) {
    tFEditNameTextControllerValidator = _tFEditNameTextControllerValidator;
    tFEditCpfTextControllerValidator = _tFEditCpfTextControllerValidator;
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
  }
}
