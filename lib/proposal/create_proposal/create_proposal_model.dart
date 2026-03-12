import '/auth/supabase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/pages/modal_edit_company/modal_edit_company_widget.dart';
import '/pages/modal_register_company/modal_register_company_widget.dart';
import '/pages/shared/alert_dialog/alert_dialog_widget.dart';
import '/pages/shared/custom_snac_bar/custom_snac_bar_widget.dart';
import '/pages/shared/empty_all_lists/empty_all_lists_widget.dart';
import '/pages/shared/empty_list/empty_list_widget.dart';
import '/pages/shared/modal_edit_address/modal_edit_address_widget.dart';
import '/pages/shared/modal_register_address/modal_register_address_widget.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'create_proposal_widget.dart' show CreateProposalWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CreateProposalModel extends FlutterFlowModel<CreateProposalWidget> {
  ///  Local state fields for this page.

  int section = 0;

  List<AircraftItemsRow> itemsOptional = [];
  void addToItemsOptional(AircraftItemsRow item) => itemsOptional.add(item);
  void removeFromItemsOptional(AircraftItemsRow item) =>
      itemsOptional.remove(item);
  void removeAtIndexFromItemsOptional(int index) =>
      itemsOptional.removeAt(index);
  void insertAtIndexInItemsOptional(int index, AircraftItemsRow item) =>
      itemsOptional.insert(index, item);
  void updateItemsOptionalAtIndex(
          int index, Function(AircraftItemsRow) updateFn) =>
      itemsOptional[index] = updateFn(itemsOptional[index]);

  int countController = 0;

  List<String> listIds = [];
  void addToListIds(String item) => listIds.add(item);
  void removeFromListIds(String item) => listIds.remove(item);
  void removeAtIndexFromListIds(int index) => listIds.removeAt(index);
  void insertAtIndexInListIds(int index, String item) =>
      listIds.insert(index, item);
  void updateListIdsAtIndex(int index, Function(String) updateFn) =>
      listIds[index] = updateFn(listIds[index]);

  bool section1 = false;

  bool section2 = false;

  ///  State fields for stateful widgets in this page.

  // State field(s) for dpdLead widget.
  String? dpdLeadValue;
  FormFieldController<String>? dpdLeadValueController;
  // Stores action output result for [Backend Call - API (Get lead details for proposal)] action in Button widget.
  ApiCallResponse? getLeadProposal;
  // Stores action output result for [Backend Call - API (Get lead details for proposal)] action in ICEditLeadData widget.
  ApiCallResponse? editCompanyProposal;
  // Stores action output result for [Backend Call - Update Row(s)] action in ICEditLeadData widget.
  List<CompanyRow>? updateCompany;
  // Stores action output result for [Backend Call - API (Get lead details for proposal)] action in ICAddLeadData widget.
  ApiCallResponse? refreshCompanyProposal;
  // Stores action output result for [Backend Call - Insert Row] action in ICAddLeadData widget.
  CompanyRow? insertCompany;
  // Stores action output result for [Backend Call - API (Get lead details for proposal)] action in ICEditAddressData widget.
  ApiCallResponse? editAddressProposal;
  // Stores action output result for [Backend Call - Update Row(s)] action in ICEditAddressData widget.
  List<AddressRow>? updatetAddress;
  // Stores action output result for [Backend Call - API (Get lead details for proposal)] action in ICAddAddressData widget.
  ApiCallResponse? refreshAddressProposal;
  // Stores action output result for [Backend Call - Insert Row] action in ICAddAddressData widget.
  AddressRow? insertAddress;
  // State field(s) for dpdAircraft widget.
  String? dpdAircraftValue;
  FormFieldController<String>? dpdAircraftValueController;
  // Stores action output result for [Backend Call - API (Get aircraft details for proposal)] action in Button widget.
  ApiCallResponse? getAircraftProposal;
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
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  ProposalItemRow? insertProposalItem;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  ProposalFinancingRow? insertProposalFinancing;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  ProposalRow? insertProposal;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<FinancingRatesRow>? getRates;

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
