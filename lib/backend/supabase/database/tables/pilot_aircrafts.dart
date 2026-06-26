import '../database.dart';

class PilotAircraftsTable extends SupabaseTable<PilotAircraftsRow> {
  @override
  String get tableName => 'pilot_aircrafts';

  @override
  PilotAircraftsRow createRow(Map<String, dynamic> data) =>
      PilotAircraftsRow(data);
}

class PilotAircraftsRow extends SupabaseDataRow {
  PilotAircraftsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PilotAircraftsTable();

  String get pilotId => getField<String>('pilot_id')!;
  set pilotId(String value) => setField<String>('pilot_id', value);

  String get aircraftId => getField<String>('aircraft_id')!;
  set aircraftId(String value) => setField<String>('aircraft_id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);
}
