import '/flutter_flow/flutter_flow_util.dart';
import '/pages/shared/menu/menu_widget.dart';
import '/index.dart';
import 'guarantees_widget.dart' show GuaranteesWidget;
import 'package:flutter/material.dart';

class GuaranteesModel extends FlutterFlowModel<GuaranteesWidget> {
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
