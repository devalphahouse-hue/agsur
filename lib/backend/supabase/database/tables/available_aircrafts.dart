import '../database.dart';

class AvailableAircraftsTable extends SupabaseTable<AvailableAircraftsRow> {
  @override
  String get tableName => 'available_aircrafts';

  @override
  AvailableAircraftsRow createRow(Map<String, dynamic> data) =>
      AvailableAircraftsRow(data);
}

class AvailableAircraftsRow extends SupabaseDataRow {
  AvailableAircraftsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AvailableAircraftsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get aircraftModel => getField<String>('aircraft_model')!;
  set aircraftModel(String value) => setField<String>('aircraft_model', value);

  String get serialNumber => getField<String>('serial_number')!;
  set serialNumber(String value) => setField<String>('serial_number', value);

  DateTime get manufactureDate => getField<DateTime>('manufacture_date')!;
  set manufactureDate(DateTime value) =>
      setField<DateTime>('manufacture_date', value);

  DateTime get configurationDeadline =>
      getField<DateTime>('configuration_deadline')!;
  set configurationDeadline(DateTime value) =>
      setField<DateTime>('configuration_deadline', value);

  DateTime get deliveryDate => getField<DateTime>('delivery_date')!;
  set deliveryDate(DateTime value) =>
      setField<DateTime>('delivery_date', value);

  String get status => getField<String>('status')!;
  set status(String value) => setField<String>('status', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String get createdBy => getField<String>('created_by')!;
  set createdBy(String value) => setField<String>('created_by', value);

  String get updateBy => getField<String>('update_by')!;
  set updateBy(String value) => setField<String>('update_by', value);

  String get entryYear => getField<String>('entry_year')!;
  set entryYear(String value) => setField<String>('entry_year', value);

  // Escritos à mão (migration 20260922120000) — revalidar após regen do
  // FlutterFlow. `in_stock` é espelho do livro-razão (stock_movements): não
  // se grava direto, a guarda do banco recusa.
  String? get registrationPrefix => getField<String>('registration_prefix');
  set registrationPrefix(String? value) =>
      setField<String>('registration_prefix', value);

  bool get inStock => getField<bool>('in_stock') ?? true;
}
