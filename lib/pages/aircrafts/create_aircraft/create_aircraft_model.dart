import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import '/pages/shared/warming_air_craft_photo/warming_air_craft_photo_widget.dart';
import '/pages/shared/warming_m_pecas/warming_m_pecas_widget.dart';
import '/pages/shared/warming_m_proprietario/warming_m_proprietario_widget.dart';
import '/pages/shared/warming_m_voo/warming_m_voo_widget.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'create_aircraft_widget.dart' show CreateAircraftWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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
