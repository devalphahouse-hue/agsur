// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class LeadStruct extends BaseStruct {
  LeadStruct({
    String? id,
    String? fullname,
    String? email,
    String? phone,
    String? sellerId,
  })  : _id = id,
        _fullname = fullname,
        _email = email,
        _phone = phone,
        _sellerId = sellerId;

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

  // "seller_id" field.
  String? _sellerId;
  String get sellerId => _sellerId ?? '';
  set sellerId(String? val) => _sellerId = val;

  bool hasSellerId() => _sellerId != null;

  static LeadStruct fromMap(Map<String, dynamic> data) => LeadStruct(
        id: data['id'] as String?,
        fullname: data['fullname'] as String?,
        email: data['email'] as String?,
        phone: data['phone'] as String?,
        sellerId: data['seller_id'] as String?,
      );

  static LeadStruct? maybeFromMap(dynamic data) =>
      data is Map ? LeadStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'fullname': _fullname,
        'email': _email,
        'phone': _phone,
        'seller_id': _sellerId,
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
        'seller_id': serializeParam(
          _sellerId,
          ParamType.String,
        ),
      }.withoutNulls;

  static LeadStruct fromSerializableMap(Map<String, dynamic> data) =>
      LeadStruct(
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
        sellerId: deserializeParam(
          data['seller_id'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'LeadStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is LeadStruct &&
        id == other.id &&
        fullname == other.fullname &&
        email == other.email &&
        phone == other.phone &&
        sellerId == other.sellerId;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([id, fullname, email, phone, sellerId]);
}

LeadStruct createLeadStruct({
  String? id,
  String? fullname,
  String? email,
  String? phone,
  String? sellerId,
}) =>
    LeadStruct(
      id: id,
      fullname: fullname,
      email: email,
      phone: phone,
      sellerId: sellerId,
    );
