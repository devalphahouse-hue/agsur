import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'c_t_csrd_aircraft_widget.dart' show CTCsrdAircraftWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CTCsrdAircraftModel extends FlutterFlowModel<CTCsrdAircraftWidget> {
  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Custom Action - convertPorcentagem] action in CTCsrdAircraft widget.
  String? retornoValor;
  DateTime? datePicked;
  // State field(s) for DPDLength widget.
  String? dPDLengthValue;
  FormFieldController<String>? dPDLengthValueController;
  // State field(s) for TFDownPayment widget.
  FocusNode? tFDownPaymentFocusNode;
  TextEditingController? tFDownPaymentTextController;
  String? Function(BuildContext, String?)? tFDownPaymentTextControllerValidator;
  // State field(s) for TFInitialDeposit widget.
  FocusNode? tFInitialDepositFocusNode;
  TextEditingController? tFInitialDepositTextController;
  String? Function(BuildContext, String?)?
      tFInitialDepositTextControllerValidator;
  // State field(s) for TFTotalDeposit widget.
  FocusNode? tFTotalDepositFocusNode;
  TextEditingController? tFTotalDepositTextController;
  String? Function(BuildContext, String?)?
      tFTotalDepositTextControllerValidator;
  // Stores action output result for [Backend Call - Update Row(s)] action in BTNRegisterLead widget.
  List<ProposalFinancingRow>? insertProposalFinancing;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tFDownPaymentFocusNode?.dispose();
    tFDownPaymentTextController?.dispose();

    tFInitialDepositFocusNode?.dispose();
    tFInitialDepositTextController?.dispose();

    tFTotalDepositFocusNode?.dispose();
    tFTotalDepositTextController?.dispose();
  }
}
