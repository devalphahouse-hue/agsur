import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/shared/menu/menu_widget.dart';
import '/index.dart';
import 'contracts_widget.dart' show ContractsWidget;
import 'package:flutter/material.dart';

class ContractsModel extends FlutterFlowModel<ContractsWidget> {
  ///  State fields for stateful widgets in this page.

  // Current user data for role checking.
  List<UsersRow>? user;
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
