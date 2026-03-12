import '../database.dart';

class OrderPartsTable extends SupabaseTable<OrderPartsRow> {
  @override
  String get tableName => 'order_parts';

  @override
  OrderPartsRow createRow(Map<String, dynamic> data) => OrderPartsRow(data);
}

class OrderPartsRow extends SupabaseDataRow {
  OrderPartsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => OrderPartsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get status => getField<String>('status')!;
  set status(String value) => setField<String>('status', value);
}
