import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/request_manager.dart';

import '/index.dart';
import 'dart:async';
import 'view_edit_proposal_widget.dart' show ViewEditProposalWidget;
import 'package:flutter/material.dart';

class ViewEditProposalModel extends FlutterFlowModel<ViewEditProposalWidget> {
  ///  Local state fields for this page.

  List<VwAircraftItemsByAircraftRow> itemsOptional = [];
  void addToItemsOptional(VwAircraftItemsByAircraftRow item) =>
      itemsOptional.add(item);
  void removeFromItemsOptional(VwAircraftItemsByAircraftRow item) =>
      itemsOptional.remove(item);
  void removeAtIndexFromItemsOptional(int index) =>
      itemsOptional.removeAt(index);
  void insertAtIndexInItemsOptional(
          int index, VwAircraftItemsByAircraftRow item) =>
      itemsOptional.insert(index, item);
  void updateItemsOptionalAtIndex(
          int index, Function(VwAircraftItemsByAircraftRow) updateFn) =>
      itemsOptional[index] = updateFn(itemsOptional[index]);

  int countController = 0;

  double baseAircraftPrice = 0.0;
  Map<String, double> selectedItemPrices = {};
  Map<String, String> aircraftToProposalItemId = {};

  List<String> listdIds = [];

  // Cache de futures para os FutureBuilders da lista de opcionais. Sem isto, o
  // `future:` é recriado a cada rebuild (qualquer setState) e refaz as queries
  // — uma para categorias e uma por categoria — gerando dezenas de chamadas
  // repetidas. Memoizamos: categorias uma vez, itens por id de categoria.
  Future<List<CategoryRow>>? optionalCategoriesFuture;
  final Map<String, Future<List<VwAircraftItemsByAircraftRow>>>
      optionalItemsByCategory = {};
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

    optionalCategoriesFuture = null;
    optionalItemsByCategory.clear();
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
