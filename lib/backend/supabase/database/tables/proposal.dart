import '../database.dart';

class ProposalTable extends SupabaseTable<ProposalRow> {
  @override
  String get tableName => 'proposal';

  @override
  ProposalRow createRow(Map<String, dynamic> data) => ProposalRow(data);
}

class ProposalRow extends SupabaseDataRow {
  ProposalRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProposalTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get leadId => getField<String>('lead_id')!;
  set leadId(String value) => setField<String>('lead_id', value);

  String get aircraftId => getField<String>('aircraft_id')!;
  set aircraftId(String value) => setField<String>('aircraft_id', value);

  double get fullprice => getField<double>('fullprice')!;
  set fullprice(double value) => setField<double>('fullprice', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String get createdBy => getField<String>('created_by')!;
  set createdBy(String value) => setField<String>('created_by', value);

  bool get active => getField<bool>('active')!;
  set active(bool value) => setField<bool>('active', value);

  bool get isDeleted => getField<bool>('is_deleted')!;
  set isDeleted(bool value) => setField<bool>('is_deleted', value);

  bool get isContract => getField<bool>('is_contract')!;
  set isContract(bool value) => setField<bool>('is_contract', value);

  String get idRef => getField<String>('id_ref')!;
  set idRef(String value) => setField<String>('id_ref', value);
}
