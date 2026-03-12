import '../database.dart';

class VwProposalDataTable extends SupabaseTable<VwProposalDataRow> {
  @override
  String get tableName => 'vw_proposal_data';

  @override
  VwProposalDataRow createRow(Map<String, dynamic> data) =>
      VwProposalDataRow(data);
}

class VwProposalDataRow extends SupabaseDataRow {
  VwProposalDataRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VwProposalDataTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get idRef => getField<String>('id_ref');
  set idRef(String? value) => setField<String>('id_ref', value);

  String? get leadId => getField<String>('lead_id');
  set leadId(String? value) => setField<String>('lead_id', value);

  String? get aircraftId => getField<String>('aircraft_id');
  set aircraftId(String? value) => setField<String>('aircraft_id', value);

  double? get fullprice => getField<double>('fullprice');
  set fullprice(double? value) => setField<double>('fullprice', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);

  bool? get isContract => getField<bool>('is_contract');
  set isContract(bool? value) => setField<bool>('is_contract', value);

  String? get aircraftModel => getField<String>('aircraft_model');
  set aircraftModel(String? value) => setField<String>('aircraft_model', value);

  String? get companyName => getField<String>('company_name');
  set companyName(String? value) => setField<String>('company_name', value);

  String? get createdByName => getField<String>('created_by_name');
  set createdByName(String? value) =>
      setField<String>('created_by_name', value);

  String? get leadFullname => getField<String>('lead_fullname');
  set leadFullname(String? value) => setField<String>('lead_fullname', value);
}
