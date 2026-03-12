import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'aircraft_details_widget.dart' show AircraftDetailsWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AircraftDetailsModel extends FlutterFlowModel<AircraftDetailsWidget> {
  ///  Local state fields for this page.

  bool isEdit = false;

  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  bool isDataUploading_uploadUpdateAircraft = false;
  FFUploadedFile uploadedLocalFile_uploadUpdateAircraft =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadUpdateAircraft = '';

  // Stores action output result for [Backend Call - Update Row(s)] action in Container widget.
  List<AircraftsRow>? deleteImageAircraft;
  // State field(s) for TFAircraftName widget.
  FocusNode? tFAircraftNameFocusNode;
  TextEditingController? tFAircraftNameTextController;
  String? Function(BuildContext, String?)?
      tFAircraftNameTextControllerValidator;
  String? _tFAircraftNameTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFPrice widget.
  FocusNode? tFPriceFocusNode;
  TextEditingController? tFPriceTextController;
  String? Function(BuildContext, String?)? tFPriceTextControllerValidator;
  String? _tFPriceTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFAircraftHopper widget.
  FocusNode? tFAircraftHopperFocusNode;
  TextEditingController? tFAircraftHopperTextController;
  String? Function(BuildContext, String?)?
      tFAircraftHopperTextControllerValidator;
  // State field(s) for TFDescription widget.
  FocusNode? tFDescriptionFocusNode;
  TextEditingController? tFDescriptionTextController;
  String? Function(BuildContext, String?)? tFDescriptionTextControllerValidator;
  bool isDataUploading_uploadUpdateOEM = false;
  FFUploadedFile uploadedLocalFile_uploadUpdateOEM =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadUpdateOEM = '';

  bool isDataUploading_uploadUpdateManualVoo = false;
  FFUploadedFile uploadedLocalFile_uploadUpdateManualVoo =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadUpdateManualVoo = '';

  bool isDataUploading_uploadUpdateManualPeca = false;
  FFUploadedFile uploadedLocalFile_uploadUpdateManualPeca =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadUpdateManualPeca = '';

  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<AircraftsRow>? updateAircraft;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<AircraftsRow>? updateImageAircraft;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<AircraftManualsRow>? updateManualProprietario;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<AircraftManualsRow>? updateManualVoo;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<AircraftManualsRow>? updateManualPecas;

  @override
  void initState(BuildContext context) {
    tFAircraftNameTextControllerValidator =
        _tFAircraftNameTextControllerValidator;
    tFPriceTextControllerValidator = _tFPriceTextControllerValidator;
  }

  @override
  void dispose() {
    tFAircraftNameFocusNode?.dispose();
    tFAircraftNameTextController?.dispose();

    tFPriceFocusNode?.dispose();
    tFPriceTextController?.dispose();

    tFAircraftHopperFocusNode?.dispose();
    tFAircraftHopperTextController?.dispose();

    tFDescriptionFocusNode?.dispose();
    tFDescriptionTextController?.dispose();
  }
}
