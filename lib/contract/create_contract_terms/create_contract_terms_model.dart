import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'create_contract_terms_widget.dart' show CreateContractTermsWidget;
import 'package:flutter/material.dart';

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
