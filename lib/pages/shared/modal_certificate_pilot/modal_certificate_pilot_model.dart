import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:math';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'modal_certificate_pilot_widget.dart' show ModalCertificatePilotWidget;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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
