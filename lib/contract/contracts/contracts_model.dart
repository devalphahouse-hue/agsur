import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/shared/empty_list/empty_list_widget.dart';
import '/pages/shared/menu/menu_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'contracts_widget.dart' show ContractsWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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
