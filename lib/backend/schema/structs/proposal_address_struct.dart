// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ProposalAddressStruct extends BaseStruct {
  ProposalAddressStruct({
    String? id,
    String? zipcode,
    String? street,
    String? number,
    String? neighborhood,
    String? city,
    String? state,
    String? complement,
  })  : _id = id,
        _zipcode = zipcode,
        _street = street,
        _number = number,
        _neighborhood = neighborhood,
        _city = city,
        _state = state,
        _complement = complement;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  // "zipcode" field.
  String? _zipcode;
  String get zipcode => _zipcode ?? '';
  set zipcode(String? val) => _zipcode = val;

  bool hasZipcode() => _zipcode != null;

  // "street" field.
  String? _street;
  String get street => _street ?? '';
  set street(String? val) => _street = val;

  bool hasStreet() => _street != null;

  // "number" field.
  String? _number;
  String get number => _number ?? '';
  set number(String? val) => _number = val;

  bool hasNumber() => _number != null;

  // "neighborhood" field.
  String? _neighborhood;
  String get neighborhood => _neighborhood ?? '';
  set neighborhood(String? val) => _neighborhood = val;

  bool hasNeighborhood() => _neighborhood != null;

  // "city" field.
  String? _city;
  String get city => _city ?? '';
  set city(String? val) => _city = val;

  bool hasCity() => _city != null;

  // "state" field.
  String? _state;
  String get state => _state ?? '';
  set state(String? val) => _state = val;

  bool hasState() => _state != null;

  // "complement" field.
  String? _complement;
  String get complement => _complement ?? '';
  set complement(String? val) => _complement = val;

  bool hasComplement() => _complement != null;

  static ProposalAddressStruct fromMap(Map<String, dynamic> data) =>
      ProposalAddressStruct(
        id: data['id'] as String?,
        zipcode: data['zipcode'] as String?,
        street: data['street'] as String?,
        number: data['number'] as String?,
        neighborhood: data['neighborhood'] as String?,
        city: data['city'] as String?,
        state: data['state'] as String?,
        complement: data['complement'] as String?,
      );

  static ProposalAddressStruct? maybeFromMap(dynamic data) => data is Map
      ? ProposalAddressStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'zipcode': _zipcode,
        'street': _street,
        'number': _number,
        'neighborhood': _neighborhood,
        'city': _city,
        'state': _state,
        'complement': _complement,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
        'zipcode': serializeParam(
          _zipcode,
          ParamType.String,
        ),
        'street': serializeParam(
          _street,
          ParamType.String,
        ),
        'number': serializeParam(
          _number,
          ParamType.String,
        ),
        'neighborhood': serializeParam(
          _neighborhood,
          ParamType.String,
        ),
        'city': serializeParam(
          _city,
          ParamType.String,
        ),
        'state': serializeParam(
          _state,
          ParamType.String,
        ),
        'complement': serializeParam(
          _complement,
          ParamType.String,
        ),
      }.withoutNulls;

  static ProposalAddressStruct fromSerializableMap(Map<String, dynamic> data) =>
      ProposalAddressStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
        zipcode: deserializeParam(
          data['zipcode'],
          ParamType.String,
          false,
        ),
        street: deserializeParam(
          data['street'],
          ParamType.String,
          false,
        ),
        number: deserializeParam(
          data['number'],
          ParamType.String,
          false,
        ),
        neighborhood: deserializeParam(
          data['neighborhood'],
          ParamType.String,
          false,
        ),
        city: deserializeParam(
          data['city'],
          ParamType.String,
          false,
        ),
        state: deserializeParam(
          data['state'],
          ParamType.String,
          false,
        ),
        complement: deserializeParam(
          data['complement'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'ProposalAddressStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ProposalAddressStruct &&
        id == other.id &&
        zipcode == other.zipcode &&
        street == other.street &&
        number == other.number &&
        neighborhood == other.neighborhood &&
        city == other.city &&
        state == other.state &&
        complement == other.complement;
  }

  @override
  int get hashCode => const ListEquality().hash(
      [id, zipcode, street, number, neighborhood, city, state, complement]);
}

ProposalAddressStruct createProposalAddressStruct({
  String? id,
  String? zipcode,
  String? street,
  String? number,
  String? neighborhood,
  String? city,
  String? state,
  String? complement,
}) =>
    ProposalAddressStruct(
      id: id,
      zipcode: zipcode,
      street: street,
      number: number,
      neighborhood: neighborhood,
      city: city,
      state: state,
      complement: complement,
    );
