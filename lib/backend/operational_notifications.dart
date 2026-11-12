import '/backend/supabase/supabase.dart';

enum OperationalNotificationKind {
  tracking,
  followUp,
  contractChange,
  clientWaiting
}

class OperationalNotification {
  OperationalNotification(Map<String, dynamic> row)
      : kind = switch (row['kind']) {
          'follow_up' => OperationalNotificationKind.followUp,
          'contract_change' => OperationalNotificationKind.contractChange,
          'client_waiting' => OperationalNotificationKind.clientWaiting,
          _ => OperationalNotificationKind.tracking,
        },
        id = row['record_id'] as String,
        proposalId = row['proposal_id'] as String?,
        title = row['title'] as String,
        subtitle = row['subtitle'] as String,
        detail = row['detail'] as String,
        dueAt = DateTime.tryParse(row['due_at'] as String? ?? ''),
        dueOn = DateTime.tryParse(row['due_on'] as String? ?? ''),
        total = (row['total_count'] as num).toInt();

  final OperationalNotificationKind kind;
  final String id;
  final String? proposalId;
  final String title;
  final String subtitle;
  final String detail;
  final DateTime? dueAt;
  final DateTime? dueOn;
  final int total;
}

Future<List<OperationalNotification>> operationalNotifications({
  int limit = 100,
}) async {
  final rows = await SupaFlow.client
      .rpc('operational_notifications', params: {'p_limit': limit});
  return (rows as List)
      .cast<Map<String, dynamic>>()
      .map(OperationalNotification.new)
      .toList();
}
