import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'create_items_options_widget.dart' show CreateItemsOptionsWidget;
import 'dart:async';
import 'package:flutter/material.dart';

class CreateItemsOptionsModel
    extends FlutterFlowModel<CreateItemsOptionsWidget> {
  ///  Local state fields for this page.

  int section = 0;

  ///  State fields for stateful widgets in this page.

  Completer<List<AircraftItemsRow>>? requestCompleter;

  // Cache de itens POR categoria. O bug original (FlutterFlow) usava um único
  // requestCompleter para todas: a primeira categoria a renderizar completava
  // a future com os itens DELA e as demais reutilizavam o mesmo resultado —
  // toda categoria mostrava os mesmos itens. Invalidar com .clear().
  final Map<String, Future<List<AircraftItemsRow>>> itemsByCategory = {};
  // Dados de apoio memoizados — aeronaves ativas do catálogo e vínculos
  // item↔aeronave (agrupados por aircraft_item_id em memória). Invalidar
  // (= null) + safeSetState após criar/editar/excluir.
  Future<List<AircraftsRow>>? aircraftsFuture;
  Future<List<AircraftItemLinksRow>>? aircraftLinksFuture;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}

  /// Additional helper methods.
  Future waitForRequestCompleted({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = requestCompleter?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
