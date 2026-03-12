import '../database.dart';

class AircraftsTable extends SupabaseTable<AircraftsRow> {
  @override
  String get tableName => 'aircrafts';

  @override
  AircraftsRow createRow(Map<String, dynamic> data) => AircraftsRow(data);
}

class AircraftsRow extends SupabaseDataRow {
  AircraftsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AircraftsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get aircraftModel => getField<String>('aircraft_model')!;
  set aircraftModel(String value) => setField<String>('aircraft_model', value);

  String get aircraftYear => getField<String>('aircraft_year')!;
  set aircraftYear(String value) => setField<String>('aircraft_year', value);

  String get aircraftDescription => getField<String>('aircraft_description')!;
  set aircraftDescription(String value) =>
      setField<String>('aircraft_description', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  bool get deleted => getField<bool>('deleted')!;
  set deleted(bool value) => setField<bool>('deleted', value);

  String get aircraftPhotoUrl => getField<String>('aircraft_photo_url')!;
  set aircraftPhotoUrl(String value) =>
      setField<String>('aircraft_photo_url', value);

  double get hopper => getField<double>('hopper')!;
  set hopper(double value) => setField<double>('hopper', value);

  double get price => getField<double>('price')!;
  set price(double value) => setField<double>('price', value);

  bool get active => getField<bool>('active')!;
  set active(bool value) => setField<bool>('active', value);

  String get createdBy => getField<String>('created_by')!;
  set createdBy(String value) => setField<String>('created_by', value);
}
