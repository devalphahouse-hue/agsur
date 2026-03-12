import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/shared/empty_list/empty_list_widget.dart';
import '/pages/shared/menu/menu_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'dart:async';
import 'registed_aircraft_widget.dart' show RegistedAircraftWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class RegistedAircraftModel extends FlutterFlowModel<RegistedAircraftWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TFSearchAircraft widget.
  FocusNode? tFSearchAircraftFocusNode;
  TextEditingController? tFSearchAircraftTextController;
  String? Function(BuildContext, String?)?
      tFSearchAircraftTextControllerValidator;
  Completer<List<AircraftsRow>>? requestCompleter;
  // Model for menu component.
  late MenuModel menuModel;

  @override
  void initState(BuildContext context) {
    menuModel = createModel(context, () => MenuModel());
  }

  @override
  void dispose() {
    tFSearchAircraftFocusNode?.dispose();
    tFSearchAircraftTextController?.dispose();

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
