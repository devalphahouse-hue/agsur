import '/auth/supabase_auth/auth_util.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/pages/shared/empty_all_lists/empty_all_lists_widget.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'create_items_options_widget.dart' show CreateItemsOptionsWidget;
import 'dart:async';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CreateItemsOptionsModel
    extends FlutterFlowModel<CreateItemsOptionsWidget> {
  ///  Local state fields for this page.

  int section = 0;

  ///  State fields for stateful widgets in this page.

  // State field(s) for DPDCategory widget.
  String? dPDCategoryValue;
  FormFieldController<String>? dPDCategoryValueController;
  // State field(s) for TFAircraftName widget.
  FocusNode? tFAircraftNameFocusNode;
  TextEditingController? tFAircraftNameTextController;
  String? Function(BuildContext, String?)?
      tFAircraftNameTextControllerValidator;
  // State field(s) for TFQtyItem widget.
  FocusNode? tFQtyItemFocusNode;
  TextEditingController? tFQtyItemTextController;
  String? Function(BuildContext, String?)? tFQtyItemTextControllerValidator;
  // State field(s) for TFPrice widget.
  FocusNode? tFPriceFocusNode;
  TextEditingController? tFPriceTextController;
  String? Function(BuildContext, String?)? tFPriceTextControllerValidator;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  AircraftItemsRow? createOptionalItem;
  Completer<List<AircraftItemsRow>>? requestCompleter;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tFAircraftNameFocusNode?.dispose();
    tFAircraftNameTextController?.dispose();

    tFQtyItemFocusNode?.dispose();
    tFQtyItemTextController?.dispose();

    tFPriceFocusNode?.dispose();
    tFPriceTextController?.dispose();
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
