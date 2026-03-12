import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'create_contract_terms_widget.dart' show CreateContractTermsWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CreateContractTermsModel
    extends FlutterFlowModel<CreateContractTermsWidget> {
  ///  Local state fields for this page.

  bool termsActive = false;

  bool instructionsActive = false;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<ContractTermsRow>? updateTerms;
  // State field(s) for TFContractTerms widget.
  FocusNode? tFContractTermsFocusNode;
  TextEditingController? tFContractTermsTextController;
  String? Function(BuildContext, String?)?
      tFContractTermsTextControllerValidator;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<ContractTermsRow>? updateInstructions;
  // State field(s) for TFContractInstructions widget.
  FocusNode? tFContractInstructionsFocusNode;
  TextEditingController? tFContractInstructionsTextController;
  String? Function(BuildContext, String?)?
      tFContractInstructionsTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tFContractTermsFocusNode?.dispose();
    tFContractTermsTextController?.dispose();

    tFContractInstructionsFocusNode?.dispose();
    tFContractInstructionsTextController?.dispose();
  }
}
