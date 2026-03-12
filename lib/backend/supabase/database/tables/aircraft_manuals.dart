import '../database.dart';

class AircraftManualsTable extends SupabaseTable<AircraftManualsRow> {
  @override
  String get tableName => 'aircraft_manuals';

  @override
  AircraftManualsRow createRow(Map<String, dynamic> data) =>
      AircraftManualsRow(data);
}

class AircraftManualsRow extends SupabaseDataRow {
  AircraftManualsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AircraftManualsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get aircraftId => getField<String>('aircraft_id')!;
  set aircraftId(String value) => setField<String>('aircraft_id', value);

  String get documentionName => getField<String>('documention_name')!;
  set documentionName(String value) =>
      setField<String>('documention_name', value);

  String get documentionUrl => getField<String>('documention_url')!;
  set documentionUrl(String value) =>
      setField<String>('documention_url', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  bool get deleted => getField<bool>('deleted')!;
  set deleted(bool value) => setField<bool>('deleted', value);

  String get type => getField<String>('type')!;
  set type(String value) => setField<String>('type', value);
}
