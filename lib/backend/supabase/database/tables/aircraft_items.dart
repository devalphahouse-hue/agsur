import '../database.dart';

class AircraftItemsTable extends SupabaseTable<AircraftItemsRow> {
  @override
  String get tableName => 'aircraft_items';

  @override
  AircraftItemsRow createRow(Map<String, dynamic> data) =>
      AircraftItemsRow(data);
}

class AircraftItemsRow extends SupabaseDataRow {
  AircraftItemsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AircraftItemsTable();

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

  String get createdBy => getField<String>('created_by')!;
  set createdBy(String value) => setField<String>('created_by', value);
}
