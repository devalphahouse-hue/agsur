import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/shared/alert_dialog/alert_dialog_widget.dart';
import '/pages/shared/custom_snac_bar/custom_snac_bar_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'oficina_details_widget.dart' show OficinaDetailsWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

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
  String? Function(BuildContext, String?)?
      tFPhoneOficinaTextControllerValidator;
  // State field(s) for TFEmailOficina widget.
  FocusNode? tFEmailOficinaFocusNode;
  TextEditingController? tFEmailOficinaTextController;
  String? Function(BuildContext, String?)?
      tFEmailOficinaTextControllerValidator;

  @override
  void initState(BuildContext context) {}

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
  }
}
