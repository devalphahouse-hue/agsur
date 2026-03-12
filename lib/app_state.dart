import 'package:flutter/material.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/api_requests/api_manager.dart';
import 'backend/supabase/supabase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {}

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  GetLeadDetailsForProposalStruct _asGetLeadProposal =
      GetLeadDetailsForProposalStruct();
  GetLeadDetailsForProposalStruct get asGetLeadProposal => _asGetLeadProposal;
  set asGetLeadProposal(GetLeadDetailsForProposalStruct value) {
    _asGetLeadProposal = value;
  }

  void updateAsGetLeadProposalStruct(
      Function(GetLeadDetailsForProposalStruct) updateFn) {
    updateFn(_asGetLeadProposal);
  }

  GetAircraftDetailsForProposalStruct _asGetAircraftProposal =
      GetAircraftDetailsForProposalStruct();
  GetAircraftDetailsForProposalStruct get asGetAircraftProposal =>
      _asGetAircraftProposal;
  set asGetAircraftProposal(GetAircraftDetailsForProposalStruct value) {
    _asGetAircraftProposal = value;
  }

  void updateAsGetAircraftProposalStruct(
      Function(GetAircraftDetailsForProposalStruct) updateFn) {
    updateFn(_asGetAircraftProposal);
  }

  GetProposalDetailsStruct _asGetProposalDetails = GetProposalDetailsStruct();
  GetProposalDetailsStruct get asGetProposalDetails => _asGetProposalDetails;
  set asGetProposalDetails(GetProposalDetailsStruct value) {
    _asGetProposalDetails = value;
  }

  void updateAsGetProposalDetailsStruct(
      Function(GetProposalDetailsStruct) updateFn) {
    updateFn(_asGetProposalDetails);
  }

  GetTrackingStruct _asGetTracking = GetTrackingStruct();
  GetTrackingStruct get asGetTracking => _asGetTracking;
  set asGetTracking(GetTrackingStruct value) {
    _asGetTracking = value;
  }

  void updateAsGetTrackingStruct(Function(GetTrackingStruct) updateFn) {
    updateFn(_asGetTracking);
  }

  GetFinancialProposalStruct _asGetFinancialProposal =
      GetFinancialProposalStruct();
  GetFinancialProposalStruct get asGetFinancialProposal =>
      _asGetFinancialProposal;
  set asGetFinancialProposal(GetFinancialProposalStruct value) {
    _asGetFinancialProposal = value;
  }

  void updateAsGetFinancialProposalStruct(
      Function(GetFinancialProposalStruct) updateFn) {
    updateFn(_asGetFinancialProposal);
  }
}
