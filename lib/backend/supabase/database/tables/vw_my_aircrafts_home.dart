import '../database.dart';

class VwMyAircraftsHomeTable extends SupabaseTable<VwMyAircraftsHomeRow> {
  @override
  String get tableName => 'vw_my_aircrafts_home';

  @override
  VwMyAircraftsHomeRow createRow(Map<String, dynamic> data) =>
      VwMyAircraftsHomeRow(data);
}

class VwMyAircraftsHomeRow extends SupabaseDataRow {
  VwMyAircraftsHomeRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VwMyAircraftsHomeTable();

  String? get userAircraftId => getField<String>('user_aircraft_id');
  set userAircraftId(String? value) =>
      setField<String>('user_aircraft_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get aircraftPhotoUrl => getField<String>('aircraft_photo_url');
  set aircraftPhotoUrl(String? value) =>
      setField<String>('aircraft_photo_url', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  double? get hopper => getField<double>('hopper');
  set hopper(double? value) => setField<double>('hopper', value);

  double? get price => getField<double>('price');
  set price(double? value) => setField<double>('price', value);
}
