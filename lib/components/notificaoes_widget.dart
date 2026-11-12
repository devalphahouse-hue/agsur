import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/backend/operational_notifications.dart';
import '/backend/supabase/supabase.dart';
import '/components/reminder_notifications_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/security/write_guard.dart';

class NotificaoesWidget extends StatefulWidget {
  const NotificaoesWidget({super.key});

  @override
  State<NotificaoesWidget> createState() => _NotificaoesWidgetState();
}

class _NotificaoesWidgetState extends State<NotificaoesWidget> {
  late Future<List<OperationalNotification>> _pending;
  Timer? _poll;
  final _completing = <String>{};

  @override
  void initState() {
    super.initState();
    _pending = operationalNotifications();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  void _refresh() => setState(() => _pending = operationalNotifications());

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _complete(OperationalNotification item) async {
    setState(() => _completing.add(item.id));
    try {
      final (rpc, key) = switch (item.kind) {
        OperationalNotificationKind.followUp => (
            'complete_contract_follow_up',
            'p_contract_id'
          ),
        OperationalNotificationKind.contractChange => (
            'resolve_contract_change',
            'p_request_id'
          ),
        OperationalNotificationKind.clientWaiting => (
            'set_lead_waiting',
            'p_lead_id'
          ),
        OperationalNotificationKind.tracking =>
          throw StateError('A etapa deve ser concluída no rastreamento.'),
      };
      final completed = await SupaFlow.client.rpc(rpc, params: {key: item.id});
      if (!mounted) return;
      if (completed != true) {
        showWriteError(
            context, 'A pendência já foi concluída ou está indisponível.');
      }
      _refresh();
    } catch (_) {
      if (mounted)
        showWriteError(context, 'Não foi possível concluir a pendência.');
    } finally {
      if (mounted) setState(() => _completing.remove(item.id));
    }
  }

  void _open(OperationalNotification item) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    switch (item.kind) {
      case OperationalNotificationKind.followUp:
      case OperationalNotificationKind.contractChange:
        router.pushNamed(ViewContractWidget.routeName,
            queryParameters: {
              'proposalId': serializeParam(item.proposalId, ParamType.String),
              'typeAccess':
                  item.kind == OperationalNotificationKind.contractChange
                      ? 'edit'
                      : 'view',
            }.withoutNulls);
      case OperationalNotificationKind.clientWaiting:
        router.pushNamed(ViewEditLeadWidget.routeName,
            queryParameters: {
              'leadId': serializeParam(item.id, ParamType.String),
              'typeAccess': 'view',
              'fullname': item.subtitle,
            }.withoutNulls);
      case OperationalNotificationKind.tracking:
        router.pushNamed(ViewTrackingWidget.routeName,
            queryParameters: {
              'userAircraftId': serializeParam(item.id, ParamType.String),
            }.withoutNulls);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Material(
      color: const Color(0xFF313131),
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: size.width < 440 ? size.width - 32 : 408,
          maxHeight: size.height * 0.7,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text('Notificações',
                          style: Theme.of(context).textTheme.titleLarge)),
                  IconButton(
                      tooltip: 'Atualizar',
                      icon: const Icon(Icons.refresh),
                      onPressed: _refresh),
                  IconButton(
                      tooltip: 'Fechar',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const ReminderNotificationsWidget(),
              FutureBuilder<List<OperationalNotification>>(
                future: _pending,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                        'Não foi possível carregar as pendências.');
                  }
                  final items = snapshot.data;
                  if (items == null) return const LinearProgressIndicator();
                  if (items.isEmpty)
                    return const Text('Nenhuma pendência em andamento.');
                  return Column(
                    children: [
                      for (final item in items)
                        Card(
                          child: ListTile(
                            title: Text(item.title),
                            subtitle: Text([
                              item.subtitle,
                              item.detail,
                              if (item.kind ==
                                      OperationalNotificationKind.followUp &&
                                  item.dueAt != null)
                                'Agendado para ${DateFormat('dd/MM HH:mm').format(item.dueAt!.toLocal())}',
                              if (item.dueOn case final DateTime date)
                                'Prazo ${DateFormat('dd/MM/yyyy').format(date)}${item.dueAt!.isBefore(DateTime.now()) ? ' · Em atraso' : ''}',
                            ].join('\n')),
                            onTap: () => _open(item),
                            trailing: item.kind !=
                                    OperationalNotificationKind.tracking
                                ? IconButton(
                                    tooltip: 'Concluir pendência',
                                    icon:
                                        const Icon(Icons.check_circle_outline),
                                    onPressed: _completing.contains(item.id)
                                        ? null
                                        : () => _complete(item),
                                  )
                                : const Icon(Icons.chevron_right),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
