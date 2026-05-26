import '/flutter_flow/flutter_flow_util.dart';
import '/pages/shared/menu/menu_widget.dart';
import '/index.dart';
import 'part_quote_widget.dart' show PartQuoteWidget;
import 'package:flutter/material.dart';

class PartQuoteModel extends FlutterFlowModel<PartQuoteWidget> {
  ///  State fields for stateful widgets in this page.

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
}
