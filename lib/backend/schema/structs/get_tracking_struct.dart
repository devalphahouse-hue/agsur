// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class GetTrackingStruct extends BaseStruct {
  GetTrackingStruct({
    List<TrackingStruct>? tracking,
    TrackUserAircraftStruct? trackUserAircraft,
    TrackProposalStruct? trackProposal,
    TrackLeadStruct? trackLead,
    TrackCompanyStruct? trackCompany,
    TrackSalesStruct? trackSales,
    TrackFinancialStruct? trackFinancial,
  })  : _tracking = tracking,
        _trackUserAircraft = trackUserAircraft,
        _trackProposal = trackProposal,
        _trackLead = trackLead,
        _trackCompany = trackCompany,
        _trackSales = trackSales,
        _trackFinancial = trackFinancial;

  // "tracking" field.
  List<TrackingStruct>? _tracking;
  List<TrackingStruct> get tracking => _tracking ?? const [];
  set tracking(List<TrackingStruct>? val) => _tracking = val;

  void updateTracking(Function(List<TrackingStruct>) updateFn) {
    updateFn(_tracking ??= []);
  }

  bool hasTracking() => _tracking != null;

  // "track_user_aircraft" field.
  TrackUserAircraftStruct? _trackUserAircraft;
  TrackUserAircraftStruct get trackUserAircraft =>
      _trackUserAircraft ?? TrackUserAircraftStruct();
  set trackUserAircraft(TrackUserAircraftStruct? val) =>
      _trackUserAircraft = val;

  void updateTrackUserAircraft(Function(TrackUserAircraftStruct) updateFn) {
    updateFn(_trackUserAircraft ??= TrackUserAircraftStruct());
  }

  bool hasTrackUserAircraft() => _trackUserAircraft != null;

  // "track_proposal" field.
  TrackProposalStruct? _trackProposal;
  TrackProposalStruct get trackProposal =>
      _trackProposal ?? TrackProposalStruct();
  set trackProposal(TrackProposalStruct? val) => _trackProposal = val;

  void updateTrackProposal(Function(TrackProposalStruct) updateFn) {
    updateFn(_trackProposal ??= TrackProposalStruct());
  }

  bool hasTrackProposal() => _trackProposal != null;

  // "track_lead" field.
  TrackLeadStruct? _trackLead;
  TrackLeadStruct get trackLead => _trackLead ?? TrackLeadStruct();
  set trackLead(TrackLeadStruct? val) => _trackLead = val;

  void updateTrackLead(Function(TrackLeadStruct) updateFn) {
    updateFn(_trackLead ??= TrackLeadStruct());
  }

  bool hasTrackLead() => _trackLead != null;

  // "track_company" field.
  TrackCompanyStruct? _trackCompany;
  TrackCompanyStruct get trackCompany => _trackCompany ?? TrackCompanyStruct();
  set trackCompany(TrackCompanyStruct? val) => _trackCompany = val;

  void updateTrackCompany(Function(TrackCompanyStruct) updateFn) {
    updateFn(_trackCompany ??= TrackCompanyStruct());
  }

  bool hasTrackCompany() => _trackCompany != null;

  // "track_sales" field.
  TrackSalesStruct? _trackSales;
  TrackSalesStruct get trackSales => _trackSales ?? TrackSalesStruct();
  set trackSales(TrackSalesStruct? val) => _trackSales = val;

  void updateTrackSales(Function(TrackSalesStruct) updateFn) {
    updateFn(_trackSales ??= TrackSalesStruct());
  }

  bool hasTrackSales() => _trackSales != null;

  // "track_financial" field.
  TrackFinancialStruct? _trackFinancial;
  TrackFinancialStruct get trackFinancial =>
      _trackFinancial ?? TrackFinancialStruct();
  set trackFinancial(TrackFinancialStruct? val) => _trackFinancial = val;

  void updateTrackFinancial(Function(TrackFinancialStruct) updateFn) {
    updateFn(_trackFinancial ??= TrackFinancialStruct());
  }

  bool hasTrackFinancial() => _trackFinancial != null;

  static GetTrackingStruct fromMap(Map<String, dynamic> data) =>
      GetTrackingStruct(
        tracking: getStructList(
          data['tracking'],
          TrackingStruct.fromMap,
        ),
        trackUserAircraft: data['track_user_aircraft']
                is TrackUserAircraftStruct
            ? data['track_user_aircraft']
            : TrackUserAircraftStruct.maybeFromMap(data['track_user_aircraft']),
        trackProposal: data['track_proposal'] is TrackProposalStruct
            ? data['track_proposal']
            : TrackProposalStruct.maybeFromMap(data['track_proposal']),
        trackLead: data['track_lead'] is TrackLeadStruct
            ? data['track_lead']
            : TrackLeadStruct.maybeFromMap(data['track_lead']),
        trackCompany: data['track_company'] is TrackCompanyStruct
            ? data['track_company']
            : TrackCompanyStruct.maybeFromMap(data['track_company']),
        trackSales: data['track_sales'] is TrackSalesStruct
            ? data['track_sales']
            : TrackSalesStruct.maybeFromMap(data['track_sales']),
        trackFinancial: data['track_financial'] is TrackFinancialStruct
            ? data['track_financial']
            : TrackFinancialStruct.maybeFromMap(data['track_financial']),
      );

  static GetTrackingStruct? maybeFromMap(dynamic data) => data is Map
      ? GetTrackingStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'tracking': _tracking?.map((e) => e.toMap()).toList(),
        'track_user_aircraft': _trackUserAircraft?.toMap(),
        'track_proposal': _trackProposal?.toMap(),
        'track_lead': _trackLead?.toMap(),
        'track_company': _trackCompany?.toMap(),
        'track_sales': _trackSales?.toMap(),
        'track_financial': _trackFinancial?.toMap(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'tracking': serializeParam(
          _tracking,
          ParamType.DataStruct,
          isList: true,
        ),
        'track_user_aircraft': serializeParam(
          _trackUserAircraft,
          ParamType.DataStruct,
        ),
        'track_proposal': serializeParam(
          _trackProposal,
          ParamType.DataStruct,
        ),
        'track_lead': serializeParam(
          _trackLead,
          ParamType.DataStruct,
        ),
        'track_company': serializeParam(
          _trackCompany,
          ParamType.DataStruct,
        ),
        'track_sales': serializeParam(
          _trackSales,
          ParamType.DataStruct,
        ),
        'track_financial': serializeParam(
          _trackFinancial,
          ParamType.DataStruct,
        ),
      }.withoutNulls;

  static GetTrackingStruct fromSerializableMap(Map<String, dynamic> data) =>
      GetTrackingStruct(
        tracking: deserializeStructParam<TrackingStruct>(
          data['tracking'],
          ParamType.DataStruct,
          true,
          structBuilder: TrackingStruct.fromSerializableMap,
        ),
        trackUserAircraft: deserializeStructParam(
          data['track_user_aircraft'],
          ParamType.DataStruct,
          false,
          structBuilder: TrackUserAircraftStruct.fromSerializableMap,
        ),
        trackProposal: deserializeStructParam(
          data['track_proposal'],
          ParamType.DataStruct,
          false,
          structBuilder: TrackProposalStruct.fromSerializableMap,
        ),
        trackLead: deserializeStructParam(
          data['track_lead'],
          ParamType.DataStruct,
          false,
          structBuilder: TrackLeadStruct.fromSerializableMap,
        ),
        trackCompany: deserializeStructParam(
          data['track_company'],
          ParamType.DataStruct,
          false,
          structBuilder: TrackCompanyStruct.fromSerializableMap,
        ),
        trackSales: deserializeStructParam(
          data['track_sales'],
          ParamType.DataStruct,
          false,
          structBuilder: TrackSalesStruct.fromSerializableMap,
        ),
        trackFinancial: deserializeStructParam(
          data['track_financial'],
          ParamType.DataStruct,
          false,
          structBuilder: TrackFinancialStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'GetTrackingStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is GetTrackingStruct &&
        listEquality.equals(tracking, other.tracking) &&
        trackUserAircraft == other.trackUserAircraft &&
        trackProposal == other.trackProposal &&
        trackLead == other.trackLead &&
        trackCompany == other.trackCompany &&
        trackSales == other.trackSales &&
        trackFinancial == other.trackFinancial;
  }

  @override
  int get hashCode => const ListEquality().hash([
        tracking,
        trackUserAircraft,
        trackProposal,
        trackLead,
        trackCompany,
        trackSales,
        trackFinancial
      ]);
}

GetTrackingStruct createGetTrackingStruct({
  TrackUserAircraftStruct? trackUserAircraft,
  TrackProposalStruct? trackProposal,
  TrackLeadStruct? trackLead,
  TrackCompanyStruct? trackCompany,
  TrackSalesStruct? trackSales,
  TrackFinancialStruct? trackFinancial,
}) =>
    GetTrackingStruct(
      trackUserAircraft: trackUserAircraft ?? TrackUserAircraftStruct(),
      trackProposal: trackProposal ?? TrackProposalStruct(),
      trackLead: trackLead ?? TrackLeadStruct(),
      trackCompany: trackCompany ?? TrackCompanyStruct(),
      trackSales: trackSales ?? TrackSalesStruct(),
      trackFinancial: trackFinancial ?? TrackFinancialStruct(),
    );
