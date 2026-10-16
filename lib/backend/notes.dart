import '/backend/supabase/supabase.dart';

/// Saves note + recipient snapshots + schedule in one database transaction.
Future<void> createLeadNote({
  required String leadId,
  required String note,
  required String requestId,
  Map<String, dynamic>? reminder,
}) async {
  try {
    await SupaFlow.client.rpc('create_lead_note', params: {
      'p_lead_id': leadId,
      'p_note': note,
      'p_reminder': reminder,
      'p_request_id': requestId,
    });
  } on PostgrestException catch (error) {
    // A missing RPC means no transaction ran. Keep ordinary notes available
    // during rollout; never silently discard a requested reminder or retry
    // another error whose write outcome may be uncertain.
    if (error.code != 'PGRST202' || reminder != null) rethrow;
    final userId = SupaFlow.client.auth.currentUser?.id;
    if (userId == null) rethrow;
    await NotesTable().insert({
      'lead_id': leadId,
      'note': note.trim(),
      'created_by': userId,
    });
  }
}
