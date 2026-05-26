import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'create_rates_widget.dart' show CreateRatesWidget;
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class CreateRatesModel extends FlutterFlowModel<CreateRatesWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TFPremiumRateFive widget.
  FocusNode? tFPremiumRateFiveFocusNode;
  TextEditingController? tFPremiumRateFiveTextController;
  late MaskTextInputFormatter tFPremiumRateFiveMask;
  String? Function(BuildContext, String?)?
      tFPremiumRateFiveTextControllerValidator;
  // State field(s) for TFPremiumRateSeven widget.
  FocusNode? tFPremiumRateSevenFocusNode;
  TextEditingController? tFPremiumRateSevenTextController;
  late MaskTextInputFormatter tFPremiumRateSevenMask;
  String? Function(BuildContext, String?)?
      tFPremiumRateSevenTextControllerValidator;
  // State field(s) for TFSofrRate widget.
  FocusNode? tFSofrRateFocusNode;
  TextEditingController? tFSofrRateTextController;
  late MaskTextInputFormatter tFSofrRateMask;
  String? Function(BuildContext, String?)? tFSofrRateTextControllerValidator;
  // State field(s) for TFInterestRate widget.
  FocusNode? tFInterestRateFocusNode;
  TextEditingController? tFInterestRateTextController;
  late MaskTextInputFormatter tFInterestRateMask;
  String? Function(BuildContext, String?)?
      tFInterestRateTextControllerValidator;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<FinancingRatesRow>? updateRates;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tFPremiumRateFiveFocusNode?.dispose();
    tFPremiumRateFiveTextController?.dispose();

    tFPremiumRateSevenFocusNode?.dispose();
    tFPremiumRateSevenTextController?.dispose();

    tFSofrRateFocusNode?.dispose();
    tFSofrRateTextController?.dispose();

    tFInterestRateFocusNode?.dispose();
    tFInterestRateTextController?.dispose();
  }
}
