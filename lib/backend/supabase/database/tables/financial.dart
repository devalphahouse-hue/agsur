import '../database.dart';

class FinancialTable extends SupabaseTable<FinancialRow> {
  @override
  String get tableName => 'financial';

  @override
  FinancialRow createRow(Map<String, dynamic> data) => FinancialRow(data);
}

class FinancialRow extends SupabaseDataRow {
  FinancialRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FinancialTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get financialType => getField<String>('financial_type')!;
  set financialType(String value) => setField<String>('financial_type', value);

  String get saleId => getField<String>('sale_id')!;
  set saleId(String value) => setField<String>('sale_id', value);

  String get description => getField<String>('description')!;
  set description(String value) => setField<String>('description', value);

  String get financialStatus => getField<String>('financial_status')!;
  set financialStatus(String value) =>
      setField<String>('financial_status', value);

  DateTime? get dueDate => getField<DateTime>('due_date');
  set dueDate(DateTime? value) => setField<DateTime>('due_date', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String get createdBy => getField<String>('created_by')!;
  set createdBy(String value) => setField<String>('created_by', value);
}
