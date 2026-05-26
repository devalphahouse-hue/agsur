import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'create_category_widget.dart' show CreateCategoryWidget;
import 'dart:async';
import 'package:flutter/material.dart';

class CreateCategoryModel extends FlutterFlowModel<CreateCategoryWidget> {
  ///  Local state fields for this page.

  int section = 0;

  ///  State fields for stateful widgets in this page.

  // State field(s) for DpdTypeItem widget.
  String? dpdTypeItemValue;
  FormFieldController<String>? dpdTypeItemValueController;
  // State field(s) for TFCategoryName widget.
  FocusNode? tFCategoryNameFocusNode;
  TextEditingController? tFCategoryNameTextController;
  String? Function(BuildContext, String?)?
      tFCategoryNameTextControllerValidator;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  CategoryRow? createCategory;
  Completer<List<CategoryRow>>? requestCompleter;
  // Stores action output result for [Backend Call - Delete Row(s)] action in Icon widget.
  List<CategoryRow>? deletedCategory;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tFCategoryNameFocusNode?.dispose();
    tFCategoryNameTextController?.dispose();
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
