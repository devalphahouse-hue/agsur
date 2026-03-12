import '../database.dart';

class AircraftDocumentsTable extends SupabaseTable<AircraftDocumentsRow> {
  @override
  String get tableName => 'aircraft_documents';

  @override
  AircraftDocumentsRow createRow(Map<String, dynamic> data) =>
      AircraftDocumentsRow(data);
}

class AircraftDocumentsRow extends SupabaseDataRow {
  AircraftDocumentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AircraftDocumentsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userAircraftId => getField<String>('user_aircraft_id')!;
  set userAircraftId(String value) =>
      setField<String>('user_aircraft_id', value);

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
}
