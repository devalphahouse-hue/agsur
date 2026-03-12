import '../database.dart';

class ProposalFinancingTable extends SupabaseTable<ProposalFinancingRow> {
  @override
  String get tableName => 'proposal_financing';

  @override
  ProposalFinancingRow createRow(Map<String, dynamic> data) =>
      ProposalFinancingRow(data);
}

class ProposalFinancingRow extends SupabaseDataRow {
  ProposalFinancingRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProposalFinancingTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  int get termLength => getField<int>('term_length')!;
  set termLength(int value) => setField<int>('term_length', value);

  DateTime get creditDate => getField<DateTime>('credit_date')!;
  set creditDate(DateTime value) => setField<DateTime>('credit_date', value);

  double get downPayment => getField<double>('down_payment')!;
  set downPayment(double value) => setField<double>('down_payment', value);

  double get initialDeposit => getField<double>('initial_deposit')!;
  set initialDeposit(double value) =>
      setField<double>('initial_deposit', value);

  double get totalDeposit => getField<double>('total_deposit')!;
  set totalDeposit(double value) => setField<double>('total_deposit', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String get createdBy => getField<String>('created_by')!;
  set createdBy(String value) => setField<String>('created_by', value);

  String get proposalId => getField<String>('proposal_id')!;
  set proposalId(String value) => setField<String>('proposal_id', value);

  double get premiumRate => getField<double>('premium_rate')!;
  set premiumRate(double value) => setField<double>('premium_rate', value);

  double get sofrRate => getField<double>('sofr_rate')!;
  set sofrRate(double value) => setField<double>('sofr_rate', value);

  double get interestRate => getField<double>('interest_rate')!;
  set interestRate(double value) => setField<double>('interest_rate', value);
}
