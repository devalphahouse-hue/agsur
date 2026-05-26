import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'create_aircraft_widget.dart' show CreateAircraftWidget;
import 'package:flutter/material.dart';

class CreateAircraftModel extends FlutterFlowModel<CreateAircraftWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  bool isDataUploading_uploadAircraft = false;
  FFUploadedFile uploadedLocalFile_uploadAircraft =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadAircraft = '';

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

  // State field(s) for TFAircraftYear widget.
  FocusNode? tFAircraftYearFocusNode;
  TextEditingController? tFAircraftYearTextController;
  String? Function(BuildContext, String?)?
      tFAircraftYearTextControllerValidator;
  // State field(s) for TFAircraftHopper widget.
  FocusNode? tFAircraftHopperFocusNode;
  TextEditingController? tFAircraftHopperTextController;
  String? Function(BuildContext, String?)?
      tFAircraftHopperTextControllerValidator;
  // State field(s) for TFDescription widget.
  FocusNode? tFDescriptionFocusNode;
  TextEditingController? tFDescriptionTextController;
  String? Function(BuildContext, String?)? tFDescriptionTextControllerValidator;
  bool isDataUploading_uploadOEM = false;
  FFUploadedFile uploadedLocalFile_uploadOEM =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadOEM = '';

  bool isDataUploading_uploadManualVoo = false;
  FFUploadedFile uploadedLocalFile_uploadManualVoo =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadManualVoo = '';

  bool isDataUploading_uploadManualPeca = false;
  FFUploadedFile uploadedLocalFile_uploadManualPeca =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadManualPeca = '';

  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  AircraftsRow? createAircraft;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  AircraftManualsRow? createManualProprietario;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  AircraftManualsRow? createManualVoo;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  AircraftManualsRow? createManualPecas;

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

    tFAircraftYearFocusNode?.dispose();
    tFAircraftYearTextController?.dispose();

    tFAircraftHopperFocusNode?.dispose();
    tFAircraftHopperTextController?.dispose();

    tFDescriptionFocusNode?.dispose();
    tFDescriptionTextController?.dispose();
  }
}
