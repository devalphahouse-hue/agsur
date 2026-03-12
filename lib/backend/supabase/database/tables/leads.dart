import '../database.dart';

class LeadsTable extends SupabaseTable<LeadsRow> {
  @override
  String get tableName => 'leads';

  @override
  LeadsRow createRow(Map<String, dynamic> data) => LeadsRow(data);
}

class LeadsRow extends SupabaseDataRow {
  LeadsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => LeadsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  String get lastName => getField<String>('last_name')!;
  set lastName(String value) => setField<String>('last_name', value);

  String get cpf => getField<String>('cpf')!;
  set cpf(String value) => setField<String>('cpf', value);

  String get email => getField<String>('email')!;
  set email(String value) => setField<String>('email', value);

  String get phone => getField<String>('phone')!;
  set phone(String value) => setField<String>('phone', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get sellerId => getField<String>('seller_id');
  set sellerId(String? value) => setField<String>('seller_id', value);

  String get city => getField<String>('city')!;
  set city(String value) => setField<String>('city', value);

  String get state => getField<String>('state')!;
  set state(String value) => setField<String>('state', value);

  bool get active => getField<bool>('active')!;
  set active(bool value) => setField<bool>('active', value);

  String get createdBy => getField<String>('created_by')!;
  set createdBy(String value) => setField<String>('created_by', value);

  String? get fullname => getField<String>('fullname');
  set fullname(String? value) => setField<String>('fullname', value);

  bool get isDeleted => getField<bool>('is_deleted')!;
  set isDeleted(bool value) => setField<bool>('is_deleted', value);

  String? get jobTitle => getField<String>('job_title');
  set jobTitle(String? value) => setField<String>('job_title', value);

  String? get companyName => getField<String>('company_name');
  set companyName(String? value) => setField<String>('company_name', value);
}
