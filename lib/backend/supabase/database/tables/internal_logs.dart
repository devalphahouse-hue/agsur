import '../database.dart';

class InternalLogsTable extends SupabaseTable<InternalLogsRow> {
  @override
  String get tableName => 'internal_logs';

  @override
  InternalLogsRow createRow(Map<String, dynamic> data) => InternalLogsRow(data);
}

class InternalLogsRow extends SupabaseDataRow {
  InternalLogsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => InternalLogsTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get logType => getField<String>('log_type');
  set logType(String? value) => setField<String>('log_type', value);
}
