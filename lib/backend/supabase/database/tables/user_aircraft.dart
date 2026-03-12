import '../database.dart';

class UserAircraftTable extends SupabaseTable<UserAircraftRow> {
  @override
  String get tableName => 'user_aircraft';

  @override
  UserAircraftRow createRow(Map<String, dynamic> data) => UserAircraftRow(data);
}

class UserAircraftRow extends SupabaseDataRow {
  UserAircraftRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserAircraftTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  bool get deleted => getField<bool>('deleted')!;
  set deleted(bool value) => setField<bool>('deleted', value);

  String? get stripeColor => getField<String>('stripe_color');
  set stripeColor(String? value) => setField<String>('stripe_color', value);

  String? get airFilter => getField<String>('air_filter');
  set airFilter(String? value) => setField<String>('air_filter', value);

  String? get panel => getField<String>('panel');
  set panel(String? value) => setField<String>('panel', value);

  String? get contractId => getField<String>('contract_id');
  set contractId(String? value) => setField<String>('contract_id', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);

  String? get aircraftStatus => getField<String>('aircraft_status');
  set aircraftStatus(String? value) =>
      setField<String>('aircraft_status', value);

  String get proposalId => getField<String>('proposal_id')!;
  set proposalId(String value) => setField<String>('proposal_id', value);
}
