// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TrackFinancialStruct extends BaseStruct {
  TrackFinancialStruct({
    String? id,
  }) : _id = id;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  static TrackFinancialStruct fromMap(Map<String, dynamic> data) =>
      TrackFinancialStruct(
        id: data['id'] as String?,
      );

  static TrackFinancialStruct? maybeFromMap(dynamic data) => data is Map
      ? TrackFinancialStruct.fromMap(data.cast<String, dynamic>())
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

  static TrackFinancialStruct fromSerializableMap(Map<String, dynamic> data) =>
      TrackFinancialStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'TrackFinancialStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is TrackFinancialStruct && id == other.id;
  }

  @override
  int get hashCode => const ListEquality().hash([id]);
}

TrackFinancialStruct createTrackFinancialStruct({
  String? id,
}) =>
    TrackFinancialStruct(
      id: id,
    );
