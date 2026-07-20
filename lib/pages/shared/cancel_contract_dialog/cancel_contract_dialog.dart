import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/core_ui/core_ui.dart';

/// Motivos de cancelamento de contrato.
///
/// Conjunto fechado, espelhando o CHECK `contract_cancellation_reason_chk` da
/// migration 20260720120000. O código vai para o banco; o rótulo é só
/// apresentação — assim dá para agrupar "por que os contratos caem" num
/// relatório, o que texto livre nunca permitiria.
///
/// **Ao acrescentar um motivo aqui, acrescente também no CHECK** — senão o
/// banco recusa o cancelamento com erro de constraint.
enum MotivoCancelamento {
  desistenciaCliente('desistencia_cliente', 'Desistência do cliente'),
  reprovacaoCredito('reprovacao_credito', 'Reprovação de crédito'),
  problemaAeronave('problema_aeronave', 'Problema na aeronave'),
  condicoesComerciais('condicoes_comerciais', 'Condições comerciais'),
  outro('outro', 'Outro');

  const MotivoCancelamento(this.codigo, this.rotulo);
  final String codigo;
  final String rotulo;

  static String rotuloDe(String? codigo) => MotivoCancelamento.values
      .firstWhere(
        (m) => m.codigo == codigo,
        orElse: () => MotivoCancelamento.outro,
      )
      .rotulo;
}

/// Resultado do diálogo de cancelamento.
class CancelamentoInfo {
  const CancelamentoInfo({required this.motivo, required this.observacao});
  final MotivoCancelamento motivo;
  final String observacao;
}

/// Pergunta o motivo do cancelamento. Devolve `null` se o usuário desistiu.
///
/// O motivo é obrigatório; a observação é opcional — exceto em "Outro", em que
/// exigir a explicação é o mínimo para o registro servir de alguma coisa.
Future<CancelamentoInfo?> askCancelContract(
  BuildContext context, {
  required String referencia,
}) {
  return showDialog<CancelamentoInfo>(
    context: context,
    builder: (dialogContext) => _CancelDialog(referencia: referencia),
  );
}

/// Confirmação final, depois de escolhido o motivo.
///
/// Dois passos de propósito: o primeiro coleta, este confirma. Cancelar um
/// contrato mexe numa venda fechada e hoje não há tela para desfazer — então
/// vale repetir o que vai ser gravado antes de gravar.
Future<bool> confirmCancelSummary(
  BuildContext context, {
  required String referencia,
  required CancelamentoInfo info,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0x33F9CF58),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.help_outline_rounded,
                        color: Color(0xFFF9CF58), size: 21),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Confirmar o cancelamento?',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _Linha('Contrato', referencia),
              const SizedBox(height: 8),
              _Linha('Motivo', info.motivo.rotulo),
              if (info.observacao.isNotEmpty) ...[
                const SizedBox(height: 8),
                _Linha('Observação', info.observacao),
              ],
              const SizedBox(height: 16),
              Text(
                'O contrato continuará na lista, marcado como cancelado. '
                'Não há tela para reverter isso depois.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.4,
                  color: const Color(0xB3FFFFFF),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(
                      'Voltar',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: const Color(0xCCFFFFFF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF9CF58),
                      foregroundColor: const Color(0xFF1A1A1A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(
                      'Confirmar cancelamento',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return ok ?? false;
}

class _Linha extends StatelessWidget {
  const _Linha(this.rotulo, this.valor);
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            rotulo,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0x8AFFFFFF),
            ),
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _CancelDialog extends StatefulWidget {
  const _CancelDialog({required this.referencia});
  final String referencia;

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  MotivoCancelamento? _motivo;
  final _obs = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _obs.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (_motivo == null) {
      setState(() => _erro = 'Selecione o motivo do cancelamento.');
      return;
    }
    if (_motivo == MotivoCancelamento.outro && _obs.text.trim().isEmpty) {
      setState(() => _erro = 'Descreva o motivo na observação.');
      return;
    }
    Navigator.of(context).pop(
      CancelamentoInfo(motivo: _motivo!, observacao: _obs.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0x33F9CF58),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.block_rounded,
                        color: Color(0xFFF9CF58), size: 21),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Cancelar o contrato ${widget.referencia}?',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'O contrato não é excluído: ele continua na lista, marcado como '
                'cancelado, com o motivo registrado.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.4,
                  color: const Color(0xB3FFFFFF),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Motivo *',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xCCFFFFFF),
                ),
              ),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<MotivoCancelamento>(
                    isExpanded: true,
                    value: _motivo,
                    hint: Text(
                      'Selecione o motivo',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: const Color(0x8AFFFFFF),
                      ),
                    ),
                    dropdownColor: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(10),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0x99FFFFFF)),
                    style: GoogleFonts.inter(
                        fontSize: 13.5, color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    items: [
                      for (final m in MotivoCancelamento.values)
                        DropdownMenuItem(value: m, child: Text(m.rotulo)),
                    ],
                    onChanged: (v) => setState(() {
                      _motivo = v;
                      _erro = null;
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AppFormField(
                controller: _obs,
                label: _motivo == MotivoCancelamento.outro
                    ? 'Observação *'
                    : 'Observação',
                placeholder: 'Detalhe o que aconteceu (opcional)',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
              if (_erro != null) ...[
                const SizedBox(height: 12),
                Text(
                  _erro!,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFFFF7B82),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Voltar',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: const Color(0xCCFFFFFF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF9CF58),
                      foregroundColor: const Color(0xFF1A1A1A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                    onPressed: _confirmar,
                    child: Text(
                      'Cancelar contrato',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
