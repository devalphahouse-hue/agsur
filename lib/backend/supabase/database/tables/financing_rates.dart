import '../database.dart';

class FinancingRatesTable extends SupabaseTable<FinancingRatesRow> {
  @override
  String get tableName => 'financing_rates';

  @override
  FinancingRatesRow createRow(Map<String, dynamic> data) =>
      FinancingRatesRow(data);
}

class FinancingRatesRow extends SupabaseDataRow {
  FinancingRatesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FinancingRatesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  double get premiumRateFive => getField<double>('premium_rate_five')!;
  set premiumRateFive(double value) =>
      setField<double>('premium_rate_five', value);

  double get sofrRate => getField<double>('sofr_rate')!;
  set sofrRate(double value) => setField<double>('sofr_rate', value);

  double get interestRate => getField<double>('interest_rate')!;
  set interestRate(double value) => setField<double>('interest_rate', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String get createdBy => getField<String>('created_by')!;
  set createdBy(String value) => setField<String>('created_by', value);

  double get premiumRateSeven => getField<double>('premium_rate_seven')!;
  set premiumRateSeven(double value) =>
      setField<double>('premium_rate_seven', value);
}
