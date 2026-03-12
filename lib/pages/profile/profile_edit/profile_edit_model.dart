import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/shared/menu/menu_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'profile_edit_widget.dart' show ProfileEditWidget;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

class ProfileEditModel extends FlutterFlowModel<ProfileEditWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for TFNome widget.
  FocusNode? tFNomeFocusNode;
  TextEditingController? tFNomeTextController;
  String? Function(BuildContext, String?)? tFNomeTextControllerValidator;
  String? _tFNomeTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFTelefone widget.
  FocusNode? tFTelefoneFocusNode;
  TextEditingController? tFTelefoneTextController;
  late MaskTextInputFormatter tFTelefoneMask;
  String? Function(BuildContext, String?)? tFTelefoneTextControllerValidator;
  String? _tFTelefoneTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // Model for menu component.
  late MenuModel menuModel;

  @override
  void initState(BuildContext context) {
    tFNomeTextControllerValidator = _tFNomeTextControllerValidator;
    tFTelefoneTextControllerValidator = _tFTelefoneTextControllerValidator;
    menuModel = createModel(context, () => MenuModel());
  }

  @override
  void dispose() {
    tFNomeFocusNode?.dispose();
    tFNomeTextController?.dispose();

    tFTelefoneFocusNode?.dispose();
    tFTelefoneTextController?.dispose();

    menuModel.dispose();
  }
}
