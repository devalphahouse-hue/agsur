import '../database.dart';

class RequestedPartsTable extends SupabaseTable<RequestedPartsRow> {
  @override
  String get tableName => 'requested_parts';

  @override
  RequestedPartsRow createRow(Map<String, dynamic> data) =>
      RequestedPartsRow(data);
}

class RequestedPartsRow extends SupabaseDataRow {
  RequestedPartsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => RequestedPartsTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String get pn => getField<String>('pn')!;
  set pn(String value) => setField<String>('pn', value);

  int get qty => getField<int>('qty')!;
  set qty(int value) => setField<int>('qty', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  String get orderId => getField<String>('order_id')!;
  set orderId(String value) => setField<String>('order_id', value);
}
