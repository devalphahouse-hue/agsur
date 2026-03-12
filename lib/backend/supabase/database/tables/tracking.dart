import '../database.dart';

class TrackingTable extends SupabaseTable<TrackingRow> {
  @override
  String get tableName => 'tracking';

  @override
  TrackingRow createRow(Map<String, dynamic> data) => TrackingRow(data);
}

class TrackingRow extends SupabaseDataRow {
  TrackingRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => TrackingTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userAircraft => getField<String>('user_aircraft')!;
  set userAircraft(String value) => setField<String>('user_aircraft', value);

  String get trackingDescription => getField<String>('tracking_description')!;
  set trackingDescription(String value) =>
      setField<String>('tracking_description', value);

  bool get isCheck => getField<bool>('isCheck')!;
  set isCheck(bool value) => setField<bool>('isCheck', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  int get order => getField<int>('order')!;
  set order(int value) => setField<int>('order', value);

  String? get link => getField<String>('link');
  set link(String? value) => setField<String>('link', value);

  String? get link2 => getField<String>('link2');
  set link2(String? value) => setField<String>('link2', value);
}
