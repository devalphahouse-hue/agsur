// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class GetAircraftDetailsForProposalStruct extends BaseStruct {
  GetAircraftDetailsForProposalStruct({
    String? id,
    String? aircraftModel,
    String? aircraftYear,
    String? aircraftDescription,
    String? aircraftPhotoUrl,
    double? hopper,
    double? price,
    List<ItemsSeriesStruct>? itemsSeries,
  })  : _id = id,
        _aircraftModel = aircraftModel,
        _aircraftYear = aircraftYear,
        _aircraftDescription = aircraftDescription,
        _aircraftPhotoUrl = aircraftPhotoUrl,
        _hopper = hopper,
        _price = price,
        _itemsSeries = itemsSeries;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

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

  // "aircraft_photo_url" field.
  String? _aircraftPhotoUrl;
  String get aircraftPhotoUrl => _aircraftPhotoUrl ?? '';
  set aircraftPhotoUrl(String? val) => _aircraftPhotoUrl = val;

  bool hasAircraftPhotoUrl() => _aircraftPhotoUrl != null;

  // "hopper" field.
  double? _hopper;
  double get hopper => _hopper ?? 0.0;
  set hopper(double? val) => _hopper = val;

  void incrementHopper(double amount) => hopper = hopper + amount;

  bool hasHopper() => _hopper != null;

  // "price" field.
  double? _price;
  double get price => _price ?? 0.0;
  set price(double? val) => _price = val;

  void incrementPrice(double amount) => price = price + amount;

  bool hasPrice() => _price != null;

  // "items_series" field.
  List<ItemsSeriesStruct>? _itemsSeries;
  List<ItemsSeriesStruct> get itemsSeries => _itemsSeries ?? const [];
  set itemsSeries(List<ItemsSeriesStruct>? val) => _itemsSeries = val;

  void updateItemsSeries(Function(List<ItemsSeriesStruct>) updateFn) {
    updateFn(_itemsSeries ??= []);
  }

  bool hasItemsSeries() => _itemsSeries != null;

  static GetAircraftDetailsForProposalStruct fromMap(
          Map<String, dynamic> data) =>
      GetAircraftDetailsForProposalStruct(
        id: data['id'] as String?,
        aircraftModel: data['aircraft_model'] as String?,
        aircraftYear: data['aircraft_year'] as String?,
        aircraftDescription: data['aircraft_description'] as String?,
        aircraftPhotoUrl: data['aircraft_photo_url'] as String?,
        hopper: castToType<double>(data['hopper']),
        price: castToType<double>(data['price']),
        itemsSeries: getStructList(
          data['items_series'],
          ItemsSeriesStruct.fromMap,
        ),
      );

  static GetAircraftDetailsForProposalStruct? maybeFromMap(dynamic data) =>
      data is Map
          ? GetAircraftDetailsForProposalStruct.fromMap(
              data.cast<String, dynamic>())
          : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'aircraft_model': _aircraftModel,
        'aircraft_year': _aircraftYear,
        'aircraft_description': _aircraftDescription,
        'aircraft_photo_url': _aircraftPhotoUrl,
        'hopper': _hopper,
        'price': _price,
        'items_series': _itemsSeries?.map((e) => e.toMap()).toList(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
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
        'aircraft_photo_url': serializeParam(
          _aircraftPhotoUrl,
          ParamType.String,
        ),
        'hopper': serializeParam(
          _hopper,
          ParamType.double,
        ),
        'price': serializeParam(
          _price,
          ParamType.double,
        ),
        'items_series': serializeParam(
          _itemsSeries,
          ParamType.DataStruct,
          isList: true,
        ),
      }.withoutNulls;

  static GetAircraftDetailsForProposalStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      GetAircraftDetailsForProposalStruct(
        id: deserializeParam(
          data['id'],
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
        aircraftPhotoUrl: deserializeParam(
          data['aircraft_photo_url'],
          ParamType.String,
          false,
        ),
        hopper: deserializeParam(
          data['hopper'],
          ParamType.double,
          false,
        ),
        price: deserializeParam(
          data['price'],
          ParamType.double,
          false,
        ),
        itemsSeries: deserializeStructParam<ItemsSeriesStruct>(
          data['items_series'],
          ParamType.DataStruct,
          true,
          structBuilder: ItemsSeriesStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'GetAircraftDetailsForProposalStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is GetAircraftDetailsForProposalStruct &&
        id == other.id &&
        aircraftModel == other.aircraftModel &&
        aircraftYear == other.aircraftYear &&
        aircraftDescription == other.aircraftDescription &&
        aircraftPhotoUrl == other.aircraftPhotoUrl &&
        hopper == other.hopper &&
        price == other.price &&
        listEquality.equals(itemsSeries, other.itemsSeries);
  }

  @override
  int get hashCode => const ListEquality().hash([
        id,
        aircraftModel,
        aircraftYear,
        aircraftDescription,
        aircraftPhotoUrl,
        hopper,
        price,
        itemsSeries
      ]);
}

GetAircraftDetailsForProposalStruct createGetAircraftDetailsForProposalStruct({
  String? id,
  String? aircraftModel,
  String? aircraftYear,
  String? aircraftDescription,
  String? aircraftPhotoUrl,
  double? hopper,
  double? price,
}) =>
    GetAircraftDetailsForProposalStruct(
      id: id,
      aircraftModel: aircraftModel,
      aircraftYear: aircraftYear,
      aircraftDescription: aircraftDescription,
      aircraftPhotoUrl: aircraftPhotoUrl,
      hopper: hopper,
      price: price,
    );
