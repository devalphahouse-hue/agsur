import '../database.dart';

class VwMyAircraftDetailsTable extends SupabaseTable<VwMyAircraftDetailsRow> {
  @override
  String get tableName => 'vw_my_aircraft_details';

  @override
  VwMyAircraftDetailsRow createRow(Map<String, dynamic> data) =>
      VwMyAircraftDetailsRow(data);
}

class VwMyAircraftDetailsRow extends SupabaseDataRow {
  VwMyAircraftDetailsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VwMyAircraftDetailsTable();

  String? get aircraftId => getField<String>('aircraft_id');
  set aircraftId(String? value) => setField<String>('aircraft_id', value);

  String? get aircraftPhotoUrl => getField<String>('aircraft_photo_url');
  set aircraftPhotoUrl(String? value) =>
      setField<String>('aircraft_photo_url', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get aircraftDescription => getField<String>('aircraft_description');
  set aircraftDescription(String? value) =>
      setField<String>('aircraft_description', value);

  double? get hopper => getField<double>('hopper');
  set hopper(double? value) => setField<double>('hopper', value);

  double? get price => getField<double>('price');
  set price(double? value) => setField<double>('price', value);

  dynamic? get flightManuals => getField<dynamic>('flight_manuals');
  set flightManuals(dynamic? value) =>
      setField<dynamic>('flight_manuals', value);

  dynamic? get ownerManuals => getField<dynamic>('owner_manuals');
  set ownerManuals(dynamic? value) => setField<dynamic>('owner_manuals', value);

  dynamic? get partsManuals => getField<dynamic>('parts_manuals');
  set partsManuals(dynamic? value) => setField<dynamic>('parts_manuals', value);

  dynamic? get itemsSeries => getField<dynamic>('items_series');
  set itemsSeries(dynamic? value) => setField<dynamic>('items_series', value);
}
