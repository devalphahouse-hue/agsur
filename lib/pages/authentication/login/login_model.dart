import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/shared/custom_snac_bar/custom_snac_bar_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'login_widget.dart' show LoginWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LoginModel extends FlutterFlowModel<LoginWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for TFEmail widget.
  FocusNode? tFEmailFocusNode;
  TextEditingController? tFEmailTextController;
  String? Function(BuildContext, String?)? tFEmailTextControllerValidator;
  String? _tFEmailTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório.';
    }

    if (!RegExp(kTextValidatorEmailRegex).hasMatch(val)) {
      return 'Has to be a valid email address.';
    }
    return null;
  }

  // State field(s) for TFSenha widget.
  FocusNode? tFSenhaFocusNode;
  TextEditingController? tFSenhaTextController;
  late bool tFSenhaVisibility;
  String? Function(BuildContext, String?)? tFSenhaTextControllerValidator;
  String? _tFSenhaTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório.';
    }

    return null;
  }

  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<UsersRow>? userResponse;

  @override
  void initState(BuildContext context) {
    tFEmailTextControllerValidator = _tFEmailTextControllerValidator;
    tFSenhaVisibility = false;
    tFSenhaTextControllerValidator = _tFSenhaTextControllerValidator;
  }

  @override
  void dispose() {
    tFEmailFocusNode?.dispose();
    tFEmailTextController?.dispose();

    tFSenhaFocusNode?.dispose();
    tFSenhaTextController?.dispose();
  }
}
