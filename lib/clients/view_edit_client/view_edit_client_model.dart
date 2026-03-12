import '/auth/supabase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/shared/empty_list/empty_list_widget.dart';
import '/pages/shared/modal_register_note/modal_register_note_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'dart:async';
import 'view_edit_client_widget.dart' show ViewEditClientWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

class ViewEditClientModel extends FlutterFlowModel<ViewEditClientWidget> {
  ///  Local state fields for this page.

  bool edit = false;

  ///  State fields for stateful widgets in this page.

  // State field(s) for TFNameLead widget.
  FocusNode? tFNameLeadFocusNode;
  TextEditingController? tFNameLeadTextController;
  String? Function(BuildContext, String?)? tFNameLeadTextControllerValidator;
  // State field(s) for TFLastnameLead widget.
  FocusNode? tFLastnameLeadFocusNode;
  TextEditingController? tFLastnameLeadTextController;
  String? Function(BuildContext, String?)?
      tFLastnameLeadTextControllerValidator;
  // State field(s) for TFCpfLead widget.
  FocusNode? tFCpfLeadFocusNode;
  TextEditingController? tFCpfLeadTextController;
  late MaskTextInputFormatter tFCpfLeadMask;
  String? Function(BuildContext, String?)? tFCpfLeadTextControllerValidator;
  // State field(s) for TFEmailLead widget.
  FocusNode? tFEmailLeadFocusNode;
  TextEditingController? tFEmailLeadTextController;
  String? Function(BuildContext, String?)? tFEmailLeadTextControllerValidator;
  // State field(s) for TFEmpresaLead widget.
  FocusNode? tFEmpresaLeadFocusNode;
  TextEditingController? tFEmpresaLeadTextController;
  String? Function(BuildContext, String?)? tFEmpresaLeadTextControllerValidator;
  // State field(s) for TFPhoneLead widget.
  FocusNode? tFPhoneLeadFocusNode;
  TextEditingController? tFPhoneLeadTextController;
  late MaskTextInputFormatter tFPhoneLeadMask;
  String? Function(BuildContext, String?)? tFPhoneLeadTextControllerValidator;
  // State field(s) for TFCargoLead widget.
  FocusNode? tFCargoLeadFocusNode;
  TextEditingController? tFCargoLeadTextController;
  String? Function(BuildContext, String?)? tFCargoLeadTextControllerValidator;
  // State field(s) for TFCityLead widget.
  FocusNode? tFCityLeadFocusNode;
  TextEditingController? tFCityLeadTextController;
  String? Function(BuildContext, String?)? tFCityLeadTextControllerValidator;
  // State field(s) for TFUfLead widget.
  FocusNode? tFUfLeadFocusNode;
  TextEditingController? tFUfLeadTextController;
  String? Function(BuildContext, String?)? tFUfLeadTextControllerValidator;
  // Stores action output result for [Backend Call - Update Row(s)] action in BTNAddRegister widget.
  List<LeadsRow>? updateLead;
  // Stores action output result for [Backend Call - Update Row(s)] action in BTNAddRegister widget.
  List<UsersRow>? updatePhoneUser;
  Completer<List<VwNotesDetailsRow>>? requestCompleter;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tFNameLeadFocusNode?.dispose();
    tFNameLeadTextController?.dispose();

    tFLastnameLeadFocusNode?.dispose();
    tFLastnameLeadTextController?.dispose();

    tFCpfLeadFocusNode?.dispose();
    tFCpfLeadTextController?.dispose();

    tFEmailLeadFocusNode?.dispose();
    tFEmailLeadTextController?.dispose();

    tFEmpresaLeadFocusNode?.dispose();
    tFEmpresaLeadTextController?.dispose();

    tFPhoneLeadFocusNode?.dispose();
    tFPhoneLeadTextController?.dispose();

    tFCargoLeadFocusNode?.dispose();
    tFCargoLeadTextController?.dispose();

    tFCityLeadFocusNode?.dispose();
    tFCityLeadTextController?.dispose();

    tFUfLeadFocusNode?.dispose();
    tFUfLeadTextController?.dispose();
  }

  /// Additional helper methods.
  Future waitForRequestCompleted({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = requestCompleter?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
