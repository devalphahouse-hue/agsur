import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'create_items_standard_widget.dart' show CreateItemsStandardWidget;
import 'package:flutter/material.dart';

class CreateItemsStandardModel
    extends FlutterFlowModel<CreateItemsStandardWidget> {
  ///  Local state fields for this page.

  int section = 0;

  /// Dados de apoio memoizados (evita re-query a cada rebuild — ver CLAUDE.md).
  /// Invalidar (`= null`) + `safeSetState` após criar/editar/excluir.
  // Aeronaves ativas — opções do multi-select e rótulos da listagem.
  Future<List<AircraftsRow>>? aircraftsFuture;
  // Vínculos item ↔ aeronave (tabela pequena; agrupada em memória).
  Future<List<AircraftItemLinksRow>>? itemLinksFuture;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
