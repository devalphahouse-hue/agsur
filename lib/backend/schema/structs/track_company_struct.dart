// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TrackCompanyStruct extends BaseStruct {
  TrackCompanyStruct({
    String? id,
    String? companyName,
  })  : _id = id,
        _companyName = companyName;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  // "company_name" field.
  String? _companyName;
  String get companyName => _companyName ?? '';
  set companyName(String? val) => _companyName = val;

  bool hasCompanyName() => _companyName != null;

  static TrackCompanyStruct fromMap(Map<String, dynamic> data) =>
      TrackCompanyStruct(
        id: data['id'] as String?,
        companyName: data['company_name'] as String?,
      );

  static TrackCompanyStruct? maybeFromMap(dynamic data) => data is Map
      ? TrackCompanyStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'company_name': _companyName,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
        'company_name': serializeParam(
          _companyName,
          ParamType.String,
        ),
      }.withoutNulls;

  static TrackCompanyStruct fromSerializableMap(Map<String, dynamic> data) =>
      TrackCompanyStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
        companyName: deserializeParam(
          data['company_name'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'TrackCompanyStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is TrackCompanyStruct &&
        id == other.id &&
        companyName == other.companyName;
  }

  @override
  int get hashCode => const ListEquality().hash([id, companyName]);
}

TrackCompanyStruct createTrackCompanyStruct({
  String? id,
  String? companyName,
}) =>
    TrackCompanyStruct(
      id: id,
      companyName: companyName,
    );
