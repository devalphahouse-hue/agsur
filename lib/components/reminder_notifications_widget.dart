import 'dart:async';
import 'package:flutter/material.dart';
import '/backend/reminder_notifications.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// The inbox is independent of delivery: a failed WhatsApp send is still due.
class ReminderNotificationsWidget extends StatefulWidget {
  const ReminderNotificationsWidget({super.key});
  @override
  State<ReminderNotificationsWidget> createState() =>
      _ReminderNotificationsState();
}

class _ReminderNotificationsState extends State<ReminderNotificationsWidget> {
  late Future<List<Map<String, dynamic>>> _items;
  Timer? _timer;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _items = reminderNotifications();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !_busy) _refresh();
    });
  }

  void _refresh() => setState(() => _items = reminderNotifications());

  Future<void> _read(String id) async {
    setState(() => _busy = true);
    try {
      await readReminderNotification(id);
      if (mounted) _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível marcar o lembrete como lido.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _items,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return TextButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Atualizar lembretes do painel'));
              }
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final rows = snapshot.data!;
              return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                        'Lembretes (${rows.isEmpty ? 0 : rows.first['unread_count']} não lidos)',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    if (rows.isEmpty)
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Nenhum lembrete pendente.',
                              style: TextStyle(color: Colors.white70))),
                    if (rows.isNotEmpty)
                      ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: ListView.builder(
                              primary: false,
                              shrinkWrap: true,
                              itemCount: rows.length,
                              itemBuilder: (context, index) {
                                final row = rows[index];
                                final unread = row['read_at'] == null;
                                final date = DateTime.parse(
                                        row['scheduled_at'] as String)
                                    .toLocal();
                                final subject = row['subject'] as String? ?? '';
                                return Card(
                                    color: unread
                                        ? const Color(0xFF414141)
                                        : const Color(0xFF313131),
                                    child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  subject.isEmpty
                                                      ? 'Lembrete de atendimento'
                                                      : subject,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              Text(
                                                  '${row['lead_name']} · ${dateTimeFormat('dd/MM HH:mm', date)}',
                                                  style: const TextStyle(
                                                      color: Colors.white70)),
                                              Text(
                                                  row['message'] as String? ??
                                                      '',
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      color: Colors.white)),
                                              Text('WhatsApp: ${row['status']}',
                                                  style: const TextStyle(
                                                      color: Colors.white70)),
                                              if (unread)
                                                TextButton(
                                                    onPressed: _busy
                                                        ? null
                                                        : () => _read(row['id']
                                                            as String),
                                                    child: const Text(
                                                        'Marcar como lido')),
                                            ])));
                              })),
                    const Divider(color: Colors.white24),
                  ]);
            }),
      );
}
