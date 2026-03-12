import '../database.dart';

class UsersTable extends SupabaseTable<UsersRow> {
  @override
  String get tableName => 'users';

  @override
  UsersRow createRow(Map<String, dynamic> data) => UsersRow(data);
}

class UsersRow extends SupabaseDataRow {
  UsersRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UsersTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  String get email => getField<String>('email')!;
  set email(String value) => setField<String>('email', value);

  String? get profilePhotoUrl => getField<String>('profile_photo_url');
  set profilePhotoUrl(String? value) =>
      setField<String>('profile_photo_url', value);

  String get phone => getField<String>('phone')!;
  set phone(String value) => setField<String>('phone', value);

  String get profileType => getField<String>('profile_type')!;
  set profileType(String value) => setField<String>('profile_type', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  bool get isActive => getField<bool>('is_active')!;
  set isActive(bool value) => setField<bool>('is_active', value);

  bool get isDeleted => getField<bool>('is_deleted')!;
  set isDeleted(bool value) => setField<bool>('is_deleted', value);

  bool get isAdmin => getField<bool>('is_admin')!;
  set isAdmin(bool value) => setField<bool>('is_admin', value);

  String? get deviceToken => getField<String>('device_token');
  set deviceToken(String? value) => setField<String>('device_token', value);

  String get cpf => getField<String>('cpf')!;
  set cpf(String value) => setField<String>('cpf', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get lastname => getField<String>('lastname');
  set lastname(String? value) => setField<String>('lastname', value);

  String? get fullname => getField<String>('fullname');
  set fullname(String? value) => setField<String>('fullname', value);

  String? get leadId => getField<String>('lead_id');
  set leadId(String? value) => setField<String>('lead_id', value);

  String? get jobTitleAdmin => getField<String>('job_title_admin');
  set jobTitleAdmin(String? value) =>
      setField<String>('job_title_admin', value);
}
