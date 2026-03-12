// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class GetLeadDetailsForProposalStruct extends BaseStruct {
  GetLeadDetailsForProposalStruct({
    LeadStruct? lead,
    SellerStruct? seller,
    CompanyStruct? company,
    AddressStruct? address,
  })  : _lead = lead,
        _seller = seller,
        _company = company,
        _address = address;

  // "lead" field.
  LeadStruct? _lead;
  LeadStruct get lead => _lead ?? LeadStruct();
  set lead(LeadStruct? val) => _lead = val;

  void updateLead(Function(LeadStruct) updateFn) {
    updateFn(_lead ??= LeadStruct());
  }

  bool hasLead() => _lead != null;

  // "seller" field.
  SellerStruct? _seller;
  SellerStruct get seller => _seller ?? SellerStruct();
  set seller(SellerStruct? val) => _seller = val;

  void updateSeller(Function(SellerStruct) updateFn) {
    updateFn(_seller ??= SellerStruct());
  }

  bool hasSeller() => _seller != null;

  // "company" field.
  CompanyStruct? _company;
  CompanyStruct get company => _company ?? CompanyStruct();
  set company(CompanyStruct? val) => _company = val;

  void updateCompany(Function(CompanyStruct) updateFn) {
    updateFn(_company ??= CompanyStruct());
  }

  bool hasCompany() => _company != null;

  // "address" field.
  AddressStruct? _address;
  AddressStruct get address => _address ?? AddressStruct();
  set address(AddressStruct? val) => _address = val;

  void updateAddress(Function(AddressStruct) updateFn) {
    updateFn(_address ??= AddressStruct());
  }

  bool hasAddress() => _address != null;

  static GetLeadDetailsForProposalStruct fromMap(Map<String, dynamic> data) =>
      GetLeadDetailsForProposalStruct(
        lead: data['lead'] is LeadStruct
            ? data['lead']
            : LeadStruct.maybeFromMap(data['lead']),
        seller: data['seller'] is SellerStruct
            ? data['seller']
            : SellerStruct.maybeFromMap(data['seller']),
        company: data['company'] is CompanyStruct
            ? data['company']
            : CompanyStruct.maybeFromMap(data['company']),
        address: data['address'] is AddressStruct
            ? data['address']
            : AddressStruct.maybeFromMap(data['address']),
      );

  static GetLeadDetailsForProposalStruct? maybeFromMap(dynamic data) => data
          is Map
      ? GetLeadDetailsForProposalStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'lead': _lead?.toMap(),
        'seller': _seller?.toMap(),
        'company': _company?.toMap(),
        'address': _address?.toMap(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'lead': serializeParam(
          _lead,
          ParamType.DataStruct,
        ),
        'seller': serializeParam(
          _seller,
          ParamType.DataStruct,
        ),
        'company': serializeParam(
          _company,
          ParamType.DataStruct,
        ),
        'address': serializeParam(
          _address,
          ParamType.DataStruct,
        ),
      }.withoutNulls;

  static GetLeadDetailsForProposalStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      GetLeadDetailsForProposalStruct(
        lead: deserializeStructParam(
          data['lead'],
          ParamType.DataStruct,
          false,
          structBuilder: LeadStruct.fromSerializableMap,
        ),
        seller: deserializeStructParam(
          data['seller'],
          ParamType.DataStruct,
          false,
          structBuilder: SellerStruct.fromSerializableMap,
        ),
        company: deserializeStructParam(
          data['company'],
          ParamType.DataStruct,
          false,
          structBuilder: CompanyStruct.fromSerializableMap,
        ),
        address: deserializeStructParam(
          data['address'],
          ParamType.DataStruct,
          false,
          structBuilder: AddressStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'GetLeadDetailsForProposalStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is GetLeadDetailsForProposalStruct &&
        lead == other.lead &&
        seller == other.seller &&
        company == other.company &&
        address == other.address;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([lead, seller, company, address]);
}

GetLeadDetailsForProposalStruct createGetLeadDetailsForProposalStruct({
  LeadStruct? lead,
  SellerStruct? seller,
  CompanyStruct? company,
  AddressStruct? address,
}) =>
    GetLeadDetailsForProposalStruct(
      lead: lead ?? LeadStruct(),
      seller: seller ?? SellerStruct(),
      company: company ?? CompanyStruct(),
      address: address ?? AddressStruct(),
    );
