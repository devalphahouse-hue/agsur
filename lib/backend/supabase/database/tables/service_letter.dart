import '../database.dart';

class ServiceLetterTable extends SupabaseTable<ServiceLetterRow> {
  @override
  String get tableName => 'service_letter';

  @override
  ServiceLetterRow createRow(Map<String, dynamic> data) =>
      ServiceLetterRow(data);
}

class ServiceLetterRow extends SupabaseDataRow {
  ServiceLetterRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ServiceLetterTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get clientId => getField<String>('client_id')!;
  set clientId(String value) => setField<String>('client_id', value);

  String get title => getField<String>('title')!;
  set title(String value) => setField<String>('title', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  String get pdfUrl => getField<String>('pdf_url')!;
  set pdfUrl(String value) => setField<String>('pdf_url', value);

  bool get isDeleted => getField<bool>('is_deleted')!;
  set isDeleted(bool value) => setField<bool>('is_deleted', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);
}
