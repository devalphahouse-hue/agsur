import '../database.dart';

class VwGetPilotsTable extends SupabaseTable<VwGetPilotsRow> {
  @override
  String get tableName => 'vw_get_pilots';

  @override
  VwGetPilotsRow createRow(Map<String, dynamic> data) => VwGetPilotsRow(data);
}

class VwGetPilotsRow extends SupabaseDataRow {
  VwGetPilotsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VwGetPilotsTable();

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get fullname => getField<String>('fullname');
  set fullname(String? value) => setField<String>('fullname', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get lastname => getField<String>('lastname');
  set lastname(String? value) => setField<String>('lastname', value);

  String? get email => getField<String>('email');
  set email(String? value) => setField<String>('email', value);

  String? get createdAt => getField<String>('created_at');
  set createdAt(String? value) => setField<String>('created_at', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  String? get phone => getField<String>('phone');
  set phone(String? value) => setField<String>('phone', value);

  bool? get isDeleted => getField<bool>('is_deleted');
  set isDeleted(bool? value) => setField<bool>('is_deleted', value);
}
