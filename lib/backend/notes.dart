import '/backend/supabase/supabase.dart';

/// Saves note + recipient snapshots + schedule in one database transaction.
Future<void> createLeadNote({
  required String leadId,
  required String note,
  required String requestId,
  Map<String, dynamic>? reminder,
}) async {
  await SupaFlow.client.rpc('create_lead_note', params: {
    'p_lead_id': leadId,
    'p_note': note,
    'p_reminder': reminder,
    'p_request_id': requestId,
  });
}
