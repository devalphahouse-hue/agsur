import 'dart:async';

import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';

/// State container do ViewTrackingWidget — mantido para preservar o
/// contrato `_model.apiRequestCompleter` usado no widget.
class ViewTrackingModel {
  Completer<ApiCallResponse>? apiRequestCompleter;
  List<UserAircraftRow>? updateUserAircraft;
  List<UsersRow>? user;

  /// Dados preenchidos de cada etapa (memoizado para não refazer a query por
  /// rebuild/por card — ver armadilha do FutureBuilder inline no CLAUDE.md).
  /// Zerado em `_refresh`.
  Future<TrackingExtras>? extrasFuture;

  void dispose() {}

  Future<void> waitForApiRequestCompleted({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(const Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleter?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}

/// Dados preenchidos das etapas: os `tracking_details` (um por etapa, indexado
/// por `tracking_id`) + a linha `user_aircraft` (guarda cor/filtro/painel da
/// etapa 1). Carregado uma vez por aeronave e passado aos cards.
class TrackingExtras {
  const TrackingExtras(this.detailsByTrackingId, this.aircraft);
  final Map<String, TrackingDetailsRow> detailsByTrackingId;
  final UserAircraftRow? aircraft;
}
