import '/flutter_flow/flutter_flow_util.dart';
import '/pages/shared/menu/menu_widget.dart';
import '/index.dart';
import 'view_edit_rates_widget.dart' show ViewEditRatesWidget;
import 'package:flutter/material.dart';

class ViewEditRatesModel extends FlutterFlowModel<ViewEditRatesWidget> {
  ///  Local state fields for this page.

  bool edit = false;

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
