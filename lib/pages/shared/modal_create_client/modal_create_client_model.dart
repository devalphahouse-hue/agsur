import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'modal_create_client_widget.dart' show ModalCreateClientWidget;
import 'package:flutter/material.dart';

class ModalCreateClientModel extends FlutterFlowModel<ModalCreateClientWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // Stores action output result for [Backend Call - Query Rows] action in DropDown widget.
  List<LeadsRow>? leadss;
  // State field(s) for TFEmailUser widget.
  FocusNode? tFEmailUserFocusNode;
  TextEditingController? tFEmailUserTextController;
  String? Function(BuildContext, String?)? tFEmailUserTextControllerValidator;
  String? _tFEmailUserTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFPasswordUser widget.
  FocusNode? tFPasswordUserFocusNode;
  TextEditingController? tFPasswordUserTextController;
  late bool tFPasswordUserVisibility;
  String? Function(BuildContext, String?)?
      tFPasswordUserTextControllerValidator;
  String? _tFPasswordUserTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    if (val.length < 8) {
      return 'A senha deve ter o mínimo de 8 caracteres';
    }

    return null;
  }

  // Stores action output result for [Validate Form] action in BTNRegisterCertificate widget.
  bool? formRegister;
  // Stores action output result for [Backend Call - Query Rows] action in BTNRegisterCertificate widget.
  List<LeadsRow>? getLeadData;
  // Stores action output result for [Backend Call - API (Create account another user)] action in BTNRegisterCertificate widget.
  ApiCallResponse? authUserResponse;
  // Stores action output result for [Backend Call - Insert Row] action in BTNRegisterCertificate widget.
  UsersRow? insertUser;
  // Stores action output result for [Backend Call - Insert Row] action in BTNRegisterCertificate widget.
  TrackingRow? tracking;

  @override
  void initState(BuildContext context) {
    tFEmailUserTextControllerValidator = _tFEmailUserTextControllerValidator;
    tFPasswordUserVisibility = false;
    tFPasswordUserTextControllerValidator =
        _tFPasswordUserTextControllerValidator;
  }

  @override
  void dispose() {
    tFEmailUserFocusNode?.dispose();
    tFEmailUserTextController?.dispose();

    tFPasswordUserFocusNode?.dispose();
    tFPasswordUserTextController?.dispose();
  }
}
