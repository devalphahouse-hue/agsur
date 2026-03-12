import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'view_edit_employees_widget.dart' show ViewEditEmployeesWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

class ViewEditEmployeesModel extends FlutterFlowModel<ViewEditEmployeesWidget> {
  ///  Local state fields for this page.

  bool edit = false;

  ///  State fields for stateful widgets in this page.

  // State field(s) for TFName widget.
  FocusNode? tFNameFocusNode;
  TextEditingController? tFNameTextController;
  String? Function(BuildContext, String?)? tFNameTextControllerValidator;
  // State field(s) for TFLastName widget.
  FocusNode? tFLastNameFocusNode;
  TextEditingController? tFLastNameTextController;
  String? Function(BuildContext, String?)? tFLastNameTextControllerValidator;
  // State field(s) for TFCpf widget.
  FocusNode? tFCpfFocusNode;
  TextEditingController? tFCpfTextController;
  late MaskTextInputFormatter tFCpfMask;
  String? Function(BuildContext, String?)? tFCpfTextControllerValidator;
  // State field(s) for TFPhone widget.
  FocusNode? tFPhoneFocusNode;
  TextEditingController? tFPhoneTextController;
  late MaskTextInputFormatter tFPhoneMask;
  String? Function(BuildContext, String?)? tFPhoneTextControllerValidator;
  // State field(s) for TFEmail widget.
  FocusNode? tFEmailFocusNode;
  TextEditingController? tFEmailTextController;
  String? Function(BuildContext, String?)? tFEmailTextControllerValidator;
  // Stores action output result for [Backend Call - Update Row(s)] action in BTNAddRegister widget.
  List<UsersRow>? updateSeller;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tFNameFocusNode?.dispose();
    tFNameTextController?.dispose();

    tFLastNameFocusNode?.dispose();
    tFLastNameTextController?.dispose();

    tFCpfFocusNode?.dispose();
    tFCpfTextController?.dispose();

    tFPhoneFocusNode?.dispose();
    tFPhoneTextController?.dispose();

    tFEmailFocusNode?.dispose();
    tFEmailTextController?.dispose();
  }
}
