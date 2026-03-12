// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SellerStruct extends BaseStruct {
  SellerStruct({
    String? sellerId,
    String? fullname,
  })  : _sellerId = sellerId,
        _fullname = fullname;

  // "seller_id" field.
  String? _sellerId;
  String get sellerId => _sellerId ?? '';
  set sellerId(String? val) => _sellerId = val;

  bool hasSellerId() => _sellerId != null;

  // "fullname" field.
  String? _fullname;
  String get fullname => _fullname ?? '';
  set fullname(String? val) => _fullname = val;

  bool hasFullname() => _fullname != null;

  static SellerStruct fromMap(Map<String, dynamic> data) => SellerStruct(
        sellerId: data['seller_id'] as String?,
        fullname: data['fullname'] as String?,
      );

  static SellerStruct? maybeFromMap(dynamic data) =>
      data is Map ? SellerStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'seller_id': _sellerId,
        'fullname': _fullname,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'seller_id': serializeParam(
          _sellerId,
          ParamType.String,
        ),
        'fullname': serializeParam(
          _fullname,
          ParamType.String,
        ),
      }.withoutNulls;

  static SellerStruct fromSerializableMap(Map<String, dynamic> data) =>
      SellerStruct(
        sellerId: deserializeParam(
          data['seller_id'],
          ParamType.String,
          false,
        ),
        fullname: deserializeParam(
          data['fullname'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'SellerStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is SellerStruct &&
        sellerId == other.sellerId &&
        fullname == other.fullname;
  }

  @override
  int get hashCode => const ListEquality().hash([sellerId, fullname]);
}

SellerStruct createSellerStruct({
  String? sellerId,
  String? fullname,
}) =>
    SellerStruct(
      sellerId: sellerId,
      fullname: fullname,
    );
