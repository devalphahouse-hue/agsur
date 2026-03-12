import '../database.dart';

class PilotCertificatesTable extends SupabaseTable<PilotCertificatesRow> {
  @override
  String get tableName => 'pilot_certificates';

  @override
  PilotCertificatesRow createRow(Map<String, dynamic> data) =>
      PilotCertificatesRow(data);
}

class PilotCertificatesRow extends SupabaseDataRow {
  PilotCertificatesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PilotCertificatesTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  int? get certificateId => getField<int>('certificate_id');
  set certificateId(int? value) => setField<int>('certificate_id', value);

  DateTime get validity => getField<DateTime>('validity')!;
  set validity(DateTime value) => setField<DateTime>('validity', value);

  String? get docUrl => getField<String>('doc_url');
  set docUrl(String? value) => setField<String>('doc_url', value);

  bool get isDeleted => getField<bool>('is_deleted')!;
  set isDeleted(bool value) => setField<bool>('is_deleted', value);
}
