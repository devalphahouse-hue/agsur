import '../database.dart';

// Escrito à mão (não-FlutterFlow) — view read-only `vw_stock_units`, migration
// 20260922120000: uma linha por unidade física do estoque, com o nome do
// modelo, o destaque do catálogo e o contrato ATIVO que a prende (se houver).
// Colunas conferidas contra a migration. Revalidar após regen do FlutterFlow.
class VwStockUnitsTable extends SupabaseTable<VwStockUnitsRow> {
  @override
  String get tableName => 'vw_stock_units';

  @override
  VwStockUnitsRow createRow(Map<String, dynamic> data) => VwStockUnitsRow(data);
}

class VwStockUnitsRow extends SupabaseDataRow {
  VwStockUnitsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VwStockUnitsTable();

  String get id => getField<String>('id')!;
  String get aircraftId => getField<String>('aircraft_id')!;
  String get aircraftModelName => getField<String>('aircraft_model_name') ?? '';
  String get aircraftPhotoUrl => getField<String>('aircraft_photo_url') ?? '';
  bool get featured => getField<bool>('featured') ?? false;
  String get serialNumber => getField<String>('serial_number') ?? '';
  String? get registrationPrefix => getField<String>('registration_prefix');
  DateTime? get manufactureDate => getField<DateTime>('manufacture_date');
  DateTime? get configurationDeadline =>
      getField<DateTime>('configuration_deadline');
  DateTime? get deliveryDate => getField<DateTime>('delivery_date');
  String get entryYear => getField<String>('entry_year') ?? '';
  String get status => getField<String>('status') ?? '';
  bool get inStock => getField<bool>('in_stock') ?? false;
  DateTime? get createdAt => getField<DateTime>('created_at');
  String? get contractId => getField<String>('contract_id');
  String? get contractProposalId => getField<String>('contract_proposal_id');
}
