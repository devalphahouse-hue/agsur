// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TrackUserAircraftStruct extends BaseStruct {
  TrackUserAircraftStruct({
    String? id,
    String? proposalId,
  })  : _id = id,
        _proposalId = proposalId;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  // "proposal_id" field.
  String? _proposalId;
  String get proposalId => _proposalId ?? '';
  set proposalId(String? val) => _proposalId = val;

  bool hasProposalId() => _proposalId != null;

  static TrackUserAircraftStruct fromMap(Map<String, dynamic> data) =>
      TrackUserAircraftStruct(
        id: data['id'] as String?,
        proposalId: data['proposal_id'] as String?,
      );

  static TrackUserAircraftStruct? maybeFromMap(dynamic data) => data is Map
      ? TrackUserAircraftStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'proposal_id': _proposalId,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
        'proposal_id': serializeParam(
          _proposalId,
          ParamType.String,
        ),
      }.withoutNulls;

  static TrackUserAircraftStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      TrackUserAircraftStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
        proposalId: deserializeParam(
          data['proposal_id'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'TrackUserAircraftStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is TrackUserAircraftStruct &&
        id == other.id &&
        proposalId == other.proposalId;
  }

  @override
  int get hashCode => const ListEquality().hash([id, proposalId]);
}

TrackUserAircraftStruct createTrackUserAircraftStruct({
  String? id,
  String? proposalId,
}) =>
    TrackUserAircraftStruct(
      id: id,
      proposalId: proposalId,
    );
