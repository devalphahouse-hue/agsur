import '../database.dart';

class SalesTable extends SupabaseTable<SalesRow> {
  @override
  String get tableName => 'sales';

  @override
  SalesRow createRow(Map<String, dynamic> data) => SalesRow(data);
}

class SalesRow extends SupabaseDataRow {
  SalesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SalesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get sellerId => getField<String>('seller_id')!;
  set sellerId(String value) => setField<String>('seller_id', value);

  String get proposalId => getField<String>('proposal_id')!;
  set proposalId(String value) => setField<String>('proposal_id', value);

  double get fullprice => getField<double>('fullprice')!;
  set fullprice(double value) => setField<double>('fullprice', value);

  double get sellerCommission => getField<double>('seller_commission')!;
  set sellerCommission(double value) =>
      setField<double>('seller_commission', value);

  double get companyCommission => getField<double>('company_commission')!;
  set companyCommission(double value) =>
      setField<double>('company_commission', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String get createdBy => getField<String>('created_by')!;
  set createdBy(String value) => setField<String>('created_by', value);
}
