import '../database.dart';

class ContractTable extends SupabaseTable<ContractRow> {
  @override
  String get tableName => 'contract';

  @override
  ContractRow createRow(Map<String, dynamic> data) => ContractRow(data);
}

class ContractRow extends SupabaseDataRow {
  ContractRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ContractTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_Id')!;
  set userId(String value) => setField<String>('user_Id', value);

  String get proposalId => getField<String>('proposal_id')!;
  set proposalId(String value) => setField<String>('proposal_id', value);

  double get fullprice => getField<double>('fullprice')!;
  set fullprice(double value) => setField<double>('fullprice', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String get createdBy => getField<String>('created_by')!;
  set createdBy(String value) => setField<String>('created_by', value);
}
