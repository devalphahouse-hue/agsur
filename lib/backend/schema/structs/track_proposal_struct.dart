// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TrackProposalStruct extends BaseStruct {
  TrackProposalStruct({
    String? id,
    String? idRef,
    String? leadId,
  })  : _id = id,
        _idRef = idRef,
        _leadId = leadId;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  // "id_ref" field.
  String? _idRef;
  String get idRef => _idRef ?? '';
  set idRef(String? val) => _idRef = val;

  bool hasIdRef() => _idRef != null;

  // "lead_id" field.
  String? _leadId;
  String get leadId => _leadId ?? '';
  set leadId(String? val) => _leadId = val;

  bool hasLeadId() => _leadId != null;

  static TrackProposalStruct fromMap(Map<String, dynamic> data) =>
      TrackProposalStruct(
        id: data['id'] as String?,
        idRef: data['id_ref'] as String?,
        leadId: data['lead_id'] as String?,
      );

  static TrackProposalStruct? maybeFromMap(dynamic data) => data is Map
      ? TrackProposalStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'id_ref': _idRef,
        'lead_id': _leadId,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
        'id_ref': serializeParam(
          _idRef,
          ParamType.String,
        ),
        'lead_id': serializeParam(
          _leadId,
          ParamType.String,
        ),
      }.withoutNulls;

  static TrackProposalStruct fromSerializableMap(Map<String, dynamic> data) =>
      TrackProposalStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
        idRef: deserializeParam(
          data['id_ref'],
          ParamType.String,
          false,
        ),
        leadId: deserializeParam(
          data['lead_id'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'TrackProposalStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is TrackProposalStruct &&
        id == other.id &&
        idRef == other.idRef &&
        leadId == other.leadId;
  }

  @override
  int get hashCode => const ListEquality().hash([id, idRef, leadId]);
}

TrackProposalStruct createTrackProposalStruct({
  String? id,
  String? idRef,
  String? leadId,
}) =>
    TrackProposalStruct(
      id: id,
      idRef: idRef,
      leadId: leadId,
    );
