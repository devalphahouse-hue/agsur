import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'modal_certificate_pilot_widget.dart' show ModalCertificatePilotWidget;
import 'package:flutter/material.dart';

class ModalCertificatePilotModel
    extends FlutterFlowModel<ModalCertificatePilotWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // State field(s) for TFPilotName widget.
  FocusNode? tFPilotNameFocusNode;
  TextEditingController? tFPilotNameTextController;
  String? Function(BuildContext, String?)? tFPilotNameTextControllerValidator;
  // State field(s) for DpdCertificate widget.
  int? dpdCertificateValue;
  FormFieldController<int>? dpdCertificateValueController;
  DateTime? datePicked;
  bool isDataUploading_uploadCertificatePilot = false;
  FFUploadedFile uploadedLocalFile_uploadCertificatePilot =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadCertificatePilot = '';

  // Stores action output result for [Validate Form] action in BTNRegisterCertificate widget.
  bool? form1;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tFPilotNameFocusNode?.dispose();
    tFPilotNameTextController?.dispose();
  }
}
