import '../database.dart';

// Escrito à mão (não-FlutterFlow) — view read-only: uma linha por par
// (item, aeronave vinculada), migration 20260714130000. Colunas snake_case
// conferidas contra a migration (armadilha de desync documentada na memória
// do projeto). Revalidar após regen do FlutterFlow.
class VwAircraftItemsByAircraftTable
    extends SupabaseTable<VwAircraftItemsByAircraftRow> {
  @override
  String get tableName => 'vw_aircraft_items_by_aircraft';

  @override
  VwAircraftItemsByAircraftRow createRow(Map<String, dynamic> data) =>
      VwAircraftItemsByAircraftRow(data);
}

class VwAircraftItemsByAircraftRow extends SupabaseDataRow {
  VwAircraftItemsByAircraftRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VwAircraftItemsByAircraftTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get categoryId => getField<String>('category_id')!;
  set categoryId(String value) => setField<String>('category_id', value);

  String get itemName => getField<String>('item_name')!;
  set itemName(String value) => setField<String>('item_name', value);

  int get qty => getField<int>('qty')!;
  set qty(int value) => setField<int>('qty', value);

  double get price => getField<double>('price')!;
  set price(double value) => setField<double>('price', value);

  bool get active => getField<bool>('active')!;
  set active(bool value) => setField<bool>('active', value);

  bool get deleted => getField<bool>('deleted')!;
  set deleted(bool value) => setField<bool>('deleted', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String get itemType => getField<String>('item_type')!;
  set itemType(String value) => setField<String>('item_type', value);

  String get aircraftId => getField<String>('aircraft_id')!;
  set aircraftId(String value) => setField<String>('aircraft_id', value);
}
