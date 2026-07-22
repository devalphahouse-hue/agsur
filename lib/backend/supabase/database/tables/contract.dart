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

  DateTime? get cancelledAt => getField<DateTime>('cancelled_at');
  set cancelledAt(DateTime? value) => setField<DateTime>('cancelled_at', value);

  // Unidade física do estoque vinculada (migration 20260722130000).
  String? get availableAircraftId => getField<String>('available_aircraft_id');
  set availableAircraftId(String? value) =>
      setField<String>('available_aircraft_id', value);
}
