import '../database.dart';

// Escrito à mão (não-FlutterFlow) — view read-only `vw_stock_movements`,
// migration 20260922120000: livro-razão do estoque (entradas e saídas) com
// modelo, serial e nome de quem lançou. Imutável no banco — não há insert
// daqui; lançamentos nascem pelas RPCs `stock_*` e pelo trigger de contrato.
// Revalidar após regen do FlutterFlow.
class VwStockMovementsTable extends SupabaseTable<VwStockMovementsRow> {
  @override
  String get tableName => 'vw_stock_movements';

  @override
  VwStockMovementsRow createRow(Map<String, dynamic> data) =>
      VwStockMovementsRow(data);
}

class VwStockMovementsRow extends SupabaseDataRow {
  VwStockMovementsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VwStockMovementsTable();

  String get id => getField<String>('id')!;
  String get availableAircraftId => getField<String>('available_aircraft_id')!;
  String get aircraftId => getField<String>('aircraft_id')!;
  String get aircraftModelName => getField<String>('aircraft_model_name') ?? '';
  String get serialNumber => getField<String>('serial_number') ?? '';

  /// `entrada` ou `saida`.
  String get movementType => getField<String>('movement_type')!;
  bool get isEntrada => movementType == 'entrada';
  String get reason => getField<String>('reason')!;
  String? get note => getField<String>('note');
  String? get contractId => getField<String>('contract_id');
  String? get batchId => getField<String>('batch_id');
  String? get createdByName => getField<String>('created_by_name');
  DateTime get createdAt => getField<DateTime>('created_at')!;
}
