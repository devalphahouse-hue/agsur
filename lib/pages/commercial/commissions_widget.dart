import 'commercial_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '/backend/commercial.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';

String _money(dynamic n) =>
    NumberFormat.currency(locale: 'pt_BR', symbol: 'US\$').format(n ?? 0);
String _date(dynamic d) => d == null
    ? '—'
    : DateFormat('dd/MM/yyyy HH:mm')
        .format(DateTime.parse(d.toString()).toLocal());

class CommissionsWidget extends StatefulWidget {
  const CommissionsWidget({super.key});
  static const routeName = 'Commissions';
  static const routePath = '/commissions';
  @override
  State<CommissionsWidget> createState() => _CommissionsState();
}

class _CommissionsState extends State<CommissionsWidget> {
  late Future<Map<String, dynamic>> _future;
  bool _master = false;
  bool _busy = false;
  int _tab = 0, _page = 0;
  String _status = 'all';
  String? _beneficiary;
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _until = DateTime(DateTime.now().year, DateTime.now().month + 1);
  List<Map<String, dynamic>> _people = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final uid = SupaFlow.client.auth.currentUser?.id;
    if (uid == null) throw StateError('Sessão encerrada');
    final user = await SupaFlow.client
        .from('users')
        .select('profile_type')
        .eq('id', uid)
        .single();
    _master = user['profile_type'] == 'Admin Master';
    if (_master) {
      _people = List<Map<String, dynamic>>.from(
          await SupaFlow.client.rpc('commission_beneficiaries') as List);
    }
    if (_tab == 1 && _master) {
      return {
        'rows': await SupaFlow.client
            .rpc('commission_sale_balances', params: {'p_page': _page})
      };
    }
    if (_tab == 2 && _master) {
      return {
        'rows': await SupaFlow.client
            .from('commission_rules')
            .select()
            .order('effective_at', ascending: false)
            .range(_page * 25, _page * 25 + 24)
      };
    }
    return commissionStatement(
        from: _from,
        until: _until,
        status: _status,
        beneficiary: _beneficiary,
        page: _page);
  }

  void _refresh({bool reset = false}) {
    if (reset) _page = 0;
    setState(() => _future = _load());
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        _refresh();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro confirmado.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(commercialError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _period(bool start) async {
    final d = await showDatePicker(
        context: context,
        initialDate: start ? _from : _until,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (d == null || !mounted) return;
    if ((start && !d.isBefore(_until)) || (!start && !d.isAfter(_from))) return;
    if (start) {
      _from = d;
    } else {
      _until = d;
    }
    _refresh(reset: true);
  }

  Future<void> _settle(Map<String, dynamic> row) async {
    final values = await commercialForm(context,
        title: 'Registrar pagamento de ${_money(row['net'])}',
        description:
            'Registra a liquidação no extrato. Informe a referência do pagamento realizado.',
        fields: const [
          CommercialInput('reference', 'Referência / comprovante',
              maxLength: 160)
        ]);
    if (values == null || !mounted) return;
    final requestId = const Uuid().v4();
    await _mutate(() async {
      await SupaFlow.client.rpc('commission_settle', params: {
        'p_id': requestId,
        'p_allocation_id': row['id'],
        'p_reference': values['reference']
      });
    });
  }

  Future<void> _allocate(Map<String, dynamic> sale) async {
    String bucket = 'seller';
    String? person = _people.isEmpty ? null : _people.first['id'] as String;
    bool external = false;
    final values = await commercialForm(context,
        title: 'Ratear comissão',
        description:
            'Saldo vendedores: ${_money(sale['seller_available'])} • indicação: ${_money(sale['referral_available'])}. O valor bruto consome o saldo; deduções ficam registradas separadamente.',
        extra: (set) => Column(children: [
              DropdownButtonFormField<String>(
                  initialValue: bucket,
                  decoration: const InputDecoration(labelText: 'Origem'),
                  items: const [
                    DropdownMenuItem(
                        value: 'seller', child: Text('Vendedores')),
                    DropdownMenuItem(
                        value: 'referral', child: Text('Indicação'))
                  ],
                  onChanged: (v) => set(() => bucket = v!)),
              SwitchListTile(
                  title: const Text('Beneficiário externo'),
                  value: external,
                  onChanged: (v) => set(() => external = v)),
              if (!external)
                DropdownButtonFormField<String>(
                    initialValue: person,
                    decoration:
                        const InputDecoration(labelText: 'Beneficiário'),
                    items: _people
                        .map((p) => DropdownMenuItem(
                            value: p['id'] as String,
                            child: Text(p['name']?.toString() ?? 'Sem nome')))
                        .toList(),
                    onChanged: (v) => person = v),
            ]),
        fields: const [
          CommercialInput('external', 'Nome do beneficiário externo',
              required: false, maxLength: 160),
          CommercialInput('gross', 'Valor bruto em US\$ (sem milhar)',
              decimal: true),
          CommercialInput('deduction', 'Dedução em US\$',
              decimal: true, initial: '0'),
          CommercialInput('reason', 'Motivo da dedução',
              required: false, maxLength: 300)
        ]);
    if (values == null || !mounted) return;
    if ((external && values['external']!.trim().isEmpty) ||
        (!external && person == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe o beneficiário.')));
      return;
    }
    final id = const Uuid().v4();
    await _mutate(() async {
      await SupaFlow.client.rpc('commission_allocate', params: {
        'p_id': id,
        'p_sale_id': sale['sale_id'],
        'p_beneficiary_id': external ? null : person,
        'p_external_name': external ? values['external'] : null,
        'p_bucket': bucket,
        'p_gross': commercialDecimal(values['gross']!),
        'p_deduction': commercialDecimal(values['deduction']!),
        'p_reason': values['reason']
      });
    });
  }

  Future<void> _rule() async {
    var effective = DateTime.now().add(const Duration(days: 1));
    final tiers = <Map<String, String>>[];
    final values = await commercialForm(context,
        title: 'Nova versão da regra',
        description:
            'A regra vale apenas para novas vendas a partir da vigência. Percentuais são informados em %. Entre as faixas que atingirem preço e meta mensal da empresa (UTC), vence a de maior preço mínimo e depois maior meta.',
        extra: (set) =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text(
                      'Vigência: ${DateFormat('dd/MM/yyyy HH:mm').format(effective)}'),
                  onPressed: () async {
                    final d = await showDatePicker(
                        context: context,
                        initialDate: effective,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100));
                    if (d == null || !mounted) return;
                    final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(effective));
                    if (t != null) {
                      set(() => effective =
                          DateTime(d.year, d.month, d.day, t.hour, t.minute));
                    }
                  }),
              for (final t in tiers)
                ListTile(
                    title: Text(
                        'A partir de US\$ ${t['price']} e ${t['sales']} venda(s): US\$ ${t['fixed']} + ${t['rate']}%'),
                    trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => set(() => tiers.remove(t)))),
              TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar faixa / meta mensal'),
                  onPressed: () async {
                    final tier = await commercialForm(context,
                        title: 'Faixa de comissão',
                        fields: const [
                          CommercialInput('price', 'Preço mínimo em US\$',
                              decimal: true, initial: '0'),
                          CommercialInput(
                              'sales', 'Quantidade mínima de vendas no mês',
                              integer: true, initial: '1'),
                          CommercialInput('fixed', 'Valor fixo em US\$',
                              decimal: true),
                          CommercialInput(
                              'rate', 'Percentual sobre a venda (%)',
                              decimal: true, initial: '0')
                        ]);
                    if (tier != null) set(() => tiers.add(tier));
                  }),
            ]),
        fields: const [
          CommercialInput('label', 'Nome da regra', maxLength: 120),
          CommercialInput('company', 'Percentual AGSur (%)',
              decimal: true, initial: '2'),
          CommercialInput('fixed', 'Bolo fixo vendedores em US\$',
              decimal: true, initial: '7500'),
          CommercialInput('rate', 'Percentual adicional vendedores (%)',
              decimal: true, initial: '0'),
          CommercialInput('referral', 'Repasse de indicação em US\$',
              decimal: true, initial: '3000')
        ]);
    if (values == null || !mounted) return;
    // Rates are converted to decimal by moving digits, preserving exact text.
    String percent(String s) {
      final d = commercialDecimal(s)!;
      final parts = d.split('.');
      final digits =
          '${parts[0]}${(parts.length > 1 ? parts[1] : '').padRight(2, '0')}';
      return '${int.parse(digits) ~/ 10000}.${(int.parse(digits) % 10000).toString().padLeft(4, '0')}';
    }

    await _mutate(() async {
      await SupaFlow.client.rpc('commission_create_rule', params: {
        'p_label': values['label'],
        'p_effective_at': effective.toUtc().toIso8601String(),
        'p_company_rate': percent(values['company']!),
        'p_seller_fixed': commercialDecimal(values['fixed']!),
        'p_seller_rate': percent(values['rate']!),
        'p_referral_fixed': commercialDecimal(values['referral']!),
        'p_tiers': tiers
            .map((t) => {
                  'min_price': commercialDecimal(t['price']!),
                  'min_sales': int.parse(t['sales']!),
                  'fixed': commercialDecimal(t['fixed']!),
                  'rate': percent(t['rate']!)
                })
            .toList()
      });
    });
  }

  @override
  Widget build(BuildContext context) => CommercialTheme(
      child: AppListScaffold(
          eyebrow: 'GESTÃO COMERCIAL',
          title: 'Comissões',
          description: 'Rateio, extratos e pagamentos registrados em US\$.',
          actions: [
            IconButton(
                tooltip: 'Atualizar',
                onPressed: _busy ? null : () => _refresh(),
                icon: const Icon(Icons.refresh))
          ],
          body: FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(commercialError(snapshot.error!)),
                        TextButton(
                            onPressed: () => _refresh(),
                            child: const Text('Tentar novamente'))
                      ]);
                }
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final data = snapshot.data!;
                final rows =
                    List<Map<String, dynamic>>.from(data['rows'] as List);
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_master)
                        Wrap(spacing: 8, children: [
                          for (var i = 0; i < 3; i++)
                            ChoiceChip(
                                label: Text([
                                  'Extratos',
                                  'Rateio de vendas',
                                  'Regras comerciais'
                                ][i]),
                                selected: _tab == i,
                                onSelected: _busy
                                    ? null
                                    : (_) {
                                        _tab = i;
                                        _refresh(reset: true);
                                      })
                        ]),
                      const SizedBox(height: 16),
                      if (_tab == 0) ...[
                        Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              OutlinedButton(
                                  onPressed: () => _period(true),
                                  child: Text(
                                      'De ${DateFormat('dd/MM/yyyy').format(_from)}')),
                              OutlinedButton(
                                  onPressed: () => _period(false),
                                  child: Text(
                                      'Até ${DateFormat('dd/MM/yyyy').format(_until)} (não inclui esta data)')),
                              SizedBox(
                                  width: 170,
                                  child: DropdownButtonFormField<String>(
                                      initialValue: _status,
                                      decoration: const InputDecoration(
                                          labelText: 'Situação'),
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'all', child: Text('Todas')),
                                        DropdownMenuItem(
                                            value: 'due',
                                            child: Text('A liquidar')),
                                        DropdownMenuItem(
                                            value: 'paid', child: Text('Pagas'))
                                      ],
                                      onChanged: (v) {
                                        _status = v!;
                                        _refresh(reset: true);
                                      })),
                              if (_master)
                                SizedBox(
                                    width: 240,
                                    child: DropdownButtonFormField<String>(
                                        initialValue: _beneficiary ?? '',
                                        decoration: const InputDecoration(
                                            labelText: 'Beneficiário'),
                                        items: [
                                          const DropdownMenuItem(
                                              value: '', child: Text('Todos')),
                                          ..._people.map((p) =>
                                              DropdownMenuItem(
                                                  value: p['id'] as String,
                                                  child: Text(
                                                      p['name']?.toString() ??
                                                          'Sem nome')))
                                        ],
                                        onChanged: (v) {
                                          _beneficiary = v == '' ? null : v;
                                          _refresh(reset: true);
                                        })),
                            ]),
                        const SizedBox(height: 16),
                        Wrap(spacing: 12, runSpacing: 12, children: [
                          for (final key in [
                            'provisioned',
                            'due',
                            'paid',
                            'deductions'
                          ])
                            Card(
                                child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text('${{
                                      'provisioned': 'Provisionado líquido',
                                      'due': 'A liquidar',
                                      'paid': 'Pago',
                                      'deductions': 'Deduções'
                                    }[key]}\n${_money(data[key])}')))
                        ]),
                      ],
                      if (_tab == 2 && _master)
                        Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                                onPressed: _busy ? null : _rule,
                                icon: const Icon(Icons.add),
                                label: const Text('Nova versão'))),
                      if (rows.isEmpty)
                        const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Nenhum registro para este período.')),
                      for (final r in rows)
                        Card(
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: _tab == 0
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                            Text(r['beneficiary_name']
                                                    ?.toString() ??
                                                'Beneficiário'),
                                            Text(
                                                'Bruto: ${_money(r['gross'])} • Dedução: ${_money(r['deduction'])} • Líquido: ${_money(r['net'])}'),
                                            Text(
                                                'Provisão: ${_date(r['created_at'])} • ${r['payment_id'] == null ? 'A liquidar' : 'Pago em ${_date(r['paid_at'])}'}'),
                                            if (r['deduction_reason'] != null)
                                              Text(
                                                  'Dedução: ${r['deduction_reason']}'),
                                            if (r['reference'] != null)
                                              Text(
                                                  'Referência: ${r['reference']}'),
                                            if (_master &&
                                                r['payment_id'] == null)
                                              TextButton(
                                                  onPressed: _busy
                                                      ? null
                                                      : () => _settle(r),
                                                  child: const Text(
                                                      'Registrar pagamento')),
                                          ])
                                    : _tab == 1
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                                Text(
                                                    'Venda ${r['proposal_ref'] ?? r['sale_id']}'),
                                                Text(
                                                    'AGSur: ${_money(r['company_amount'])} • Moeda: ${r['currency']}'),
                                                Text(
                                                    'Saldo para rateio: vendedores ${_money(r['seller_available'])} • indicação ${_money(r['referral_available'])}'),
                                                if (r['calculation']
                                                        ?['legacy'] ==
                                                    true)
                                                  const Text(
                                                      'Venda histórica: valores preservados; indicação não reconstruída.'),
                                                TextButton(
                                                    onPressed: _busy
                                                        ? null
                                                        : () => _allocate(r),
                                                    child: const Text(
                                                        'Definir beneficiário e rateio'))
                                              ])
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                                Text(r['label'].toString()),
                                                Text(
                                                    'Vigência: ${_date(r['effective_at'])} • AGSur: ${(r['company_rate'] as num) * 100}%'),
                                                Text(
                                                    'Vendedores: ${_money(r['seller_fixed'])} + ${(r['seller_rate'] as num) * 100}% • Indicação: ${_money(r['referral_fixed'])}'),
                                                Text(
                                                    '${(r['tiers'] as List).length} faixa(s) configurada(s)')
                                              ]))),
                      Wrap(
                          spacing: 16,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            TextButton(
                                onPressed: _busy || _page == 0
                                    ? null
                                    : () {
                                        _page--;
                                        _refresh();
                                      },
                                child: const Text('Anterior')),
                            Text('Página ${_page + 1}'),
                            TextButton(
                                onPressed: _busy ||
                                        (_tab == 0
                                            ? (_page + 1) * 25 >=
                                                (data['count'] as num)
                                            : rows.length < 25)
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

class CommercialInput {
  const CommercialInput(this.key, this.label,
      {this.required = true,
      this.decimal = false,
      this.integer = false,
      this.initial = '',
      this.maxLength = 120});
  final String key, label, initial;
  final bool required, decimal, integer;
  final int maxLength;
}

Future<Map<String, String>?> commercialForm(
  BuildContext context, {
  required String title,
  String? description,
  required List<CommercialInput> fields,
  Widget Function(void Function(VoidCallback))? extra,
}) =>
    showDialog<Map<String, String>>(
        context: context,
        builder: (_) => _CommercialFormDialog(
            title: title,
            description: description,
            fields: fields,
            extra: extra));

class _CommercialFormDialog extends StatefulWidget {
  const _CommercialFormDialog(
      {required this.title,
      this.description,
      required this.fields,
      this.extra});
  final String title;
  final String? description;
  final List<CommercialInput> fields;
  final Widget Function(void Function(VoidCallback))? extra;
  @override
  State<_CommercialFormDialog> createState() => _CommercialFormDialogState();
}

class _CommercialFormDialogState extends State<_CommercialFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _controllers = {
    for (final f in widget.fields) f.key: TextEditingController(text: f.initial)
  };
  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text(widget.title),
          content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                  child: Form(
                      key: _form,
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.description != null)
                              Text(widget.description!),
                            if (widget.extra != null)
                              widget.extra!((callback) {
                                if (mounted) setState(callback);
                              }),
                            for (final f in widget.fields)
                              Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: TextFormField(
                                      controller: _controllers[f.key],
                                      maxLength: f.maxLength,
                                      decoration:
                                          InputDecoration(labelText: f.label),
                                      keyboardType: f.decimal || f.integer
                                          ? const TextInputType
                                              .numberWithOptions(decimal: true)
                                          : TextInputType.text,
                                      validator: (v) {
                                        final text = v?.trim() ?? '';
                                        if (!f.required && text.isEmpty) {
                                          return null;
                                        }
                                        if (text.isEmpty) {
                                          return 'Campo obrigatório';
                                        }
                                        if (f.decimal &&
                                            commercialDecimal(text) == null) {
                                          return 'Use um valor positivo, sem milhar, com até 2 casas';
                                        }
                                        if (f.integer &&
                                            (!RegExp(r'^[0-9]{1,6}$')
                                                    .hasMatch(text) ||
                                                int.parse(text) < 1)) {
                                          return 'Informe uma quantidade maior que zero';
                                        }
                                        return null;
                                      }))
                          ])))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () {
                  if (_form.currentState!.validate()) {
                    Navigator.pop(context, {
                      for (final f in widget.fields)
                        f.key: _controllers[f.key]!.text.trim()
                    });
                  }
                },
                child: const Text('Confirmar'))
          ]);
}
