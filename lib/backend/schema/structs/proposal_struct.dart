// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ProposalStruct extends BaseStruct {
  ProposalStruct({
    String? id,
    String? leadId,
    String? aircraftId,
    double? fullprice,
    String? createdAt,
    String? createdBy,
    String? idRef,
  })  : _id = id,
        _leadId = leadId,
        _aircraftId = aircraftId,
        _fullprice = fullprice,
        _createdAt = createdAt,
        _createdBy = createdBy,
        _idRef = idRef;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  // "lead_id" field.
  String? _leadId;
  String get leadId => _leadId ?? '';
  set leadId(String? val) => _leadId = val;

  bool hasLeadId() => _leadId != null;

  // "aircraft_id" field.
  String? _aircraftId;
  String get aircraftId => _aircraftId ?? '';
  set aircraftId(String? val) => _aircraftId = val;

  bool hasAircraftId() => _aircraftId != null;

  // "fullprice" field.
  double? _fullprice;
  double get fullprice => _fullprice ?? 0.0;
  set fullprice(double? val) => _fullprice = val;

  void incrementFullprice(double amount) => fullprice = fullprice + amount;

  bool hasFullprice() => _fullprice != null;

  // "created_at" field.
  String? _createdAt;
  String get createdAt => _createdAt ?? '';
  set createdAt(String? val) => _createdAt = val;

  bool hasCreatedAt() => _createdAt != null;

  // "created_by" field.
  String? _createdBy;
  String get createdBy => _createdBy ?? '';
  set createdBy(String? val) => _createdBy = val;

  bool hasCreatedBy() => _createdBy != null;

  // "id_ref" field.
  String? _idRef;
  String get idRef => _idRef ?? '';
  set idRef(String? val) => _idRef = val;

  bool hasIdRef() => _idRef != null;

  static ProposalStruct fromMap(Map<String, dynamic> data) => ProposalStruct(
        id: data['id'] as String?,
        leadId: data['lead_id'] as String?,
        aircraftId: data['aircraft_id'] as String?,
        fullprice: castToType<double>(data['fullprice']),
        createdAt: data['created_at'] as String?,
        createdBy: data['created_by'] as String?,
        idRef: data['id_ref'] as String?,
      );

  static ProposalStruct? maybeFromMap(dynamic data) =>
      data is Map ? ProposalStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'lead_id': _leadId,
        'aircraft_id': _aircraftId,
        'fullprice': _fullprice,
        'created_at': _createdAt,
        'created_by': _createdBy,
        'id_ref': _idRef,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
        'lead_id': serializeParam(
          _leadId,
          ParamType.String,
        ),
        'aircraft_id': serializeParam(
          _aircraftId,
          ParamType.String,
        ),
        'fullprice': serializeParam(
          _fullprice,
          ParamType.double,
        ),
        'created_at': serializeParam(
          _createdAt,
          ParamType.String,
        ),
        'created_by': serializeParam(
          _createdBy,
          ParamType.String,
        ),
        'id_ref': serializeParam(
          _idRef,
          ParamType.String,
        ),
      }.withoutNulls;

  static ProposalStruct fromSerializableMap(Map<String, dynamic> data) =>
      ProposalStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
        leadId: deserializeParam(
          data['lead_id'],
          ParamType.String,
          false,
        ),
        aircraftId: deserializeParam(
          data['aircraft_id'],
          ParamType.String,
          false,
        ),
        fullprice: deserializeParam(
          data['fullprice'],
          ParamType.double,
          false,
        ),
        createdAt: deserializeParam(
          data['created_at'],
          ParamType.String,
          false,
        ),
        createdBy: deserializeParam(
          data['created_by'],
          ParamType.String,
          false,
        ),
        idRef: deserializeParam(
          data['id_ref'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'ProposalStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ProposalStruct &&
        id == other.id &&
        leadId == other.leadId &&
        aircraftId == other.aircraftId &&
        fullprice == other.fullprice &&
        createdAt == other.createdAt &&
        createdBy == other.createdBy &&
        idRef == other.idRef;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([id, leadId, aircraftId, fullprice, createdAt, createdBy, idRef]);
}

ProposalStruct createProposalStruct({
  String? id,
  String? leadId,
  String? aircraftId,
  double? fullprice,
  String? createdAt,
  String? createdBy,
  String? idRef,
}) =>
    ProposalStruct(
      id: id,
      leadId: leadId,
      aircraftId: aircraftId,
      fullprice: fullprice,
      createdAt: createdAt,
      createdBy: createdBy,
      idRef: idRef,
    );
