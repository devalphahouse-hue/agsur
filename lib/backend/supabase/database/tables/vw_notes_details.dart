import '../database.dart';

class VwNotesDetailsTable extends SupabaseTable<VwNotesDetailsRow> {
  @override
  String get tableName => 'vw_notes_details';

  @override
  VwNotesDetailsRow createRow(Map<String, dynamic> data) =>
      VwNotesDetailsRow(data);
}

class VwNotesDetailsRow extends SupabaseDataRow {
  VwNotesDetailsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VwNotesDetailsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get leadId => getField<String>('lead_id');
  set leadId(String? value) => setField<String>('lead_id', value);

  String? get note => getField<String>('note');
  set note(String? value) => setField<String>('note', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);

  String? get createdByName => getField<String>('created_by_name');
  set createdByName(String? value) =>
      setField<String>('created_by_name', value);
}
