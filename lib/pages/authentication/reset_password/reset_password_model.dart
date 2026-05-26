import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'reset_password_widget.dart' show ResetPasswordWidget;
import 'package:flutter/material.dart';

class ResetPasswordModel extends FlutterFlowModel<ResetPasswordWidget> {
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

  @override
  void initState(BuildContext context) {
    tFEmailTextControllerValidator = _tFEmailTextControllerValidator;
  }

  @override
  void dispose() {
    tFEmailFocusNode?.dispose();
    tFEmailTextController?.dispose();
  }
}
