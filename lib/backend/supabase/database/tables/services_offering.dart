import '../database.dart';

class ServicesOfferingTable extends SupabaseTable<ServicesOfferingRow> {
  @override
  String get tableName => 'services_offering';

  @override
  ServicesOfferingRow createRow(Map<String, dynamic> data) =>
      ServicesOfferingRow(data);
}

class ServicesOfferingRow extends SupabaseDataRow {
  ServicesOfferingRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ServicesOfferingTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get serviceTitle => getField<String>('service_title')!;
  set serviceTitle(String value) => setField<String>('service_title', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String get docUrl => getField<String>('doc_url')!;
  set docUrl(String value) => setField<String>('doc_url', value);

  String get type => getField<String>('type')!;
  set type(String value) => setField<String>('type', value);

  String? get models => getField<String>('models');
  set models(String? value) => setField<String>('models', value);

  bool get isDeleted => getField<bool>('is_deleted')!;
  set isDeleted(bool value) => setField<bool>('is_deleted', value);
}
