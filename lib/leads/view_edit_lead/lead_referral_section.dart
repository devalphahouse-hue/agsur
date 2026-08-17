import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/backend/commission.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/security/action_feedback.dart';
import '/security/write_guard.dart';

/// Seção "Indicação de venda" da tela do lead.
///
/// Marca que a venda veio de indicação de terceiro e guarda quem indicou
/// (migration `20260817120000`). O efeito real acontece na conversão
/// proposta→contrato: lead marcado paga US$ 4.500,00 de comissão ao vendedor
/// em vez de US$ 7.500,00 — a régua inteira vive em `backend/commission.dart`.
///
/// Por que uma seção própria, fora do widget gerado: `view_edit_lead_widget`
/// tem ~3.500 linhas de FlutterFlow e monta seus campos a partir da RPC
/// `getLeadDetails`, que não devolve as colunas de indicação. Enfiar estado
/// novo lá dentro morreria na próxima regeneração. Mesmo padrão do
/// `contract_aircraft_unit_section.dart`.
///
/// Salva sozinha (botão próprio), sem depender do "Atualizar dados" da página.
class LeadReferralSection extends StatefulWidget {
  const LeadReferralSection({
    super.key,
    required this.leadId,
    required this.canEdit,
  });

  final String leadId;

  /// `AccessControl.canEditFunil`. Quem não edita apenas visualiza — a RLS de
  /// `leads` é o guarda real.
  final bool canEdit;

  @override
  State<LeadReferralSection> createState() => _LeadReferralSectionState();
}

class _LeadReferralSectionState extends State<LeadReferralSection> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _phoneMask = MaskTextInputFormatter(mask: '(##) # ####.####');

  bool _isReferral = false;
  bool _loading = true;
  bool _busy = false;
  String? _erroNome;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await LeadsTable().queryRows(
        queryFn: (q) => q.eqOrNull('id', widget.leadId),
      );
      final lead = rows.firstOrNull;
      if (!mounted) return;
      setState(() {
        _isReferral = lead?.isReferral ?? false;
        _nameCtrl.text = lead?.referralName ?? '';
        _applyPhone(lead?.referralPhone ?? '');
        _emailCtrl.text = lead?.referralEmail ?? '';
        final v = lead?.referralAgreedValue;
        _valueCtrl.text = v == null ? '' : v.toStringAsFixed(2).replaceAll('.', ',');
        _loading = false;
      });
    } catch (e, st) {
      // Falha de leitura não derruba a tela do lead: a seção some e o erro
      // vai para o Sentry.
      Sentry.captureException(e,
          stackTrace: st,
          withScope: (s) => s.setTag('acao', 'lead.indicacao_load'));
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    _phoneCtrl.text = _phoneMask.maskText(digits);
    _phoneMask.updateMask(
        newValue: TextEditingValue(text: _phoneCtrl.text));
  }

  /// `null` quando vazio ou ilegível — nunca 0, para não confundir "não
  /// combinado" com "combinado zero". Aceita "4.500,00" e "4500.00".
  double? get _agreedValue {
    final raw = _valueCtrl.text.trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw
        .replaceAll(RegExp(r'[^0-9,.]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.'));
  }

  Future<void> _save() async {
    if (_busy) return;

    // Espelha o CHECK `leads_referral_coerente`: indicação sem quem indicou o
    // banco recusa — melhor barrar aqui com mensagem do que levar um 23514.
    final nome = _nameCtrl.text.trim();
    if (_isReferral && nome.isEmpty) {
      setState(() => _erroNome = 'Informe quem indicou');
      return;
    }
    setState(() {
      _erroNome = null;
      _busy = true;
    });

    // Desmarcado limpa tudo: nome/valor pendurados num lead que deixou de ser
    // indicação violariam o CHECK e sujariam o card INDICAÇÃO futuro.
    final referral = _isReferral
        ? ReferralInfo(
            name: nome,
            phone: _phoneCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            agreedValue: _agreedValue,
          )
        : null;

    final ok = await guardWrite(
      context,
      () => LeadsTable().update(
        data: leadReferralColumns(referral),
        matchingRows: (q) => q.eqOrNull('id', widget.leadId),
        returnRows: true,
      ),
      contexto: 'lead.indicacao_salvar',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      showActionSuccess(
        context,
        _isReferral ? 'Indicação salva' : 'Indicação removida',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 96,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign_outlined,
                  size: 18, color: const Color(0xFFC2D51C)),
              const SizedBox(width: 8),
              Text(
                'Indicação de venda',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Marcado, a comissão do vendedor nesta venda passa de US\$ 7.500,00 '
            'para US\$ 4.500,00. Vale a partir da próxima conversão em contrato.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.55),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: widget.canEdit
                ? () => setState(() {
                      _isReferral = !_isReferral;
                      _erroNome = null;
                    })
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: _isReferral,
                    onChanged: widget.canEdit
                        ? (v) => setState(() {
                              _isReferral = v ?? false;
                              _erroNome = null;
                            })
                        : null,
                    side: const BorderSide(
                        color: Color(0x66FFFFFF), width: 1.4),
                    activeColor: const Color(0xFFC2D51C),
                    checkColor: const Color(0xFF313131),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta venda veio de indicação de terceiro',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isReferral) ...[
            const SizedBox(height: 12),
            AppFormField(
              controller: _nameCtrl,
              label: 'Nome de quem indicou',
              placeholder: 'Ex.: João Pereira',
              icon: Icons.person_pin_circle_outlined,
              required: true,
              enabled: widget.canEdit,
              onChanged: (_) {
                if (_erroNome != null) setState(() => _erroNome = null);
              },
            ),
            if (_erroNome != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 2),
                child: Text(
                  _erroNome!,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFE57373)),
                ),
              ),
            const SizedBox(height: 12),
            ResponsiveRow(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppFormField(
                    controller: _phoneCtrl,
                    label: 'Telefone',
                    placeholder: '(00) 9 0000.0000',
                    icon: Icons.phone_iphone_rounded,
                    enabled: widget.canEdit,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_phoneMask],
                  ),
                ),
                Expanded(
                  child: AppFormField(
                    controller: _emailCtrl,
                    label: 'E-mail',
                    placeholder: 'nome@email.com',
                    icon: Icons.alternate_email_rounded,
                    enabled: widget.canEdit,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppFormField(
              controller: _valueCtrl,
              label: 'Valor acordado (US\$)',
              placeholder: '0,00',
              icon: Icons.attach_money_rounded,
              enabled: widget.canEdit,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
          if (widget.canEdit) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: AppPrimaryButton(
                label: 'Salvar indicação',
                icon: Icons.check_rounded,
                busy: _busy,
                onPressed: _save,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
