import '../database.dart';

class ProposalItemTable extends SupabaseTable<ProposalItemRow> {
  @override
  String get tableName => 'proposal_item';

  @override
  ProposalItemRow createRow(Map<String, dynamic> data) => ProposalItemRow(data);
}

class ProposalItemRow extends SupabaseDataRow {
  ProposalItemRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProposalItemTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get proposalId => getField<String>('proposal_id')!;
  set proposalId(String value) => setField<String>('proposal_id', value);

  String get aircraftItemId => getField<String>('aircraft_item_id')!;
  set aircraftItemId(String value) =>
      setField<String>('aircraft_item_id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);
}
