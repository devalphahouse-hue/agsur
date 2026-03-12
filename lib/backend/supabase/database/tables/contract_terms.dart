import '../database.dart';

class ContractTermsTable extends SupabaseTable<ContractTermsRow> {
  @override
  String get tableName => 'contract_terms';

  @override
  ContractTermsRow createRow(Map<String, dynamic> data) =>
      ContractTermsRow(data);
}

class ContractTermsRow extends SupabaseDataRow {
  ContractTermsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ContractTermsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get terms => getField<String>('terms')!;
  set terms(String value) => setField<String>('terms', value);

  String get paymentInstructions => getField<String>('payment_instructions')!;
  set paymentInstructions(String value) =>
      setField<String>('payment_instructions', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String get createdBy => getField<String>('created_by')!;
  set createdBy(String value) => setField<String>('created_by', value);

  String get updateTermsBy => getField<String>('update_terms_by')!;
  set updateTermsBy(String value) => setField<String>('update_terms_by', value);

  DateTime get updateTermsAt => getField<DateTime>('update_terms_at')!;
  set updateTermsAt(DateTime value) =>
      setField<DateTime>('update_terms_at', value);

  String get updateInstructionsBy =>
      getField<String>('update_instructions_by')!;
  set updateInstructionsBy(String value) =>
      setField<String>('update_instructions_by', value);

  DateTime get updateInstructionsAt =>
      getField<DateTime>('update_instructions_at')!;
  set updateInstructionsAt(DateTime value) =>
      setField<DateTime>('update_instructions_at', value);
}
