// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ListAvailableAircraftsStruct extends BaseStruct {
  ListAvailableAircraftsStruct({
    String? id,
    String? aircraftModelId,
    String? serialNumber,
    String? manufactureDate,
    String? configurationDeadline,
    String? deliveryDate,
    String? status,
    String? createdAt,
    String? createdBy,
    String? updateBy,
    String? entryYear,
    String? aircraftId,
    String? aircraftModel,
    String? aircraftPhotoUrl,
  })  : _id = id,
        _aircraftModelId = aircraftModelId,
        _serialNumber = serialNumber,
        _manufactureDate = manufactureDate,
        _configurationDeadline = configurationDeadline,
        _deliveryDate = deliveryDate,
        _status = status,
        _createdAt = createdAt,
        _createdBy = createdBy,
        _updateBy = updateBy,
        _entryYear = entryYear,
        _aircraftId = aircraftId,
        _aircraftModel = aircraftModel,
        _aircraftPhotoUrl = aircraftPhotoUrl;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  // "aircraft_model_id" field.
  String? _aircraftModelId;
  String get aircraftModelId => _aircraftModelId ?? '';
  set aircraftModelId(String? val) => _aircraftModelId = val;

  bool hasAircraftModelId() => _aircraftModelId != null;

  // "serial_number" field.
  String? _serialNumber;
  String get serialNumber => _serialNumber ?? '';
  set serialNumber(String? val) => _serialNumber = val;

  bool hasSerialNumber() => _serialNumber != null;

  // "manufacture_date" field.
  String? _manufactureDate;
  String get manufactureDate => _manufactureDate ?? '';
  set manufactureDate(String? val) => _manufactureDate = val;

  bool hasManufactureDate() => _manufactureDate != null;

  // "configuration_deadline" field.
  String? _configurationDeadline;
  String get configurationDeadline => _configurationDeadline ?? '';
  set configurationDeadline(String? val) => _configurationDeadline = val;

  bool hasConfigurationDeadline() => _configurationDeadline != null;

  // "delivery_date" field.
  String? _deliveryDate;
  String get deliveryDate => _deliveryDate ?? '';
  set deliveryDate(String? val) => _deliveryDate = val;

  bool hasDeliveryDate() => _deliveryDate != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  set status(String? val) => _status = val;

  bool hasStatus() => _status != null;

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

  // "update_by" field.
  String? _updateBy;
  String get updateBy => _updateBy ?? '';
  set updateBy(String? val) => _updateBy = val;

  bool hasUpdateBy() => _updateBy != null;

  // "entry_year" field.
  String? _entryYear;
  String get entryYear => _entryYear ?? '';
  set entryYear(String? val) => _entryYear = val;

  bool hasEntryYear() => _entryYear != null;

  // "aircraft_id" field.
  String? _aircraftId;
  String get aircraftId => _aircraftId ?? '';
  set aircraftId(String? val) => _aircraftId = val;

  bool hasAircraftId() => _aircraftId != null;

  // "aircraft_model" field.
  String? _aircraftModel;
  String get aircraftModel => _aircraftModel ?? '';
  set aircraftModel(String? val) => _aircraftModel = val;

  bool hasAircraftModel() => _aircraftModel != null;

  // "aircraft_photo_url" field.
  String? _aircraftPhotoUrl;
  String get aircraftPhotoUrl => _aircraftPhotoUrl ?? '';
  set aircraftPhotoUrl(String? val) => _aircraftPhotoUrl = val;

  bool hasAircraftPhotoUrl() => _aircraftPhotoUrl != null;

  static ListAvailableAircraftsStruct fromMap(Map<String, dynamic> data) =>
      ListAvailableAircraftsStruct(
        id: data['id'] as String?,
        aircraftModelId: data['aircraft_model_id'] as String?,
        serialNumber: data['serial_number'] as String?,
        manufactureDate: data['manufacture_date'] as String?,
        configurationDeadline: data['configuration_deadline'] as String?,
        deliveryDate: data['delivery_date'] as String?,
        status: data['status'] as String?,
        createdAt: data['created_at'] as String?,
        createdBy: data['created_by'] as String?,
        updateBy: data['update_by'] as String?,
        entryYear: data['entry_year'] as String?,
        aircraftId: data['aircraft_id'] as String?,
        aircraftModel: data['aircraft_model'] as String?,
        aircraftPhotoUrl: data['aircraft_photo_url'] as String?,
      );

  static ListAvailableAircraftsStruct? maybeFromMap(dynamic data) => data is Map
      ? ListAvailableAircraftsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'aircraft_model_id': _aircraftModelId,
        'serial_number': _serialNumber,
        'manufacture_date': _manufactureDate,
        'configuration_deadline': _configurationDeadline,
        'delivery_date': _deliveryDate,
        'status': _status,
        'created_at': _createdAt,
        'created_by': _createdBy,
        'update_by': _updateBy,
        'entry_year': _entryYear,
        'aircraft_id': _aircraftId,
        'aircraft_model': _aircraftModel,
        'aircraft_photo_url': _aircraftPhotoUrl,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
        'aircraft_model_id': serializeParam(
          _aircraftModelId,
          ParamType.String,
        ),
        'serial_number': serializeParam(
          _serialNumber,
          ParamType.String,
        ),
        'manufacture_date': serializeParam(
          _manufactureDate,
          ParamType.String,
        ),
        'configuration_deadline': serializeParam(
          _configurationDeadline,
          ParamType.String,
        ),
        'delivery_date': serializeParam(
          _deliveryDate,
          ParamType.String,
        ),
        'status': serializeParam(
          _status,
          ParamType.String,
        ),
        'created_at': serializeParam(
          _createdAt,
          ParamType.String,
        ),
        'created_by': serializeParam(
          _createdBy,
          ParamType.String,
        ),
        'update_by': serializeParam(
          _updateBy,
          ParamType.String,
        ),
        'entry_year': serializeParam(
          _entryYear,
          ParamType.String,
        ),
        'aircraft_id': serializeParam(
          _aircraftId,
          ParamType.String,
        ),
        'aircraft_model': serializeParam(
          _aircraftModel,
          ParamType.String,
        ),
        'aircraft_photo_url': serializeParam(
          _aircraftPhotoUrl,
          ParamType.String,
        ),
      }.withoutNulls;

  static ListAvailableAircraftsStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      ListAvailableAircraftsStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
        aircraftModelId: deserializeParam(
          data['aircraft_model_id'],
          ParamType.String,
          false,
        ),
        serialNumber: deserializeParam(
          data['serial_number'],
          ParamType.String,
          false,
        ),
        manufactureDate: deserializeParam(
          data['manufacture_date'],
          ParamType.String,
          false,
        ),
        configurationDeadline: deserializeParam(
          data['configuration_deadline'],
          ParamType.String,
          false,
        ),
        deliveryDate: deserializeParam(
          data['delivery_date'],
          ParamType.String,
          false,
        ),
        status: deserializeParam(
          data['status'],
          ParamType.String,
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
        updateBy: deserializeParam(
          data['update_by'],
          ParamType.String,
          false,
        ),
        entryYear: deserializeParam(
          data['entry_year'],
          ParamType.String,
          false,
        ),
        aircraftId: deserializeParam(
          data['aircraft_id'],
          ParamType.String,
          false,
        ),
        aircraftModel: deserializeParam(
          data['aircraft_model'],
          ParamType.String,
          false,
        ),
        aircraftPhotoUrl: deserializeParam(
          data['aircraft_photo_url'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'ListAvailableAircraftsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ListAvailableAircraftsStruct &&
        id == other.id &&
        aircraftModelId == other.aircraftModelId &&
        serialNumber == other.serialNumber &&
        manufactureDate == other.manufactureDate &&
        configurationDeadline == other.configurationDeadline &&
        deliveryDate == other.deliveryDate &&
        status == other.status &&
        createdAt == other.createdAt &&
        createdBy == other.createdBy &&
        updateBy == other.updateBy &&
        entryYear == other.entryYear &&
        aircraftId == other.aircraftId &&
        aircraftModel == other.aircraftModel &&
        aircraftPhotoUrl == other.aircraftPhotoUrl;
  }

  @override
  int get hashCode => const ListEquality().hash([
        id,
        aircraftModelId,
        serialNumber,
        manufactureDate,
        configurationDeadline,
        deliveryDate,
        status,
        createdAt,
        createdBy,
        updateBy,
        entryYear,
        aircraftId,
        aircraftModel,
        aircraftPhotoUrl
      ]);
}

ListAvailableAircraftsStruct createListAvailableAircraftsStruct({
  String? id,
  String? aircraftModelId,
  String? serialNumber,
  String? manufactureDate,
  String? configurationDeadline,
  String? deliveryDate,
  String? status,
  String? createdAt,
  String? createdBy,
  String? updateBy,
  String? entryYear,
  String? aircraftId,
  String? aircraftModel,
  String? aircraftPhotoUrl,
}) =>
    ListAvailableAircraftsStruct(
      id: id,
      aircraftModelId: aircraftModelId,
      serialNumber: serialNumber,
      manufactureDate: manufactureDate,
      configurationDeadline: configurationDeadline,
      deliveryDate: deliveryDate,
      status: status,
      createdAt: createdAt,
      createdBy: createdBy,
      updateBy: updateBy,
      entryYear: entryYear,
      aircraftId: aircraftId,
      aircraftModel: aircraftModel,
      aircraftPhotoUrl: aircraftPhotoUrl,
    );
