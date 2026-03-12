import '../database.dart';

class GuaranteeTable extends SupabaseTable<GuaranteeRow> {
  @override
  String get tableName => 'guarantee';

  @override
  GuaranteeRow createRow(Map<String, dynamic> data) => GuaranteeRow(data);
}

class GuaranteeRow extends SupabaseDataRow {
  GuaranteeRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => GuaranteeTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String get nameAircraft => getField<String>('name_aircraft')!;
  set nameAircraft(String value) => setField<String>('name_aircraft', value);

  String get aircraftSerialKey => getField<String>('aircraft_serial_key')!;
  set aircraftSerialKey(String value) =>
      setField<String>('aircraft_serial_key', value);

  String get aircraftPrefix => getField<String>('aircraft_prefix')!;
  set aircraftPrefix(String value) =>
      setField<String>('aircraft_prefix', value);

  String get partNumber => getField<String>('part_number')!;
  set partNumber(String value) => setField<String>('part_number', value);

  String get partSerialNumber => getField<String>('part_serial_number')!;
  set partSerialNumber(String value) =>
      setField<String>('part_serial_number', value);

  String get partDescription => getField<String>('part_description')!;
  set partDescription(String value) =>
      setField<String>('part_description', value);

  DateTime get failureDate => getField<DateTime>('failure_date')!;
  set failureDate(DateTime value) => setField<DateTime>('failure_date', value);

  String get failureDescription => getField<String>('failure_description')!;
  set failureDescription(String value) =>
      setField<String>('failure_description', value);

  String? get observations => getField<String>('observations');
  set observations(String? value) => setField<String>('observations', value);

  String? get imageUrl => getField<String>('image_url');
  set imageUrl(String? value) => setField<String>('image_url', value);

  String get mechanicShopName => getField<String>('mechanic_shop_name')!;
  set mechanicShopName(String value) =>
      setField<String>('mechanic_shop_name', value);

  String get mechanicName => getField<String>('mechanic_name')!;
  set mechanicName(String value) => setField<String>('mechanic_name', value);

  String get mechanicId => getField<String>('mechanic_id')!;
  set mechanicId(String value) => setField<String>('mechanic_id', value);

  bool get termsAccepted => getField<bool>('terms_accepted')!;
  set termsAccepted(bool value) => setField<bool>('terms_accepted', value);

  bool get deleted => getField<bool>('deleted')!;
  set deleted(bool value) => setField<bool>('deleted', value);

  String get idRef => getField<String>('id_ref')!;
  set idRef(String value) => setField<String>('id_ref', value);

  String get status => getField<String>('status')!;
  set status(String value) => setField<String>('status', value);

  String get createdBy => getField<String>('created_by')!;
  set createdBy(String value) => setField<String>('created_by', value);
}
