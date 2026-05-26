import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'oficina_details_widget.dart' show OficinaDetailsWidget;
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class OficinaDetailsModel extends FlutterFlowModel<OficinaDetailsWidget> {
  ///  Local state fields for this page.

  bool edit = false;

  ///  State fields for stateful widgets in this page.

  // State field(s) for TFFullnameOficina widget.
  FocusNode? tFFullnameOficinaFocusNode;
  TextEditingController? tFFullnameOficinaTextController;
  String? Function(BuildContext, String?)?
      tFFullnameOficinaTextControllerValidator;
  // State field(s) for TFCnpjOficina widget.
  FocusNode? tFCnpjOficinaFocusNode;
  TextEditingController? tFCnpjOficinaTextController;
  late MaskTextInputFormatter tFCnpjOficinaMask;
  String? Function(BuildContext, String?)? tFCnpjOficinaTextControllerValidator;
  // State field(s) for TFPhoneOficina widget.
  FocusNode? tFPhoneOficinaFocusNode;
  TextEditingController? tFPhoneOficinaTextController;
  String? Function(BuildContext, String?)?
      tFPhoneOficinaTextControllerValidator;
  // State field(s) for TFEmailOficina widget.
  FocusNode? tFEmailOficinaFocusNode;
  TextEditingController? tFEmailOficinaTextController;
  String? Function(BuildContext, String?)?
      tFEmailOficinaTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tFFullnameOficinaFocusNode?.dispose();
    tFFullnameOficinaTextController?.dispose();

    tFCnpjOficinaFocusNode?.dispose();
    tFCnpjOficinaTextController?.dispose();

    tFPhoneOficinaFocusNode?.dispose();
    tFPhoneOficinaTextController?.dispose();

    tFEmailOficinaFocusNode?.dispose();
    tFEmailOficinaTextController?.dispose();
  }
}
