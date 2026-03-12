// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ProposalLeadStruct extends BaseStruct {
  ProposalLeadStruct({
    String? id,
    String? fullname,
    String? email,
    String? phone,
  })  : _id = id,
        _fullname = fullname,
        _email = email,
        _phone = phone;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  // "fullname" field.
  String? _fullname;
  String get fullname => _fullname ?? '';
  set fullname(String? val) => _fullname = val;

  bool hasFullname() => _fullname != null;

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  set email(String? val) => _email = val;

  bool hasEmail() => _email != null;

  // "phone" field.
  String? _phone;
  String get phone => _phone ?? '';
  set phone(String? val) => _phone = val;

  bool hasPhone() => _phone != null;

  static ProposalLeadStruct fromMap(Map<String, dynamic> data) =>
      ProposalLeadStruct(
        id: data['id'] as String?,
        fullname: data['fullname'] as String?,
        email: data['email'] as String?,
        phone: data['phone'] as String?,
      );

  static ProposalLeadStruct? maybeFromMap(dynamic data) => data is Map
      ? ProposalLeadStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'fullname': _fullname,
        'email': _email,
        'phone': _phone,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
        'fullname': serializeParam(
          _fullname,
          ParamType.String,
        ),
        'email': serializeParam(
          _email,
          ParamType.String,
        ),
        'phone': serializeParam(
          _phone,
          ParamType.String,
        ),
      }.withoutNulls;

  static ProposalLeadStruct fromSerializableMap(Map<String, dynamic> data) =>
      ProposalLeadStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
        fullname: deserializeParam(
          data['fullname'],
          ParamType.String,
          false,
        ),
        email: deserializeParam(
          data['email'],
          ParamType.String,
          false,
        ),
        phone: deserializeParam(
          data['phone'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'ProposalLeadStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ProposalLeadStruct &&
        id == other.id &&
        fullname == other.fullname &&
        email == other.email &&
        phone == other.phone;
  }

  @override
  int get hashCode => const ListEquality().hash([id, fullname, email, phone]);
}

ProposalLeadStruct createProposalLeadStruct({
  String? id,
  String? fullname,
  String? email,
  String? phone,
}) =>
    ProposalLeadStruct(
      id: id,
      fullname: fullname,
      email: email,
      phone: phone,
    );
