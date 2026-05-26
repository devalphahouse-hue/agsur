import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/shared/menu/menu_widget.dart';
import '/pages/shared/switch_component/switch_component_widget.dart';
import '/index.dart';
import 'dart:async';
import 'pilots_widget.dart' show PilotsWidget;
import 'package:flutter/material.dart';

class PilotsModel extends FlutterFlowModel<PilotsWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TFSearchPilot widget.
  FocusNode? tFSearchPilotFocusNode;
  TextEditingController? tFSearchPilotTextController;
  String? Function(BuildContext, String?)? tFSearchPilotTextControllerValidator;
  Completer<List<VwGetPilotsRow>>? requestCompleter;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  UsersRow? createUserPilot;
  // Stores action output result for [Backend Call - API (Create account another user)] action in Button widget.
  ApiCallResponse? createAuthUserForColab;
  // Models for switch_component dynamic component.
  late FlutterFlowDynamicModels<SwitchComponentModel> switchComponentModels;
  // Model for menu component.
  late MenuModel menuModel;

  @override
  void initState(BuildContext context) {
    switchComponentModels =
        FlutterFlowDynamicModels(() => SwitchComponentModel());
    menuModel = createModel(context, () => MenuModel());
  }

  @override
  void dispose() {
    tFSearchPilotFocusNode?.dispose();
    tFSearchPilotTextController?.dispose();

    switchComponentModels.dispose();
    menuModel.dispose();
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
