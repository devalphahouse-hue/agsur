import '../database.dart';

class CompanyTable extends SupabaseTable<CompanyRow> {
  @override
  String get tableName => 'company';

  @override
  CompanyRow createRow(Map<String, dynamic> data) => CompanyRow(data);
}

class CompanyRow extends SupabaseDataRow {
  CompanyRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CompanyTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get companyName => getField<String>('company_name')!;
  set companyName(String value) => setField<String>('company_name', value);

  String get cnpj => getField<String>('cnpj')!;
  set cnpj(String value) => setField<String>('cnpj', value);

  String get phone => getField<String>('phone')!;
  set phone(String value) => setField<String>('phone', value);

  String? get email => getField<String>('email');
  set email(String? value) => setField<String>('email', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String get createdBy => getField<String>('created_by')!;
  set createdBy(String value) => setField<String>('created_by', value);

  String get leadId => getField<String>('lead_id')!;
  set leadId(String value) => setField<String>('lead_id', value);

  String? get cpf => getField<String>('cpf');
  set cpf(String? value) => setField<String>('cpf', value);

  String? get typeDoc => getField<String>('type_doc');
  set typeDoc(String? value) => setField<String>('type_doc', value);

  String? get stateRegistration => getField<String>('state_registration');
  set stateRegistration(String? value) =>
      setField<String>('state_registration', value);
}
