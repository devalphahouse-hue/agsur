import 'dart:async';

import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';

/// State container do ViewTrackingWidget — mantido para preservar o
/// contrato `_model.apiRequestCompleter` usado no widget.
class ViewTrackingModel {
  Completer<ApiCallResponse>? apiRequestCompleter;
  List<UserAircraftRow>? updateUserAircraft;
  List<UsersRow>? user;

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
