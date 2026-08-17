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

  // ⚠️ Escritos à mão (migration 20260817120000_leads_referral). Uma regeneração
  // do FlutterFlow apaga daqui para baixo e a indicação para de chegar na
  // conversão — a comissão do vendedor volta silenciosamente para 7500.
  // `isReferral` é NOT NULL DEFAULT false no banco, mas o getter é nullable de
  // propósito: linha vinda de um SELECT que não pediu a coluna devolveria null.
  bool? get isReferral => getField<bool>('is_referral');
  set isReferral(bool? value) => setField<bool>('is_referral', value);

  String? get referralName => getField<String>('referral_name');
  set referralName(String? value) => setField<String>('referral_name', value);

  String? get referralPhone => getField<String>('referral_phone');
  set referralPhone(String? value) => setField<String>('referral_phone', value);

  String? get referralEmail => getField<String>('referral_email');
  set referralEmail(String? value) => setField<String>('referral_email', value);

  double? get referralAgreedValue =>
      getField<double>('referral_agreed_value');
  set referralAgreedValue(double? value) =>
      setField<double>('referral_agreed_value', value);
}
