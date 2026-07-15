import '../database.dart';

// Escrito à mão (não-FlutterFlow) — vínculo N:N item ↔ aeronave
// (migration 20260714130000). Revalidar após regen do FlutterFlow.
class AircraftItemLinksTable extends SupabaseTable<AircraftItemLinksRow> {
  @override
  String get tableName => 'aircraft_item_links';

  @override
  AircraftItemLinksRow createRow(Map<String, dynamic> data) =>
      AircraftItemLinksRow(data);
}

class AircraftItemLinksRow extends SupabaseDataRow {
  AircraftItemLinksRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AircraftItemLinksTable();

  String get aircraftItemId => getField<String>('aircraft_item_id')!;
  set aircraftItemId(String value) =>
      setField<String>('aircraft_item_id', value);

  String get aircraftId => getField<String>('aircraft_id')!;
  set aircraftId(String value) => setField<String>('aircraft_id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);
}
