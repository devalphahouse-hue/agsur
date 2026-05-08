import '../database.dart';

class OficinaClientsTable extends SupabaseTable<OficinaClientsRow> {
  @override
  String get tableName => 'oficina_clients';

  @override
  OficinaClientsRow createRow(Map<String, dynamic> data) =>
      OficinaClientsRow(data);
}

class OficinaClientsRow extends SupabaseDataRow {
  OficinaClientsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => OficinaClientsTable();

  String get oficinaId => getField<String>('oficina_id')!;
  set oficinaId(String value) => setField<String>('oficina_id', value);

  String get clientId => getField<String>('client_id')!;
  set clientId(String value) => setField<String>('client_id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);
}
