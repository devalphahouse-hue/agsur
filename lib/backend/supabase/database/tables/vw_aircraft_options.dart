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

  String? get userAircraftId => getField<String>('user_aircraft_id');
  set userAircraftId(String? value) =>
      setField<String>('user_aircraft_id', value);

  String? get aircraftModel => getField<String>('aircraft_model');
  set aircraftModel(String? value) =>
      setField<String>('aircraft_model', value);

  String? get aircraftPhotoUrl => getField<String>('aircraft_photo_url');
  set aircraftPhotoUrl(String? value) =>
      setField<String>('aircraft_photo_url', value);

  String? get ownerId => getField<String>('owner_id');
  set ownerId(String? value) => setField<String>('owner_id', value);

  String? get ownerName => getField<String>('owner_name');
  set ownerName(String? value) => setField<String>('owner_name', value);
}
