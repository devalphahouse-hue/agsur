// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ProposalAircraftStruct extends BaseStruct {
  ProposalAircraftStruct({
    String? aircraftPhotoUrl,
    String? aircraftModel,
    String? aircraftYear,
    String? aircraftDescription,
    double? hopper,
  })  : _aircraftPhotoUrl = aircraftPhotoUrl,
        _aircraftModel = aircraftModel,
        _aircraftYear = aircraftYear,
        _aircraftDescription = aircraftDescription,
        _hopper = hopper;

  // "aircraft_photo_url" field.
  String? _aircraftPhotoUrl;
  String get aircraftPhotoUrl => _aircraftPhotoUrl ?? '';
  set aircraftPhotoUrl(String? val) => _aircraftPhotoUrl = val;

  bool hasAircraftPhotoUrl() => _aircraftPhotoUrl != null;

  // "aircraft_model" field.
  String? _aircraftModel;
  String get aircraftModel => _aircraftModel ?? '';
  set aircraftModel(String? val) => _aircraftModel = val;

  bool hasAircraftModel() => _aircraftModel != null;

  // "aircraft_year" field.
  String? _aircraftYear;
  String get aircraftYear => _aircraftYear ?? '';
  set aircraftYear(String? val) => _aircraftYear = val;

  bool hasAircraftYear() => _aircraftYear != null;

  // "aircraft_description" field.
  String? _aircraftDescription;
  String get aircraftDescription => _aircraftDescription ?? '';
  set aircraftDescription(String? val) => _aircraftDescription = val;

  bool hasAircraftDescription() => _aircraftDescription != null;

  // "hopper" field.
  double? _hopper;
  double get hopper => _hopper ?? 0.0;
  set hopper(double? val) => _hopper = val;

  void incrementHopper(double amount) => hopper = hopper + amount;

  bool hasHopper() => _hopper != null;

  static ProposalAircraftStruct fromMap(Map<String, dynamic> data) =>
      ProposalAircraftStruct(
        aircraftPhotoUrl: data['aircraft_photo_url'] as String?,
        aircraftModel: data['aircraft_model'] as String?,
        aircraftYear: data['aircraft_year'] as String?,
        aircraftDescription: data['aircraft_description'] as String?,
        hopper: castToType<double>(data['hopper']),
      );

  static ProposalAircraftStruct? maybeFromMap(dynamic data) => data is Map
      ? ProposalAircraftStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'aircraft_photo_url': _aircraftPhotoUrl,
        'aircraft_model': _aircraftModel,
        'aircraft_year': _aircraftYear,
        'aircraft_description': _aircraftDescription,
        'hopper': _hopper,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'aircraft_photo_url': serializeParam(
          _aircraftPhotoUrl,
          ParamType.String,
        ),
        'aircraft_model': serializeParam(
          _aircraftModel,
          ParamType.String,
        ),
        'aircraft_year': serializeParam(
          _aircraftYear,
          ParamType.String,
        ),
        'aircraft_description': serializeParam(
          _aircraftDescription,
          ParamType.String,
        ),
        'hopper': serializeParam(
          _hopper,
          ParamType.double,
        ),
      }.withoutNulls;

  static ProposalAircraftStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      ProposalAircraftStruct(
        aircraftPhotoUrl: deserializeParam(
          data['aircraft_photo_url'],
          ParamType.String,
          false,
        ),
        aircraftModel: deserializeParam(
          data['aircraft_model'],
          ParamType.String,
          false,
        ),
        aircraftYear: deserializeParam(
          data['aircraft_year'],
          ParamType.String,
          false,
        ),
        aircraftDescription: deserializeParam(
          data['aircraft_description'],
          ParamType.String,
          false,
        ),
        hopper: deserializeParam(
          data['hopper'],
          ParamType.double,
          false,
        ),
      );

  @override
  String toString() => 'ProposalAircraftStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ProposalAircraftStruct &&
        aircraftPhotoUrl == other.aircraftPhotoUrl &&
        aircraftModel == other.aircraftModel &&
        aircraftYear == other.aircraftYear &&
        aircraftDescription == other.aircraftDescription &&
        hopper == other.hopper;
  }

  @override
  int get hashCode => const ListEquality().hash([
        aircraftPhotoUrl,
        aircraftModel,
        aircraftYear,
        aircraftDescription,
        hopper
      ]);
}

ProposalAircraftStruct createProposalAircraftStruct({
  String? aircraftPhotoUrl,
  String? aircraftModel,
  String? aircraftYear,
  String? aircraftDescription,
  double? hopper,
}) =>
    ProposalAircraftStruct(
      aircraftPhotoUrl: aircraftPhotoUrl,
      aircraftModel: aircraftModel,
      aircraftYear: aircraftYear,
      aircraftDescription: aircraftDescription,
      hopper: hopper,
    );
