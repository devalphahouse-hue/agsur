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
import '/pages/shared/alert_dialog/alert_dialog_widget.dart';
import '/pages/shared/custom_snac_bar/custom_snac_bar_widget.dart';
import '/pages/shared/empty_list/empty_list_widget.dart';
import '/pages/shared/modal_edit_address/modal_edit_address_widget.dart';
import '/pages/shared/modal_register_address/modal_register_address_widget.dart';
import '/proposal/components/c_t_csrd_aircraft/c_t_csrd_aircraft_widget.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/request_manager.dart';

import '/index.dart';
import 'dart:async';
import 'view_edit_proposal_widget.dart' show ViewEditProposalWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ViewEditProposalModel extends FlutterFlowModel<ViewEditProposalWidget> {
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

  double baseAircraftPrice = 0.0;
  Map<String, double> selectedItemPrices = {};
  Map<String, String> aircraftToProposalItemId = {};

  List<String> listdIds = [];
  void addToListdIds(String item) => listdIds.add(item);
  void removeFromListdIds(String item) => listdIds.remove(item);
  void removeAtIndexFromListdIds(int index) => listdIds.removeAt(index);
  void insertAtIndexInListdIds(int index, String item) =>
      listdIds.insert(index, item);
  void updateListdIdsAtIndex(int index, Function(String) updateFn) =>
      listdIds[index] = updateFn(listdIds[index]);

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (Get proposal details)] action in ViewEditProposal widget.
  ApiCallResponse? returnGetProposalDetail;
  bool apiRequestCompleted = false;
  String? apiRequestLastUniqueKey;
  Completer<List<ProposalFinancingRow>>? requestCompleter;
  // Stores action output result for [Backend Call - API (Get proposal details)] action in ICEditLeadData widget.
  ApiCallResponse? viewEditCompanyProposal;
  // Stores action output result for [Backend Call - Update Row(s)] action in ICEditLeadData widget.
  List<CompanyRow>? updateViewEditCompany;
  // Stores action output result for [Backend Call - API (Get proposal details)] action in ICEditLeadData widget.
  ApiCallResponse? viewEditAddressProposal;
  // Stores action output result for [Backend Call - Update Row(s)] action in ICEditLeadData widget.
  List<AddressRow>? updateViewEditAddress;
  // Stores action output result for [Backend Call - API (Get proposal details)] action in ICAddAddressData widget.
  ApiCallResponse? viewCreateAddressProposal;
  // Stores action output result for [Backend Call - Insert Row] action in ICAddAddressData widget.
  AddressRow? viewInsertAddress;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  TrackingRow? createTracking;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  FinancialRow? createFinance;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  SalesRow? createSales;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  UserAircraftRow? createUserAircraft;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  UsersRow? createUserPublic;
  // Stores action output result for [Backend Call - API (Create account another user)] action in Button widget.
  ApiCallResponse? createUserAuth;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<LeadsRow>? getLead;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<UsersRow>? userExist;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<ProposalRow>? updateToContract;

  /// Query cache managers for this widget.

  final _proposalManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> proposal({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _proposalManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearProposalCache() => _proposalManager.clear();
  void clearProposalCacheKey(String? uniqueKey) =>
      _proposalManager.clearRequest(uniqueKey);

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    /// Dispose query cache managers for this widget.

    clearProposalCache();
  }

  /// Additional helper methods.
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

  Future waitForRequestCompleted({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = requestCompleter?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
