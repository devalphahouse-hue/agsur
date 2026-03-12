import '../database.dart';

class CertificatesTable extends SupabaseTable<CertificatesRow> {
  @override
  String get tableName => 'certificates';

  @override
  CertificatesRow createRow(Map<String, dynamic> data) => CertificatesRow(data);
}

class CertificatesRow extends SupabaseDataRow {
  CertificatesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CertificatesTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get certificateName => getField<String>('certificate_name');
  set certificateName(String? value) =>
      setField<String>('certificate_name', value);

  bool get isDeleted => getField<bool>('is_deleted')!;
  set isDeleted(bool value) => setField<bool>('is_deleted', value);
}
