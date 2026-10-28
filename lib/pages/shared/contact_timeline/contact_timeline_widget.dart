import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/backend/contact_timeline.dart';
import '/backend/paged_query.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import 'whatsapp_preferences.dart';
import '/pages/shared/modal_register_note/modal_register_note_widget.dart';

/// Internal contact history shared by the lead and converted client screens.
class ContactTimelineWidget extends StatefulWidget {
  const ContactTimelineWidget({super.key, required this.leadId});
  final String? leadId;
  @override
  State<ContactTimelineWidget> createState() => _ContactTimelineState();
}

class _ContactTimelineState extends State<ContactTimelineWidget> {
  late Future<ContactTimelinePage> _future;
  Timer? _poll;
  int _page = 1;
  int _perPage = 10;
  bool _busy = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !_busy && !_loading && widget.leadId?.isNotEmpty == true) {
        _refresh();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ContactTimelineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leadId != widget.leadId) {
      _page = 1;
      _future = _load();
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<ContactTimelinePage> _load() async {
    final leadId = widget.leadId;
    if (leadId == null || leadId.isEmpty) {
      return ContactTimelinePage(
          notes: PagedResult.empty<Map<String, dynamic>>(_page, _perPage),
          dispatches: const {});
    }
    _loading = true;
    try {
      return await loadContactTimeline(leadId, page: _page, perPage: _perPage);
    } finally {
      _loading = false;
    }
  }

  void _refresh() {
    if (mounted) {
      final next = _load();
      setState(() {
        _future = next;
      });
    }
  }

  Future<void> _add() async {
    if (_busy || widget.leadId?.isNotEmpty != true) return;
    setState(() => _busy = true);
    try {
      await showDialog<void>(
          context: context,
          builder: (_) => Dialog(
                elevation: 0,
                insetPadding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                child: ModalRegisterNoteWidget(
                    leadId: widget.leadId,
                    onSaved: () async {
                      if (!mounted) return;
                      _page = 1;
                      _refresh();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text('Registro adicionado à linha do tempo.')));
                    }),
              ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _action(String rpc, Map<String, dynamic> row) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await SupaFlow.client.rpc(rpc, params: {
        'p_id': rpc == 'cancel_note_reminder' ? row['reminder_id'] : row['id']
      });
      _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Não foi possível alterar o envio. Atualize para conferir o estado atual.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _date(dynamic value) {
    final d = DateTime.tryParse(value?.toString() ?? '');
    return d == null
        ? 'Data indisponível'
        : DateFormat('dd/MM/yyyy HH:mm').format(d.toLocal());
  }

  Widget _dispatch(Map<String, dynamic> row) {
    final label = contactDeliveryLabel(row);
    final status = row['status'];
    final failed =
        row['status'] == 'Falha' || row['delivery_status'] == 'failed';
    final color = failed
        ? const Color(0xFFFF8A80)
        : ['Lido', 'Entregue'].contains(label)
            ? const Color(0xFF8ED7A4)
            : const Color(0xFFC2D51C);
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline,
                    size: 18, color: Colors.white70),
                Text('WhatsApp · ${row['recipient_name'] ?? 'Destinatário'}',
                    style: const TextStyle(color: Colors.white)),
                Text(label,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w600)),
              ]),
          if ((row['subject'] as String? ?? '').isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(row['subject'] as String,
                    style: const TextStyle(color: Colors.white70))),
          const SizedBox(height: 4),
          Text('Programado para ${_date(row['scheduled_at'])}',
              style: const TextStyle(color: Colors.white70)),
          if (row['sent_at'] != null)
            Text('Enviado em ${_date(row['sent_at'])}',
                style: const TextStyle(color: Colors.white70)),
          if (['delivered', 'read', 'failed']
                  .contains(row['delivery_status']) &&
              row['delivery_updated_at'] != null)
            Text('Atualizado em ${_date(row['delivery_updated_at'])}',
                style: const TextStyle(color: Colors.white70)),
          if (failed)
            Text(contactFailureMessage(row['error_code'] as String?),
                style: const TextStyle(color: Color(0xFFFF8A80))),
          if (row['attempt_count'] is num && (row['attempt_count'] as num) > 0)
            Text('${row['attempt_count']} tentativa(s)',
                style: const TextStyle(color: Colors.white54)),
          Wrap(spacing: 12, children: [
            if (status == 'Agendado' || status == 'Falha')
              TextButton(
                  onPressed:
                      _busy ? null : () => _action('cancel_note_reminder', row),
                  child: const Text('Cancelar envios deste registro')),
            if (status == 'Falha' &&
                row['error_code'] != 'dispatch_outcome_unknown' &&
                row['provider'] != 'dryrun')
              TextButton(
                  onPressed: _busy
                      ? null
                      : () => _action('retry_whatsapp_dispatch', row),
                  child: const Text('Tentar novamente')),
          ]),
        ]));
  }

  Widget _entry(
          Map<String, dynamic> note, List<Map<String, dynamic>> dispatches) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: const Color(0xFF313131),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 20, runSpacing: 8, children: [
            Text(_date(note['created_at']),
                style: const TextStyle(color: Colors.white70)),
            Text(
                'Registrado por ${note['created_by_name'] ?? 'Usuário não identificado'}',
                style: const TextStyle(color: Colors.white70)),
          ]),
          const SizedBox(height: 12),
          SelectableText(note['note']?.toString() ?? '',
              style: const TextStyle(color: Colors.white, height: 1.5)),
          if (dispatches.isNotEmpty) ...[
            const Divider(color: Colors.white24, height: 28),
            if (dispatches.length == 1)
              _dispatch(dispatches.single)
            else
              Theme(
                  data: ThemeData.dark(),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                        'Envios por WhatsApp · ${dispatches.length} destinatários'),
                    children: dispatches.map(_dispatch).toList(),
                  )),
          ],
        ]),
      );

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: const Color(0xFF404040),
            borderRadius: BorderRadius.circular(12)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Linha do tempo',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('Histórico interno de contatos e atividades',
                          style: TextStyle(color: Colors.white70)),
                    ]),
                Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                          tooltip: 'Preferências de contato',
                          onPressed: _busy || widget.leadId?.isNotEmpty != true
                              ? null
                              : () async {
                                  setState(() => _busy = true);
                                  await editWhatsAppPreference(
                                      context, widget.leadId!);
                                  if (mounted) {
                                    setState(() => _busy = false);
                                    _refresh();
                                  }
                                },
                          icon: const Icon(Icons.tune, color: Colors.white70)),
                      IconButton(
                          tooltip: 'Atualizar linha do tempo',
                          onPressed: _busy ? null : _refresh,
                          icon:
                              const Icon(Icons.refresh, color: Colors.white70)),
                      AppPrimaryButton(
                          label: 'Adicionar registro',
                          icon: Icons.add,
                          onPressed: _busy || widget.leadId?.isNotEmpty != true
                              ? null
                              : _add),
                    ]),
              ]),
          const Divider(color: Colors.white24, height: 32),
          if (widget.leadId?.isNotEmpty != true)
            const Text('Este cadastro não possui um contato vinculado.',
                style: TextStyle(color: Colors.white70))
          else
            FutureBuilder<ContactTimelinePage>(
                key: ValueKey(widget.leadId),
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                        'Não foi possível carregar a linha do tempo. Use Atualizar para tentar novamente.',
                        style: TextStyle(color: Colors.white70));
                  }
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator(
                        color: Color(0xFFC2D51C));
                  }
                  final data = snapshot.data!;
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const LinearProgressIndicator(
                              color: Color(0xFFC2D51C)),
                        if (data.historyUnavailable)
                          const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Text(
                                  'O histórico dos envios está temporariamente indisponível. As notas continuam disponíveis.',
                                  style: TextStyle(color: Color(0xFFFFD580)))),
                        if (data.notes.items.isEmpty)
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                  'Nenhum registro nesta linha do tempo.',
                                  style: TextStyle(color: Colors.white70))),
                        for (final note in data.notes.items)
                          _entry(note, data.dispatches[note['id']] ?? const []),
                        if (data.notes.total > 0)
                          AppPagination(
                              result: data.notes,
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
        ]),
      );
}
