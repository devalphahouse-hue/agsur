import '../database.dart';

class VwAircraftOptionsTable extends SupabaseTable<VwAircraftOptionsRow> {
  @override
  String get tableName => 'vw_aircraft_options';

  @override
  VwAircraftOptionsRow createRow(Map<String, dynamic> data) =>
      VwAircraftOptionsRow(data);
}

class VwAircraftOptionsRow extends SupabaseDataRow {
  VwAircraftOptionsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VwAircraftOptionsTable();

  String? get aircraftId => getField<String>('aircraft_id');
  set aircraftId(String? value) => setField<String>('aircraft_id', value);

  String? get aircraftModel => getField<String>('aircraft_model');
  set aircraftModel(String? value) =>
      setField<String>('aircraft_model', value);

  String? get aircraftPhotoUrl => getField<String>('aircraft_photo_url');
  set aircraftPhotoUrl(String? value) =>
      setField<String>('aircraft_photo_url', value);
}
