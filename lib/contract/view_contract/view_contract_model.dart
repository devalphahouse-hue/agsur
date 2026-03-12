import '/auth/supabase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/modal_edit_company/modal_edit_company_widget.dart';
import '/pages/shared/empty_all_lists/empty_all_lists_widget.dart';
import '/pages/shared/empty_list/empty_list_widget.dart';
import '/pages/shared/modal_edit_address/modal_edit_address_widget.dart';
import '/proposal/components/c_t_csrd_aircraft/c_t_csrd_aircraft_widget.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/request_manager.dart';

import '/index.dart';
import 'dart:async';
import 'view_contract_widget.dart' show ViewContractWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ViewContractModel extends FlutterFlowModel<ViewContractWidget> {
  ///  Local state fields for this page.

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

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Query Rows] action in ViewContract widget.
  List<UsersRow>? user;
  // Stores action output result for [Backend Call - API (Get proposal details)] action in ViewContract widget.
  ApiCallResponse? contractGetProposalDetail;
  // Stores action output result for [Backend Call - Query Rows] action in ViewContract widget.
  List<ProposalFinancingRow>? getProposalFinancial;
  Completer<List<ContractTermsRow>>? requestCompleter1;
  bool apiRequestCompleted = false;
  String? apiRequestLastUniqueKey;
  bool requestCompleted2 = false;
  String? requestLastUniqueKey2;
  // Stores action output result for [Backend Call - API (Get proposal details)] action in ICEditLeadData widget.
  ApiCallResponse? viewEditCompanyProposal;
  // Stores action output result for [Backend Call - Update Row(s)] action in ICEditLeadData widget.
  List<CompanyRow>? updateViewEditCompany;
  // Stores action output result for [Backend Call - API (Get proposal details)] action in ICEditLeadData widget.
  ApiCallResponse? viewEditAddressProposal;
  // Stores action output result for [Backend Call - Update Row(s)] action in ICEditLeadData widget.
  List<AddressRow>? updateViewEditAddress;
  // State field(s) for TFInstruction widget.
  FocusNode? tFInstructionFocusNode;
  TextEditingController? tFInstructionTextController;
  String? Function(BuildContext, String?)? tFInstructionTextControllerValidator;
  // State field(s) for TFTerms widget.
  FocusNode? tFTermsFocusNode;
  TextEditingController? tFTermsTextController;
  String? Function(BuildContext, String?)? tFTermsTextControllerValidator;

  /// Query cache managers for this widget.

  final _propostaFinanceiroManager =
      FutureRequestManager<List<ProposalFinancingRow>>();
  Future<List<ProposalFinancingRow>> propostaFinanceiro({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<List<ProposalFinancingRow>> Function() requestFn,
  }) =>
      _propostaFinanceiroManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearPropostaFinanceiroCache() => _propostaFinanceiroManager.clear();
  void clearPropostaFinanceiroCacheKey(String? uniqueKey) =>
      _propostaFinanceiroManager.clearRequest(uniqueKey);

  final _aircraftManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> aircraft({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _aircraftManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearAircraftCache() => _aircraftManager.clear();
  void clearAircraftCacheKey(String? uniqueKey) =>
      _aircraftManager.clearRequest(uniqueKey);

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tFInstructionFocusNode?.dispose();
    tFInstructionTextController?.dispose();

    tFTermsFocusNode?.dispose();
    tFTermsTextController?.dispose();

    /// Dispose query cache managers for this widget.

    clearPropostaFinanceiroCache();

    clearAircraftCache();
  }

  /// Additional helper methods.
  Future waitForRequestCompleted1({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = requestCompleter1?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  Future waitForApiRequestCompleted({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleted;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  Future waitForRequestCompleted2({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = requestCompleted2;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
