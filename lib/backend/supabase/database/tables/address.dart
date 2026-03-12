import '../database.dart';

class AddressTable extends SupabaseTable<AddressRow> {
  @override
  String get tableName => 'address';

  @override
  AddressRow createRow(Map<String, dynamic> data) => AddressRow(data);
}

class AddressRow extends SupabaseDataRow {
  AddressRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AddressTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get zipcode => getField<String>('zipcode')!;
  set zipcode(String value) => setField<String>('zipcode', value);

  String get companyId => getField<String>('company_id')!;
  set companyId(String value) => setField<String>('company_id', value);

  String get street => getField<String>('street')!;
  set street(String value) => setField<String>('street', value);

  String get number => getField<String>('number')!;
  set number(String value) => setField<String>('number', value);

  String get neighborhood => getField<String>('neighborhood')!;
  set neighborhood(String value) => setField<String>('neighborhood', value);

  String get city => getField<String>('city')!;
  set city(String value) => setField<String>('city', value);

  String get state => getField<String>('state')!;
  set state(String value) => setField<String>('state', value);

  String? get complement => getField<String>('complement');
  set complement(String? value) => setField<String>('complement', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get createdBy => getField<String>('created_by');
  set createdBy(String? value) => setField<String>('created_by', value);
}
