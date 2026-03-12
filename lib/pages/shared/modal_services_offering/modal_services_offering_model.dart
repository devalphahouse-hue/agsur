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
import 'modal_services_offering_widget.dart' show ModalServicesOfferingWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ModalServicesOfferingModel
    extends FlutterFlowModel<ModalServicesOfferingWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey1 = GlobalKey<FormState>();
  final formKey2 = GlobalKey<FormState>();
  // State field(s) for DpdType widget.
  String? dpdTypeValue;
  FormFieldController<String>? dpdTypeValueController;
  // State field(s) for TFTitle widget.
  FocusNode? tFTitleFocusNode;
  TextEditingController? tFTitleTextController;
  String? Function(BuildContext, String?)? tFTitleTextControllerValidator;
  String? _tFTitleTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFModels widget.
  FocusNode? tFModelsFocusNode;
  TextEditingController? tFModelsTextController;
  String? Function(BuildContext, String?)? tFModelsTextControllerValidator;
  String? _tFModelsTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  bool isDataUploading_uploadPDF = false;
  FFUploadedFile uploadedLocalFile_uploadPDF =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadPDF = '';

  // Stores action output result for [Validate Form] action in BTNRegisterServicesOffering widget.
  bool? formRegister;
  // Stores action output result for [Backend Call - Insert Row] action in BTNRegisterServicesOffering widget.
  ServicesOfferingRow? insertServiceOffering;
  // State field(s) for DpdTypeEdit widget.
  String? dpdTypeEditValue;
  FormFieldController<String>? dpdTypeEditValueController;
  // State field(s) for TFTitleEdit widget.
  FocusNode? tFTitleEditFocusNode;
  TextEditingController? tFTitleEditTextController;
  String? Function(BuildContext, String?)? tFTitleEditTextControllerValidator;
  String? _tFTitleEditTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'service_title is required';
    }

    return null;
  }

  // State field(s) for TFModelsEdit widget.
  FocusNode? tFModelsEditFocusNode;
  TextEditingController? tFModelsEditTextController;
  String? Function(BuildContext, String?)? tFModelsEditTextControllerValidator;
  String? _tFModelsEditTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'models is required';
    }

    return null;
  }

  bool isDataUploading_uploadPDFEdit = false;
  FFUploadedFile uploadedLocalFile_uploadPDFEdit =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadPDFEdit = '';

  // Stores action output result for [Validate Form] action in BTNEditServiceOffering widget.
  bool? formEdit;
  // Stores action output result for [Backend Call - Update Row(s)] action in BTNEditServiceOffering widget.
  List<ServicesOfferingRow>? updateService;

  @override
  void initState(BuildContext context) {
    tFTitleTextControllerValidator = _tFTitleTextControllerValidator;
    tFModelsTextControllerValidator = _tFModelsTextControllerValidator;
    tFTitleEditTextControllerValidator = _tFTitleEditTextControllerValidator;
    tFModelsEditTextControllerValidator = _tFModelsEditTextControllerValidator;
  }

  @override
  void dispose() {
    tFTitleFocusNode?.dispose();
    tFTitleTextController?.dispose();

    tFModelsFocusNode?.dispose();
    tFModelsTextController?.dispose();

    tFTitleEditFocusNode?.dispose();
    tFTitleEditTextController?.dispose();

    tFModelsEditFocusNode?.dispose();
    tFModelsEditTextController?.dispose();
  }
}
