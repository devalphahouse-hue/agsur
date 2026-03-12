import '/auth/supabase_auth/auth_util.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/index.dart';
import 'create_items_standard_widget.dart' show CreateItemsStandardWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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
