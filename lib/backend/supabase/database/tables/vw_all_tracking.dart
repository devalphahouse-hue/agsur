import '../database.dart';

class VwAllTrackingTable extends SupabaseTable<VwAllTrackingRow> {
  @override
  String get tableName => 'vw_all_tracking';

  @override
  VwAllTrackingRow createRow(Map<String, dynamic> data) =>
      VwAllTrackingRow(data);
}

class VwAllTrackingRow extends SupabaseDataRow {
  VwAllTrackingRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VwAllTrackingTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get userAircraft => getField<String>('user_aircraft');
  set userAircraft(String? value) => setField<String>('user_aircraft', value);

  String? get trackingDescription => getField<String>('tracking_description');
  set trackingDescription(String? value) =>
      setField<String>('tracking_description', value);

  bool? get isCheck => getField<bool>('isCheck');
  set isCheck(bool? value) => setField<bool>('isCheck', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  int? get order => getField<int>('order');
  set order(int? value) => setField<int>('order', value);

  String? get link => getField<String>('link');
  set link(String? value) => setField<String>('link', value);

  String? get userAircraftId => getField<String>('user_aircraft_id');
  set userAircraftId(String? value) =>
      setField<String>('user_aircraft_id', value);

  String? get userAircraftProposalId =>
      getField<String>('user_aircraft_proposal_id');
  set userAircraftProposalId(String? value) =>
      setField<String>('user_aircraft_proposal_id', value);

  String? get userAircraftStatus => getField<String>('user_aircraft_status');
  set userAircraftStatus(String? value) =>
      setField<String>('user_aircraft_status', value);

  DateTime? get userAircraftCreatedAt =>
      getField<DateTime>('user_aircraft_created_at');
  set userAircraftCreatedAt(DateTime? value) =>
      setField<DateTime>('user_aircraft_created_at', value);

  String? get proposalId => getField<String>('proposal_id');
  set proposalId(String? value) => setField<String>('proposal_id', value);

  String? get proposalLeadId => getField<String>('proposal_lead_id');
  set proposalLeadId(String? value) =>
      setField<String>('proposal_lead_id', value);

  String? get proposalAircraftId => getField<String>('proposal_aircraft_id');
  set proposalAircraftId(String? value) =>
      setField<String>('proposal_aircraft_id', value);

  String? get proposalIdRef => getField<String>('proposal_id_ref');
  set proposalIdRef(String? value) =>
      setField<String>('proposal_id_ref', value);

  String? get proposalCreatedBy => getField<String>('proposal_created_by');
  set proposalCreatedBy(String? value) =>
      setField<String>('proposal_created_by', value);

  String? get aircraftModel => getField<String>('aircraft_model');
  set aircraftModel(String? value) => setField<String>('aircraft_model', value);

  String? get aircraftYear => getField<String>('aircraft_year');
  set aircraftYear(String? value) => setField<String>('aircraft_year', value);

  String? get createdByFullname => getField<String>('created_by_fullname');
  set createdByFullname(String? value) =>
      setField<String>('created_by_fullname', value);

  String? get companyName => getField<String>('company_name');
  set companyName(String? value) => setField<String>('company_name', value);
}
