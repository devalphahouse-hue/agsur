import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:math';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'modal_create_available_aircraft_widget.dart'
    show ModalCreateAvailableAircraftWidget;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ModalCreateAvailableAircraftModel
    extends FlutterFlowModel<ModalCreateAvailableAircraftWidget> {
  ///  Local state fields for this component.

  bool editar = false;

  ///  State fields for stateful widgets in this component.

  final formKey1 = GlobalKey<FormState>();
  final formKey2 = GlobalKey<FormState>();
  // State field(s) for DPDAircrafts widget.
  String? dPDAircraftsValue;
  FormFieldController<String>? dPDAircraftsValueController;
  // State field(s) for TFSerialNumber widget.
  FocusNode? tFSerialNumberFocusNode;
  TextEditingController? tFSerialNumberTextController;
  String? Function(BuildContext, String?)?
      tFSerialNumberTextControllerValidator;
  String? _tFSerialNumberTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  DateTime? datePicked1;
  // State field(s) for DPDEntryYear widget.
  String? dPDEntryYearValue;
  FormFieldController<String>? dPDEntryYearValueController;
  // State field(s) for DPDStatus widget.
  String? dPDStatusValue;
  FormFieldController<String>? dPDStatusValueController;
  // Stores action output result for [Validate Form] action in BTNRegisterCertificate widget.
  bool? validateFormInsert;
  // State field(s) for DPDEditAircrafts widget.
  String? dPDEditAircraftsValue;
  FormFieldController<String>? dPDEditAircraftsValueController;
  // State field(s) for TFEditSerialNumber widget.
  FocusNode? tFEditSerialNumberFocusNode;
  TextEditingController? tFEditSerialNumberTextController;
  String? Function(BuildContext, String?)?
      tFEditSerialNumberTextControllerValidator;
  String? _tFEditSerialNumberTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  DateTime? datePicked2;
  // State field(s) for DPDEditEntryYear widget.
  String? dPDEditEntryYearValue;
  FormFieldController<String>? dPDEditEntryYearValueController;
  // State field(s) for DPDEditStatus widget.
  String? dPDEditStatusValue;
  FormFieldController<String>? dPDEditStatusValueController;
  // Stores action output result for [Validate Form] action in BTNSaveEdit widget.
  bool? validateForm;
  // State field(s) for TFViewAircraft widget.
  FocusNode? tFViewAircraftFocusNode;
  TextEditingController? tFViewAircraftTextController;
  String? Function(BuildContext, String?)?
      tFViewAircraftTextControllerValidator;
  // State field(s) for TFViewSerialNumber widget.
  FocusNode? tFViewSerialNumberFocusNode;
  TextEditingController? tFViewSerialNumberTextController;
  String? Function(BuildContext, String?)?
      tFViewSerialNumberTextControllerValidator;
  // State field(s) for TFViewEntryYear widget.
  FocusNode? tFViewEntryYearFocusNode;
  TextEditingController? tFViewEntryYearTextController;
  String? Function(BuildContext, String?)?
      tFViewEntryYearTextControllerValidator;
  // State field(s) for TFViewStatus widget.
  FocusNode? tFViewStatusFocusNode;
  TextEditingController? tFViewStatusTextController;
  String? Function(BuildContext, String?)? tFViewStatusTextControllerValidator;

  @override
  void initState(BuildContext context) {
    tFSerialNumberTextControllerValidator =
        _tFSerialNumberTextControllerValidator;
    tFEditSerialNumberTextControllerValidator =
        _tFEditSerialNumberTextControllerValidator;
  }

  @override
  void dispose() {
    tFSerialNumberFocusNode?.dispose();
    tFSerialNumberTextController?.dispose();

    tFEditSerialNumberFocusNode?.dispose();
    tFEditSerialNumberTextController?.dispose();

    tFViewAircraftFocusNode?.dispose();
    tFViewAircraftTextController?.dispose();

    tFViewSerialNumberFocusNode?.dispose();
    tFViewSerialNumberTextController?.dispose();

    tFViewEntryYearFocusNode?.dispose();
    tFViewEntryYearTextController?.dispose();

    tFViewStatusFocusNode?.dispose();
    tFViewStatusTextController?.dispose();
  }
}
