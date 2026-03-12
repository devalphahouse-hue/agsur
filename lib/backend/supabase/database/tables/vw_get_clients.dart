import '../database.dart';

class VwGetClientsTable extends SupabaseTable<VwGetClientsRow> {
  @override
  String get tableName => 'vw_get_clients';

  @override
  VwGetClientsRow createRow(Map<String, dynamic> data) => VwGetClientsRow(data);
}

class VwGetClientsRow extends SupabaseDataRow {
  VwGetClientsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VwGetClientsTable();

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get clientFullname => getField<String>('client_fullname');
  set clientFullname(String? value) =>
      setField<String>('client_fullname', value);

  String? get leadId => getField<String>('lead_id');
  set leadId(String? value) => setField<String>('lead_id', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  String? get jobTitle => getField<String>('job_title');
  set jobTitle(String? value) => setField<String>('job_title', value);

  String? get companyName => getField<String>('company_name');
  set companyName(String? value) => setField<String>('company_name', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
