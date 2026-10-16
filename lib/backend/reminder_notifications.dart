import '/backend/supabase/supabase.dart';

Future<List<Map<String, dynamic>>> reminderNotifications(
    {int limit = 50}) async {
  final result = await SupaFlow.client
      .rpc('my_reminder_notifications', params: {'p_limit': limit});
  return (result as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();
}

Future<void> readReminderNotification(String id) async {
  await SupaFlow.client
      .rpc('mark_reminder_notification_read', params: {'p_id': id});
}
