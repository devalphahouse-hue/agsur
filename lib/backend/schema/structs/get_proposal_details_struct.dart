// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class GetProposalDetailsStruct extends BaseStruct {
  GetProposalDetailsStruct({
    ProposalStruct? proposal,
    ProposalLeadStruct? proposalLead,
    ProposalCompanyStruct? proposalCompany,
    ProposalAddressStruct? proposalAddress,
    ProposalAircraftStruct? proposalAircraft,
    List<ProposalSeriesItemsStruct>? proposalSeriesItems,
    List<ProposalOptionalItemsStruct>? proposalOptionalItems,
  })  : _proposal = proposal,
        _proposalLead = proposalLead,
        _proposalCompany = proposalCompany,
        _proposalAddress = proposalAddress,
        _proposalAircraft = proposalAircraft,
        _proposalSeriesItems = proposalSeriesItems,
        _proposalOptionalItems = proposalOptionalItems;

  // "proposal" field.
  ProposalStruct? _proposal;
  ProposalStruct get proposal => _proposal ?? ProposalStruct();
  set proposal(ProposalStruct? val) => _proposal = val;

  void updateProposal(Function(ProposalStruct) updateFn) {
    updateFn(_proposal ??= ProposalStruct());
  }

  bool hasProposal() => _proposal != null;

  // "proposal_lead" field.
  ProposalLeadStruct? _proposalLead;
  ProposalLeadStruct get proposalLead => _proposalLead ?? ProposalLeadStruct();
  set proposalLead(ProposalLeadStruct? val) => _proposalLead = val;

  void updateProposalLead(Function(ProposalLeadStruct) updateFn) {
    updateFn(_proposalLead ??= ProposalLeadStruct());
  }

  bool hasProposalLead() => _proposalLead != null;

  // "proposal_company" field.
  ProposalCompanyStruct? _proposalCompany;
  ProposalCompanyStruct get proposalCompany =>
      _proposalCompany ?? ProposalCompanyStruct();
  set proposalCompany(ProposalCompanyStruct? val) => _proposalCompany = val;

  void updateProposalCompany(Function(ProposalCompanyStruct) updateFn) {
    updateFn(_proposalCompany ??= ProposalCompanyStruct());
  }

  bool hasProposalCompany() => _proposalCompany != null;

  // "proposal_address" field.
  ProposalAddressStruct? _proposalAddress;
  ProposalAddressStruct get proposalAddress =>
      _proposalAddress ?? ProposalAddressStruct();
  set proposalAddress(ProposalAddressStruct? val) => _proposalAddress = val;

  void updateProposalAddress(Function(ProposalAddressStruct) updateFn) {
    updateFn(_proposalAddress ??= ProposalAddressStruct());
  }

  bool hasProposalAddress() => _proposalAddress != null;

  // "proposal_aircraft" field.
  ProposalAircraftStruct? _proposalAircraft;
  ProposalAircraftStruct get proposalAircraft =>
      _proposalAircraft ?? ProposalAircraftStruct();
  set proposalAircraft(ProposalAircraftStruct? val) => _proposalAircraft = val;

  void updateProposalAircraft(Function(ProposalAircraftStruct) updateFn) {
    updateFn(_proposalAircraft ??= ProposalAircraftStruct());
  }

  bool hasProposalAircraft() => _proposalAircraft != null;

  // "proposal_series_items" field.
  List<ProposalSeriesItemsStruct>? _proposalSeriesItems;
  List<ProposalSeriesItemsStruct> get proposalSeriesItems =>
      _proposalSeriesItems ?? const [];
  set proposalSeriesItems(List<ProposalSeriesItemsStruct>? val) =>
      _proposalSeriesItems = val;

  void updateProposalSeriesItems(
      Function(List<ProposalSeriesItemsStruct>) updateFn) {
    updateFn(_proposalSeriesItems ??= []);
  }

  bool hasProposalSeriesItems() => _proposalSeriesItems != null;

  // "proposal_optional_items" field.
  List<ProposalOptionalItemsStruct>? _proposalOptionalItems;
  List<ProposalOptionalItemsStruct> get proposalOptionalItems =>
      _proposalOptionalItems ?? const [];
  set proposalOptionalItems(List<ProposalOptionalItemsStruct>? val) =>
      _proposalOptionalItems = val;

  void updateProposalOptionalItems(
      Function(List<ProposalOptionalItemsStruct>) updateFn) {
    updateFn(_proposalOptionalItems ??= []);
  }

  bool hasProposalOptionalItems() => _proposalOptionalItems != null;

  static GetProposalDetailsStruct fromMap(Map<String, dynamic> data) =>
      GetProposalDetailsStruct(
        proposal: data['proposal'] is ProposalStruct
            ? data['proposal']
            : ProposalStruct.maybeFromMap(data['proposal']),
        proposalLead: data['proposal_lead'] is ProposalLeadStruct
            ? data['proposal_lead']
            : ProposalLeadStruct.maybeFromMap(data['proposal_lead']),
        proposalCompany: data['proposal_company'] is ProposalCompanyStruct
            ? data['proposal_company']
            : ProposalCompanyStruct.maybeFromMap(data['proposal_company']),
        proposalAddress: data['proposal_address'] is ProposalAddressStruct
            ? data['proposal_address']
            : ProposalAddressStruct.maybeFromMap(data['proposal_address']),
        proposalAircraft: data['proposal_aircraft'] is ProposalAircraftStruct
            ? data['proposal_aircraft']
            : ProposalAircraftStruct.maybeFromMap(data['proposal_aircraft']),
        proposalSeriesItems: getStructList(
          data['proposal_series_items'],
          ProposalSeriesItemsStruct.fromMap,
        ),
        proposalOptionalItems: getStructList(
          data['proposal_optional_items'],
          ProposalOptionalItemsStruct.fromMap,
        ),
      );

  static GetProposalDetailsStruct? maybeFromMap(dynamic data) => data is Map
      ? GetProposalDetailsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'proposal': _proposal?.toMap(),
        'proposal_lead': _proposalLead?.toMap(),
        'proposal_company': _proposalCompany?.toMap(),
        'proposal_address': _proposalAddress?.toMap(),
        'proposal_aircraft': _proposalAircraft?.toMap(),
        'proposal_series_items':
            _proposalSeriesItems?.map((e) => e.toMap()).toList(),
        'proposal_optional_items':
            _proposalOptionalItems?.map((e) => e.toMap()).toList(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'proposal': serializeParam(
          _proposal,
          ParamType.DataStruct,
        ),
        'proposal_lead': serializeParam(
          _proposalLead,
          ParamType.DataStruct,
        ),
        'proposal_company': serializeParam(
          _proposalCompany,
          ParamType.DataStruct,
        ),
        'proposal_address': serializeParam(
          _proposalAddress,
          ParamType.DataStruct,
        ),
        'proposal_aircraft': serializeParam(
          _proposalAircraft,
          ParamType.DataStruct,
        ),
        'proposal_series_items': serializeParam(
          _proposalSeriesItems,
          ParamType.DataStruct,
          isList: true,
        ),
        'proposal_optional_items': serializeParam(
          _proposalOptionalItems,
          ParamType.DataStruct,
          isList: true,
        ),
      }.withoutNulls;

  static GetProposalDetailsStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      GetProposalDetailsStruct(
        proposal: deserializeStructParam(
          data['proposal'],
          ParamType.DataStruct,
          false,
          structBuilder: ProposalStruct.fromSerializableMap,
        ),
        proposalLead: deserializeStructParam(
          data['proposal_lead'],
          ParamType.DataStruct,
          false,
          structBuilder: ProposalLeadStruct.fromSerializableMap,
        ),
        proposalCompany: deserializeStructParam(
          data['proposal_company'],
          ParamType.DataStruct,
          false,
          structBuilder: ProposalCompanyStruct.fromSerializableMap,
        ),
        proposalAddress: deserializeStructParam(
          data['proposal_address'],
          ParamType.DataStruct,
          false,
          structBuilder: ProposalAddressStruct.fromSerializableMap,
        ),
        proposalAircraft: deserializeStructParam(
          data['proposal_aircraft'],
          ParamType.DataStruct,
          false,
          structBuilder: ProposalAircraftStruct.fromSerializableMap,
        ),
        proposalSeriesItems: deserializeStructParam<ProposalSeriesItemsStruct>(
          data['proposal_series_items'],
          ParamType.DataStruct,
          true,
          structBuilder: ProposalSeriesItemsStruct.fromSerializableMap,
        ),
        proposalOptionalItems:
            deserializeStructParam<ProposalOptionalItemsStruct>(
          data['proposal_optional_items'],
          ParamType.DataStruct,
          true,
          structBuilder: ProposalOptionalItemsStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'GetProposalDetailsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is GetProposalDetailsStruct &&
        proposal == other.proposal &&
        proposalLead == other.proposalLead &&
        proposalCompany == other.proposalCompany &&
        proposalAddress == other.proposalAddress &&
        proposalAircraft == other.proposalAircraft &&
        listEquality.equals(proposalSeriesItems, other.proposalSeriesItems) &&
        listEquality.equals(proposalOptionalItems, other.proposalOptionalItems);
  }

  @override
  int get hashCode => const ListEquality().hash([
        proposal,
        proposalLead,
        proposalCompany,
        proposalAddress,
        proposalAircraft,
        proposalSeriesItems,
        proposalOptionalItems
      ]);
}

GetProposalDetailsStruct createGetProposalDetailsStruct({
  ProposalStruct? proposal,
  ProposalLeadStruct? proposalLead,
  ProposalCompanyStruct? proposalCompany,
  ProposalAddressStruct? proposalAddress,
  ProposalAircraftStruct? proposalAircraft,
}) =>
    GetProposalDetailsStruct(
      proposal: proposal ?? ProposalStruct(),
      proposalLead: proposalLead ?? ProposalLeadStruct(),
      proposalCompany: proposalCompany ?? ProposalCompanyStruct(),
      proposalAddress: proposalAddress ?? ProposalAddressStruct(),
      proposalAircraft: proposalAircraft ?? ProposalAircraftStruct(),
    );
