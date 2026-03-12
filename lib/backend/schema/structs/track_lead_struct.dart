// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TrackLeadStruct extends BaseStruct {
  TrackLeadStruct({
    String? id,
    String? fullname,
  })  : _id = id,
        _fullname = fullname;

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

  static TrackLeadStruct fromMap(Map<String, dynamic> data) => TrackLeadStruct(
        id: data['id'] as String?,
        fullname: data['fullname'] as String?,
      );

  static TrackLeadStruct? maybeFromMap(dynamic data) => data is Map
      ? TrackLeadStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'fullname': _fullname,
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
      }.withoutNulls;

  static TrackLeadStruct fromSerializableMap(Map<String, dynamic> data) =>
      TrackLeadStruct(
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
      );

  @override
  String toString() => 'TrackLeadStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is TrackLeadStruct &&
        id == other.id &&
        fullname == other.fullname;
  }

  @override
  int get hashCode => const ListEquality().hash([id, fullname]);
}

TrackLeadStruct createTrackLeadStruct({
  String? id,
  String? fullname,
}) =>
    TrackLeadStruct(
      id: id,
      fullname: fullname,
    );
