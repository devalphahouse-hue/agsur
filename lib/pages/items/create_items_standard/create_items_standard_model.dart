import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'create_items_standard_widget.dart' show CreateItemsStandardWidget;
import 'package:flutter/material.dart';

class CreateItemsStandardModel
    extends FlutterFlowModel<CreateItemsStandardWidget> {
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
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  AircraftItemsRow? createItemSeries;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tFAircraftNameFocusNode?.dispose();
    tFAircraftNameTextController?.dispose();

    tFQtyItemFocusNode?.dispose();
    tFQtyItemTextController?.dispose();
  }
}
