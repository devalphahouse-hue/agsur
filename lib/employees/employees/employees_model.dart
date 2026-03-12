import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/shared/alert_dialog/alert_dialog_widget.dart';
import '/pages/shared/custom_snac_bar/custom_snac_bar_widget.dart';
import '/pages/shared/empty_list/empty_list_widget.dart';
import '/pages/shared/menu/menu_widget.dart';
import '/pages/shared/modal_register_collab/modal_register_collab_widget.dart';
import '/pages/shared/switch_component/switch_component_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'dart:async';
import 'employees_widget.dart' show EmployeesWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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
