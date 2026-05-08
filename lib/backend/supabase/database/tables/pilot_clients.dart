import '../database.dart';

class PilotClientsTable extends SupabaseTable<PilotClientsRow> {
  @override
  String get tableName => 'pilot_clients';

  @override
  PilotClientsRow createRow(Map<String, dynamic> data) =>
      PilotClientsRow(data);
}

class PilotClientsRow extends SupabaseDataRow {
  PilotClientsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PilotClientsTable();

  String get pilotId => getField<String>('pilot_id')!;
  set pilotId(String value) => setField<String>('pilot_id', value);

  String get clientId => getField<String>('client_id')!;
  set clientId(String value) => setField<String>('client_id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);
}
