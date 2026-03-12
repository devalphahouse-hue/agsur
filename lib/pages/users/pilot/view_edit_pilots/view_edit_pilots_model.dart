import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/shared/alert_dialog/alert_dialog_widget.dart';
import '/pages/shared/custom_snac_bar/custom_snac_bar_widget.dart';
import '/pages/shared/empty_list/empty_list_widget.dart';
import '/pages/shared/modal_certificate_pilot/modal_certificate_pilot_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'dart:async';
import 'view_edit_pilots_widget.dart' show ViewEditPilotsWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ViewEditPilotsModel extends FlutterFlowModel<ViewEditPilotsWidget> {
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
  // State field(s) for TFEmailPilot widget.
  FocusNode? tFEmailPilotFocusNode;
  TextEditingController? tFEmailPilotTextController;
  String? Function(BuildContext, String?)? tFEmailPilotTextControllerValidator;
  // State field(s) for TFPhonePilot widget.
  FocusNode? tFPhonePilotFocusNode;
  TextEditingController? tFPhonePilotTextController;
  String? Function(BuildContext, String?)? tFPhonePilotTextControllerValidator;
  // Stores action output result for [Backend Call - Update Row(s)] action in BTNAddRegister widget.
  List<UsersRow>? updatePilot;
  Completer<List<PilotCertificatesViewRow>>? requestCompleter;
  // Stores action output result for [Backend Call - Insert Row] action in BTNUpdateLead widget.
  PilotCertificatesRow? insertPilotCertificate;
  // Stores action output result for [Backend Call - Update Row(s)] action in Container widget.
  List<PilotCertificatesRow>? deletePilotCertificate;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tFNameFocusNode?.dispose();
    tFNameTextController?.dispose();

    tFLastNameFocusNode?.dispose();
    tFLastNameTextController?.dispose();

    tFEmailPilotFocusNode?.dispose();
    tFEmailPilotTextController?.dispose();

    tFPhonePilotFocusNode?.dispose();
    tFPhonePilotTextController?.dispose();
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
