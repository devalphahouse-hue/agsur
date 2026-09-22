import '../database.dart';

// Escrito à mão (não-FlutterFlow) — log de alteração de campos da unidade do
// estoque, preenchido por trigger (migration 20260922120000). `changes` é
// `{"coluna": {"old": ..., "new": ...}}` no update e o snapshot no insert.
// Somente leitura. Revalidar após regen do FlutterFlow.
class AvailableAircraftLogsTable
    extends SupabaseTable<AvailableAircraftLogsRow> {
  @override
  String get tableName => 'available_aircraft_logs';

  @override
  AvailableAircraftLogsRow createRow(Map<String, dynamic> data) =>
      AvailableAircraftLogsRow(data);
}

class AvailableAircraftLogsRow extends SupabaseDataRow {
  AvailableAircraftLogsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AvailableAircraftLogsTable();

  String get id => getField<String>('id')!;
  String get availableAircraftId => getField<String>('available_aircraft_id')!;

  /// `insert` ou `update`.
  String get action => getField<String>('action')!;
  Map<String, dynamic> get changes =>
      (data['changes'] as Map?)?.cast<String, dynamic>() ?? const {};
  String? get changedBy => getField<String>('changed_by');
  DateTime get changedAt => getField<DateTime>('changed_at')!;
}
