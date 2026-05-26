import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/pages/shared/menu/menu_widget.dart';
import '/index.dart';
import 'available_aircrafts_widget.dart' show AvailableAircraftsWidget;
import 'dart:async';
import 'package:flutter/material.dart';

class AvailableAircraftsModel
    extends FlutterFlowModel<AvailableAircraftsWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for DPDEntryYear widget.
  String? dPDEntryYearValue;
  FormFieldController<String>? dPDEntryYearValueController;
  Completer<ApiCallResponse>? apiRequestCompleter;
  // State field(s) for DPDStatus widget.
  String? dPDStatusValue;
  FormFieldController<String>? dPDStatusValueController;
  // Stores action output result for [Backend Call - Delete Row(s)] action in Container widget.
  List<AvailableAircraftsRow>? deleteAircraftList;
  // Current user data for role checking.
  List<UsersRow>? user;
  // Model for menu component.
  late MenuModel menuModel;

  @override
  void initState(BuildContext context) {
    menuModel = createModel(context, () => MenuModel());
  }

  @override
  void dispose() {
    menuModel.dispose();
  }

  /// Additional helper methods.
  Future waitForApiRequestCompleted({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleter?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
