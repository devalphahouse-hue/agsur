import 'dart:async';
import 'package:flutter/material.dart';
import '/backend/paged_query.dart';
import '/backend/supabase/supabase.dart';
import '/backend/phone.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/security/access_control.dart';
import '/security/write_guard.dart';

class ReminderHistoryWidget extends StatelessWidget {
  const ReminderHistoryWidget({super.key});
  static const routeName = 'ReminderHistory';
  static const routePath = '/reminderHistory';
  @override
  Widget build(BuildContext context) => const AppListScaffold(
        eyebrow: 'FUNIL DE VENDAS',
        title: 'Lembretes WhatsApp',
        description:
            'Acompanhe os agendamentos, tentativas e confirmações de entrega.',
        body: ReminderHistoryPanel(),
      );
}

class ReminderHistoryPanel extends StatefulWidget {
  const ReminderHistoryPanel({super.key, this.leadId});
  final String? leadId;
  @override
  State<ReminderHistoryPanel> createState() => _ReminderHistoryPanelState();
}

class _ReminderHistoryPanelState extends State<ReminderHistoryPanel> {
  late Future<PagedResult<Map<String, dynamic>>> _future;
  Timer? _poll;
  Timer? _debounce;
  String _status = 'Todos';
  String _query = '';
  int _page = 1;
  int _perPage = 25;
  bool _busy = false;
  int _overdueCount = 0;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _load();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !_busy) _refresh();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<PagedResult<Map<String, dynamic>>> _load() async {
    var q = SupaFlow.client.from('vw_reminder_dispatches').select();
    if (widget.leadId != null) q = q.eq('lead_id', widget.leadId!);
    if (_status != 'Todos') q = q.eq('status', _status);
    if (_query.trim().isNotEmpty) {
      q = q.or(orIlike(
          ['recipient_name', 'lead_name', 'subject', 'message'], _query));
    }
    var health = SupaFlow.client
        .from('whatsapp_reminders')
        .select('id')
        .eq('status', 'Agendado')
        .lt(
            'next_attempt_at',
            DateTime.now()
                .toUtc()
                .subtract(const Duration(minutes: 10))
                .toIso8601String());
    if (widget.leadId != null) health = health.eq('lead_id', widget.leadId!);
    final healthResult = await health.limit(1).count(CountOption.exact);
    _overdueCount = healthResult.count;
    final page = _page;
    final perPage = _perPage;
    final result = await q
        .order('created_at', ascending: false)
        .order('id')
        .range((page - 1) * perPage, page * perPage - 1)
        .count(CountOption.exact);
    return PagedResult(
        items: List<Map<String, dynamic>>.from(result.data),
        total: result.count,
        page: page,
        perPage: perPage);
  }

  void _refresh() {
    if (mounted) setState(() => _future = _load());
  }

  Future<void> _act(String rpc, Map<String, dynamic> params) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await SupaFlow.client.rpc(rpc, params: params);
      _refresh();
    } catch (_) {
      if (mounted) {
        showWriteError(context,
            'Não foi possível executar. O envio pode estar em andamento ou sem permissão para esta ação.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _team() async {
    try {
      final rows = List<Map<String, dynamic>>.from(
          await SupaFlow.client.rpc('list_whatsapp_team_members'));
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          builder: (ctx) => StatefulBuilder(
              builder: (ctx, update) => AlertDialog(
                    title: const Text('Equipe de lembretes'),
                    content: SizedBox(
                        width: 550,
                        height: 400,
                        child: Column(children: [
                          const Text(
                              'Habilite somente pessoas que autorizaram o recebimento de avisos pelo WhatsApp.'),
                          Expanded(
                              child: ListView(
                                  children: rows
                                      .map((r) => SwitchListTile(
                                            title: Text(r['name'] as String),
                                            subtitle: Text(formatBrDisplay(
                                                r['phone'] as String?)),
                                            value: r['enabled'] == true,
                                            onChanged: (value) async {
                                              try {
                                                await SupaFlow.client.rpc(
                                                    'set_whatsapp_team_member',
                                                    params: {
                                                      'p_user_id': r['id'],
                                                      'p_enabled': value
                                                    });
                                                if (ctx.mounted) {
                                                  update(() =>
                                                      r['enabled'] = value);
                                                }
                                              } catch (_) {
                                                if (mounted && ctx.mounted) {
                                                  showWriteError(context,
                                                      'Não foi possível atualizar a equipe. Verifique telefone e permissões.');
                                                }
                                              }
                                            },
                                          ))
                                      .toList())),
                        ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Fechar'))
                    ],
                  )));
    } catch (_) {
      if (mounted) {
        showWriteError(context, 'Não foi possível carregar a equipe.');
      }
    }
  }

  Future<void> _preferences() async {
    try {
      final row = await SupaFlow.client
          .from('leads')
          .select('wa_opt_out')
          .eq('id', widget.leadId!)
          .single();
      if (!mounted) return;
      final blocked = row['wa_opt_out'] == true;
      final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: Text(blocked
                    ? 'Reativar lembretes do cliente?'
                    : 'Suspender lembretes do cliente?'),
                content: Text(blocked
                    ? 'Reative somente se o cliente autorizou receber mensagens no WhatsApp.'
                    : 'Os agendamentos pendentes para o cliente serão cancelados antes do próximo disparo. Avisos para a equipe e o vendedor continuam independentes.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Voltar')),
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Confirmar'))
                ],
              ));
      if (confirm == true) {
        await _act('set_whatsapp_opt_out',
            {'p_lead_id': widget.leadId, 'p_opt_out': !blocked});
      }
    } catch (_) {
      if (mounted) {
        showWriteError(context, 'Não foi possível carregar as preferências.');
      }
    }
  }

  Future<void> _attempts(String id) async {
    try {
      final rows = await SupaFlow.client
          .from('whatsapp_dispatch_attempts')
          .select()
          .eq('dispatch_id', id)
          .order('attempt_number');
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text('Tentativas de envio'),
                content: SizedBox(
                    width: 500,
                    height: 300,
                    child: rows.isEmpty
                        ? const Text('Nenhuma tentativa realizada.')
                        : ListView(
                            children: rows
                                .map((r) => ListTile(
                                    title: Text(
                                        'Tentativa ${r['attempt_number']} · ${r['outcome']}'),
                                    subtitle: Text(
                                        '${r['provider'] ?? 'Em processamento'}${r['error_code'] == null ? '' : ' · Erro ${r['error_code']}'}\n${r['provider_message_id'] ?? ''}')))
                                .toList())),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Fechar'))
                ],
              ));
    } catch (_) {
      if (mounted) {
        showWriteError(context, 'Não foi possível carregar as tentativas.');
      }
    }
  }

  String _failureMessage(String code) {
    switch (code) {
      case 'dispatch_outcome_unknown':
        return 'Resultado incerto. Confira na Meta se a mensagem foi enviada antes de criar outro lembrete.';
      case '190':
        return 'A conexão com a Meta precisa ser renovada por um administrador.';
      case '131026':
        return 'A Meta não conseguiu entregar. Confira o telefone e se o destinatário usa WhatsApp.';
      case '131042':
        return 'A configuração de pagamento da conta WhatsApp precisa ser revisada.';
      case '132001':
      case '132000':
      case '132005':
      case '132007':
        return 'O modelo da mensagem precisa ser revisado por um administrador.';
      case 'recipient_unavailable':
        return 'Destinatário desativado ou sem autorização para receber mensagens.';
      case '130429':
        return 'O limite temporário de envio da Meta foi atingido.';
      default:
        return 'Não foi possível enviar. Confira os detalhes nas tentativas (código $code).';
    }
  }

  Widget _entry(Map<String, dynamic> row) {
    final status = row['status'] as String;
    final dryRun = row['provider'] == 'dryrun';
    final date = DateTime.parse(row['scheduled_at'] as String).toLocal();
    final delivery = {
      'accepted': 'Aceito pela Meta',
      'sent': 'Enviado',
      'delivered': 'Entregue',
      'read': 'Lido',
      'failed': 'Falha na entrega'
    }[row['delivery_status']];
    final retryAt = DateTime.parse(row['next_attempt_at'] as String).toLocal();
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  '${row['recipient_name']} · $status${dryRun ? ' · Simulação (não enviado)' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                  '${row['lead_name']} · ${row['recipient_type']} · ${dateTimeFormat('dd/MM/yyyy HH:mm', date)}'),
              if ((row['subject'] as String? ?? '').isNotEmpty)
                Text(row['subject'] as String),
              Text(row['message'] as String),
              if (delivery != null) Text(delivery),
              if (row['error_code'] != null)
                Text(_failureMessage(row['error_code'] as String)),
              if (status == 'Agendado' && (row['attempt_count'] as int) > 0)
                Text(
                    'Próxima tentativa: ${dateTimeFormat('dd/MM/yyyy HH:mm', retryAt)}'),
              Wrap(spacing: 12, children: [
                TextButton(
                    onPressed: () => _attempts(row['id'] as String),
                    child: Text('Tentativas: ${row['attempt_count']}')),
                if (status == 'Agendado' || status == 'Falha')
                  TextButton(
                      onPressed: _busy
                          ? null
                          : () => _act('cancel_note_reminder',
                              {'p_id': row['reminder_id']}),
                      child:
                          const Text('Cancelar para todos os destinatários')),
                if (status == 'Falha' &&
                    row['error_code'] != 'dispatch_outcome_unknown' &&
                    !dryRun)
                  TextButton(
                      onPressed: _busy
                          ? null
                          : () => _act(
                              'retry_whatsapp_dispatch', {'p_id': row['id']}),
                      child: const Text('Reenviar')),
              ]),
            ])));
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 12, runSpacing: 8, children: [
          TextButton.icon(
              onPressed: _busy ? null : _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar')),
          if (AccessControl.current == PanelRole.adminMaster)
            TextButton.icon(
                onPressed: _busy ? null : _team,
                icon: const Icon(Icons.groups),
                label: const Text('Gerenciar equipe')),
          if (widget.leadId != null)
            TextButton(
                onPressed: _busy ? null : _preferences,
                child: const Text('Preferências do cliente')),
        ]),
        TextField(
            controller: _search,
            decoration: const InputDecoration(
                labelText: 'Buscar cliente, destinatário, assunto ou mensagem',
                prefixIcon: Icon(Icons.search)),
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), () {
                _query = v;
                _page = 1;
                _refresh();
              });
            }),
        const SizedBox(height: 12),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Todos',
              'Agendado',
              'Processando',
              'Enviado',
              'Falha',
              'Cancelado'
            ]
                .map((s) => ChoiceChip(
                    label: Text(s),
                    selected: _status == s,
                    onSelected: (_) {
                      _status = s;
                      _page = 1;
                      _refresh();
                    }))
                .toList()),
        const SizedBox(height: 12),
        FutureBuilder<PagedResult<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(children: [
                  const Text(
                      'Não foi possível carregar os lembretes. Tente novamente; se persistir, fale com um administrador.'),
                  TextButton(
                      onPressed: _refresh,
                      child: const Text('Tentar novamente'))
                ]);
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final page = snapshot.data!;
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_overdueCount > 0)
                      const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                              'Há lembretes atrasados há mais de 10 minutos. Verifique o agendador e a configuração de envio.')),
                    if (page.items.isEmpty)
                      const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Nenhum lembrete encontrado.')),
                    ...page.items.map(_entry),
                    AppPagination(
                        result: page,
                        onPageChanged: (p) {
                          _page = p;
                          _refresh();
                        },
                        onPerPageChanged: (p) {
                          _perPage = p;
                          _page = 1;
                          _refresh();
                        }),
                  ]);
            }),
      ]);
}
