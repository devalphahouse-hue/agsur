import 'package:flutter/material.dart';
import '/pages/reminders/reminder_history/reminder_history_widget.dart';

Future<void> showWhatsappReminderHistory(BuildContext context, String leadId) =>
    showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Histórico de lembretes'),
              content: SizedBox(
                  width: 860,
                  height: 500,
                  child: SingleChildScrollView(
                      child: ReminderHistoryPanel(leadId: leadId))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Fechar'))
              ],
            ));
