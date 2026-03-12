import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'view_edit_seller_widget.dart' show ViewEditSellerWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

class ViewEditSellerModel extends FlutterFlowModel<ViewEditSellerWidget> {
  ///  Local state fields for this page.

  bool edit = false;

  ///  State fields for stateful widgets in this page.

  // State field(s) for TFNameSeller widget.
  FocusNode? tFNameSellerFocusNode;
  TextEditingController? tFNameSellerTextController;
  String? Function(BuildContext, String?)? tFNameSellerTextControllerValidator;
  // State field(s) for TFLastnameSeller widget.
  FocusNode? tFLastnameSellerFocusNode;
  TextEditingController? tFLastnameSellerTextController;
  String? Function(BuildContext, String?)?
      tFLastnameSellerTextControllerValidator;
  // State field(s) for TFCpfSeller widget.
  FocusNode? tFCpfSellerFocusNode;
  TextEditingController? tFCpfSellerTextController;
  late MaskTextInputFormatter tFCpfSellerMask;
  String? Function(BuildContext, String?)? tFCpfSellerTextControllerValidator;
  // State field(s) for TFPhoneSeller widget.
  FocusNode? tFPhoneSellerFocusNode;
  TextEditingController? tFPhoneSellerTextController;
  late MaskTextInputFormatter tFPhoneSellerMask;
  String? Function(BuildContext, String?)? tFPhoneSellerTextControllerValidator;
  // State field(s) for TFEmailSeller widget.
  FocusNode? tFEmailSellerFocusNode;
  TextEditingController? tFEmailSellerTextController;
  String? Function(BuildContext, String?)? tFEmailSellerTextControllerValidator;
  // Stores action output result for [Backend Call - Update Row(s)] action in BTNAddRegister widget.
  List<UsersRow>? updateSeller;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tFNameSellerFocusNode?.dispose();
    tFNameSellerTextController?.dispose();

    tFLastnameSellerFocusNode?.dispose();
    tFLastnameSellerTextController?.dispose();

    tFCpfSellerFocusNode?.dispose();
    tFCpfSellerTextController?.dispose();

    tFPhoneSellerFocusNode?.dispose();
    tFPhoneSellerTextController?.dispose();

    tFEmailSellerFocusNode?.dispose();
    tFEmailSellerTextController?.dispose();
  }
}
