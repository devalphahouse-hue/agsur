import 'commercial_theme.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '/backend/commercial.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/security/access_control.dart';
import 'commissions_widget.dart' show CommercialInput, commercialForm;

const signatureStatuses = {
  'draft': 'Em aprovação',
  'queued': 'Aguardando envio',
  'processing': 'Processando',
  'sent': 'Enviado',
  'viewed': 'Visualizado',
  'signed': 'Assinado',
  'declined': 'Recusado',
  'failed': 'Falha',
  'uncertain': 'Conferência necessária',
  'cancelled': 'Preparação descartada'
};
const _signatureEvents = {
  ...signatureStatuses,
  'signer_signed': 'Signatário assinou',
  'closed': 'Documento finalizado na Clicksign',
  'provider_cancelled': 'Cancelado na Clicksign',
  'expired': 'Prazo de assinatura encerrado',
};
String _date(dynamic value) => DateFormat('dd/MM/yyyy HH:mm')
    .format(DateTime.parse(value.toString()).toLocal());

Future<bool> _canPrepare() async {
  final uid = SupaFlow.client.auth.currentUser?.id;
  if (uid == null) return false;
  final u = await SupaFlow.client
      .from('users')
      .select('profile_type,access_level')
      .eq('id', uid)
      .single();
  return AccessControl.canEditFunil(AccessControl.roleOfStrings(
      u['profile_type'] as String?, u['access_level'] as String?));
}

/// Called with the exact bytes produced by the existing contract generator.
Future<void> offerContractSignature(
    BuildContext context, String proposalId, Uint8List bytes) async {
  try {
    if (!await _canPrepare() || !context.mounted) return;
    final prepare = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('PDF do contrato gerado'),
                content: const Text(
                    'Deseja preparar este mesmo PDF para aprovação e assinatura digital?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Agora não')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Preparar assinatura'))
                ]));
    if (prepare != true || !context.mounted) return;
    final contract = await SupaFlow.client
        .from('contract')
        .select('id')
        .eq('proposal_id', proposalId)
        .isFilter('cancelled_at', null)
        .single();
    if (context.mounted) {
      await prepareContractSignature(context, contract['id'] as String,
          bytes: bytes);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(commercialError(e))));
    }
  }
}

Future<void> prepareContractSignature(BuildContext context, String contractId,
    {Uint8List? bytes}) async {
  const provider = 'clicksign';
  final signers = <Map<String, String>>[];
  final approved = await commercialForm(context,
      title: 'Preparar contrato para assinatura',
      description:
          'Confira o PDF e os signatários antes de aprovar. O documento fica congelado. O envio depende da conexão com o serviço escolhido.',
      extra: (set) =>
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Serviço de assinatura'),
                subtitle: Text('Clicksign')),
            for (final s in signers)
              ListTile(
                  title: Text(s['name']!),
                  subtitle: Text(s['email']!),
                  trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => set(() => signers.remove(s)))),
            TextButton.icon(
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Adicionar signatário'),
                onPressed: signers.length >= 10
                    ? null
                    : () async {
                        final s = await commercialForm(context,
                            title: 'Signatário',
                            fields: const [
                              CommercialInput('name', 'Nome completo',
                                  maxLength: 160),
                              CommercialInput('email', 'E-mail', maxLength: 254)
                            ]);
                        if (s != null) set(() => signers.add(s));
                      }),
          ]),
      fields: const []);
  if (approved == null || !context.mounted) return;
  if (signers.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um signatário.')));
    return;
  }
  if (bytes == null) {
    final pick = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
    if (pick == null) return;
    bytes = pick.files.single.bytes;
  }
  if (!context.mounted) return;
  if (bytes == null ||
      bytes.length > 15 * 1024 * 1024 ||
      bytes.length < 5 ||
      String.fromCharCodes(bytes.take(5)) != '%PDF-') {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um PDF válido de até 15 MB.')));
    return;
  }
  final id = const Uuid().v4();
  final uid = SupaFlow.client.auth.currentUser!.id;
  final path = '$uid/$id/source.pdf';
  // Upload is never overwritten. No automatic retry after an uncertain mutation.
  await SupaFlow.client.storage.from('contract-signatures').uploadBinary(
      path, bytes,
      fileOptions:
          const FileOptions(contentType: 'application/pdf', upsert: false));
  await SupaFlow.client.rpc('signature_prepare', params: {
    'p_id': id,
    'p_contract': contractId,
    'p_provider': provider,
    'p_source_path': path,
    'p_sha256': sha256.convert(bytes).toString(),
    'p_signers': signers
  });
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Documento salvo. Revise e aprove em Assinaturas digitais.')));
  }
}

class SignaturesWidget extends StatefulWidget {
  const SignaturesWidget({super.key});
  static const routeName = 'Signatures';
  static const routePath = '/signatures';
  @override
  State<SignaturesWidget> createState() => _SignaturesState();
}

class _SignaturesState extends State<SignaturesWidget> {
  late Future<Map<String, dynamic>> _future;
  bool _edit = false, _busy = false;
  String _status = 'all';
  int _page = 0;
  Timer? _timer;
  Map<String, dynamic>? _connection;
  String get _connectionMessage {
    if (_connection?['enabled'] != true) {
      return 'Ativação da Clicksign pendente. Prepare e revise os documentos; os contratos aprovados ficam na fila até a integração ser configurada e habilitada.';
    }
    if (_connection?['environment'] == 'sandbox') {
      return 'Clicksign conectada ao ambiente de testes. As assinaturas deste ambiente não têm validade jurídica.';
    }
    return 'Clicksign conectada. Documentos aprovados seguem para envio e os retornos são registrados automaticamente.';
  }

  @override
  void initState() {
    super.initState();
    _future = _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !_busy) _refresh();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() async {
    _edit = await _canPrepare();
    try {
      final response = await SupaFlow.client.functions
          .invoke('contract-signatures', method: HttpMethod.get);
      _connection = response.status == 200
          ? Map<String, dynamic>.from(response.data as Map)
          : null;
    } catch (_) {
      _connection = null;
    }
    return Map<String, dynamic>.from(await SupaFlow.client.rpc('signature_list',
        params: {'p_status': _status, 'p_page': _page}) as Map);
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  Future<void> _act(Future<void> Function() f) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await f();
      if (mounted) _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(commercialError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _new() async {
    final contract = await showDialog<String>(
        context: context, builder: (_) => const _ContractPicker());
    if (contract != null && mounted) {
      await prepareContractSignature(context, contract);
    }
  }

  Future<void> _pdf(String path) async {
    await openPrivateStorageDoc('contract-signatures', path,
        expiresInSeconds: 120);
  }

  Future<void> _approve(Map<String, dynamic> r) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Aprovar envio para assinatura?'),
                content: const Text(
                    'Confirme que conferiu o PDF e os signatários. A aprovação autoriza o serviço conectado a enviar este contrato às partes.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Aprovar envio'))
                ]));
    if (ok == true) {
      await SupaFlow.client.rpc('signature_approve', params: {'p_id': r['id']});
    }
  }

  Future<void> _withdraw(Map<String, dynamic> r) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Descartar esta preparação?'),
                content: const Text(
                    'O PDF e o histórico serão preservados. Você poderá preparar uma nova versão para aprovação.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Voltar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Descartar'))
                ]));
    if (ok == true) {
      await SupaFlow.client
          .rpc('signature_withdraw', params: {'p_id': r['id']});
    }
  }

  Future<void> _details(Map<String, dynamic> r) async {
    final e = await SupaFlow.client
        .from('contract_signature_envelopes')
        .select('signers,approved_at')
        .eq('id', r['id'])
        .single();
    final events = await SupaFlow.client
        .from('contract_signature_events')
        .select('event_type,occurred_at,signer_email')
        .eq('envelope_id', r['id'])
        .order('occurred_at')
        .limit(200);
    if (!mounted) return;
    await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Signatários e histórico'),
                content: SizedBox(
                    width: 560,
                    child: SingleChildScrollView(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          for (final s in e['signers'] as List)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                    '${s['name']} • ${s['email']}\n${events.any((v) => v['event_type'] == 'signer_signed' && v['signer_email']?.toString().toLowerCase() == s['email']?.toString().toLowerCase()) ? 'Assinatura recebida' : 'Sem confirmação de assinatura'}')),
                          Text(e['approved_at'] == null
                              ? 'Aguardando aprovação comercial.'
                              : 'Aprovado em ${_date(e['approved_at'])}'),
                          for (final event in events)
                            Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                    '${_date(event['occurred_at'])} • ${_signatureEvents[event['event_type']] ?? event['event_type']} ${event['signer_email'] ?? ''}')),
                        ]))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Fechar'))
                ]));
  }

  @override
  Widget build(BuildContext context) => CommercialTheme(
      child: AppListScaffold(
          eyebrow: 'GESTÃO COMERCIAL',
          title: 'Assinaturas digitais',
          description:
              'Aprovação comercial, acompanhamento e PDFs privados dos contratos.',
          actions: [
            IconButton(
                tooltip: 'Atualizar',
                onPressed: _busy ? null : _refresh,
                icon: const Icon(Icons.refresh))
          ],
          body: FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(commercialError(snapshot.error!));
                }
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final rows = List<Map<String, dynamic>>.from(
                    snapshot.data!['rows'] as List);
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(spacing: 16, runSpacing: 12, children: [
                        SizedBox(
                            width: 240,
                            child: DropdownButtonFormField<String>(
                                initialValue: _status,
                                decoration: const InputDecoration(
                                    labelText: 'Situação'),
                                items: [
                                  const DropdownMenuItem(
                                      value: 'all', child: Text('Todas')),
                                  for (final s in signatureStatuses.entries)
                                    DropdownMenuItem(
                                        value: s.key, child: Text(s.value))
                                ],
                                onChanged: (v) {
                                  _status = v!;
                                  _page = 0;
                                  _refresh();
                                })),
                        if (_edit)
                          FilledButton.icon(
                              onPressed: _busy ? null : () => _act(_new),
                              icon: const Icon(Icons.add),
                              label: const Text('Preparar contrato')),
                      ]),
                      const SizedBox(height: 16),
                      Card(
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(_connectionMessage))),
                      if (rows.isEmpty)
                        const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Nenhum contrato neste filtro.')),
                      for (final r in rows)
                        Card(
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'Contrato ${r['proposal_ref']} • ${r['client_name'] ?? ''}'),
                                      Text(
                                          '${r['aircraft_model'] ?? ''} • ${r['provider']} • ${signatureStatuses[r['status']]}'),
                                      Text(
                                          'Criado em ${_date(r['created_at'])}'),
                                      if (r['status'] == 'uncertain')
                                        const Text(
                                            'Confira o envelope no serviço antes de qualquer novo envio.'),
                                      Wrap(spacing: 12, children: [
                                        TextButton(
                                            onPressed: _busy
                                                ? null
                                                : () => _act(() => _pdf(
                                                    r['source_path']
                                                        as String)),
                                            child: const Text('Conferir PDF')),
                                        TextButton(
                                            onPressed: _busy
                                                ? null
                                                : () => _act(() => _details(r)),
                                            child: const Text(
                                                'Signatários e histórico')),
                                        if (_edit && r['status'] == 'draft')
                                          FilledButton(
                                              onPressed: _busy
                                                  ? null
                                                  : () =>
                                                      _act(() => _approve(r)),
                                              child:
                                                  const Text('Aprovar envio')),
                                        if (_edit &&
                                            ['draft', 'queued']
                                                .contains(r['status']))
                                          TextButton(
                                              onPressed: _busy
                                                  ? null
                                                  : () =>
                                                      _act(() => _withdraw(r)),
                                              child: const Text(
                                                  'Descartar preparação')),
                                        if (r['signed_path'] != null)
                                          TextButton.icon(
                                              onPressed: _busy
                                                  ? null
                                                  : () => _act(() => _pdf(
                                                      r['signed_path']
                                                          as String)),
                                              icon: const Icon(Icons.download),
                                              label: const Text('PDF assinado'))
                                      ]),
                                    ]))),
                      Wrap(
                          spacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            TextButton(
                                onPressed: _page == 0 || _busy
                                    ? null
                                    : () {
                                        _page--;
                                        _refresh();
                                      },
                                child: const Text('Anterior')),
                            Text('Página ${_page + 1}'),
                            TextButton(
                                onPressed: (_page + 1) * 25 >=
                                            (snapshot.data!['count'] as num) ||
                                        _busy
                                    ? null
                                    : () {
                                        _page++;
                                        _refresh();
                                      },
                                child: const Text('Próxima'))
                          ]),
                    ]);
              })));
}

class _ContractPicker extends StatefulWidget {
  const _ContractPicker();
  @override
  State<_ContractPicker> createState() => _ContractPickerState();
}

class _ContractPickerState extends State<_ContractPicker> {
  final _search = TextEditingController();
  int _page = 0;
  late Future<List<dynamic>> _future;
  Future<List<dynamic>> _load() async =>
      await SupaFlow.client.rpc('signature_contract_choices',
          params: {'p_query': _search.text.trim(), 'p_page': _page}) as List;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _future = _load());
  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Selecionar contrato'),
          content: SizedBox(
              width: 580,
              height: 420,
              child: Column(children: [
                TextField(
                    controller: _search,
                    decoration: InputDecoration(
                        labelText: 'Número do contrato ou nome do cliente',
                        suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              _page = 0;
                              _refresh();
                            })),
                    onSubmitted: (_) {
                      _page = 0;
                      _refresh();
                    }),
                Expanded(
                    child: FutureBuilder<List<dynamic>>(
                        future: _future,
                        builder: (context, s) {
                          if (s.hasError) {
                            return Text(commercialError(s.error!));
                          }
                          if (!s.hasData) {
                            return const LinearProgressIndicator();
                          }
                          return Column(children: [
                            Expanded(
                                child: ListView(children: [
                              for (final c in s.data!)
                                ListTile(
                                    title: Text(
                                        'Contrato ${c['proposal_ref']} • ${c['client_name'] ?? ''}'),
                                    subtitle: Text(
                                        c['aircraft_model']?.toString() ?? ''),
                                    onTap: () => Navigator.pop(
                                        context, c['id'] as String))
                            ])),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                      onPressed: _page == 0
                                          ? null
                                          : () {
                                              _page--;
                                              _refresh();
                                            },
                                      child: const Text('Anterior')),
                                  TextButton(
                                      onPressed: s.data!.length < 25
                                          ? null
                                          : () {
                                              _page++;
                                              _refresh();
                                            },
                                      child: const Text('Próxima'))
                                ])
                          ]);
                        }))
              ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'))
          ]);
}
