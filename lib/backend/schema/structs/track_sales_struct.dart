// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TrackSalesStruct extends BaseStruct {
  TrackSalesStruct({
    String? id,
  }) : _id = id;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  static TrackSalesStruct fromMap(Map<String, dynamic> data) =>
      TrackSalesStruct(
        id: data['id'] as String?,
      );

  static TrackSalesStruct? maybeFromMap(dynamic data) => data is Map
      ? TrackSalesStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
      }.withoutNulls;

  static TrackSalesStruct fromSerializableMap(Map<String, dynamic> data) =>
      TrackSalesStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'TrackSalesStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is TrackSalesStruct && id == other.id;
  }

  @override
  int get hashCode => const ListEquality().hash([id]);
}

TrackSalesStruct createTrackSalesStruct({
  String? id,
}) =>
    TrackSalesStruct(
      id: id,
    );
