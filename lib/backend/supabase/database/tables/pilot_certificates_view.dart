import '../database.dart';

class PilotCertificatesViewTable
    extends SupabaseTable<PilotCertificatesViewRow> {
  @override
  String get tableName => 'pilot_certificates_view';

  @override
  PilotCertificatesViewRow createRow(Map<String, dynamic> data) =>
      PilotCertificatesViewRow(data);
}

class PilotCertificatesViewRow extends SupabaseDataRow {
  PilotCertificatesViewRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PilotCertificatesViewTable();

  String? get certificateName => getField<String>('certificate_name');
  set certificateName(String? value) =>
      setField<String>('certificate_name', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get lastname => getField<String>('lastname');
  set lastname(String? value) => setField<String>('lastname', value);

  String? get fullname => getField<String>('fullname');
  set fullname(String? value) => setField<String>('fullname', value);

  int? get id => getField<int>('id');
  set id(int? value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  int? get certificateId => getField<int>('certificate_id');
  set certificateId(int? value) => setField<int>('certificate_id', value);

  DateTime? get validity => getField<DateTime>('validity');
  set validity(DateTime? value) => setField<DateTime>('validity', value);

  String? get docUrl => getField<String>('doc_url');
  set docUrl(String? value) => setField<String>('doc_url', value);

  bool? get isDeleted => getField<bool>('is_deleted');
  set isDeleted(bool? value) => setField<bool>('is_deleted', value);
}
