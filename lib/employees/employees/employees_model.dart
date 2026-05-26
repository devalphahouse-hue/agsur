import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/shared/menu/menu_widget.dart';
import '/pages/shared/switch_component/switch_component_widget.dart';
import '/index.dart';
import 'dart:async';
import 'employees_widget.dart' show EmployeesWidget;
import 'package:flutter/material.dart';

class EmployeesModel extends FlutterFlowModel<EmployeesWidget> {
  ///  State fields for stateful widgets in this page.

  Completer<List<UsersRow>>? requestCompleter;
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
