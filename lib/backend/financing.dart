/// Percentuais do financiamento da proposta, num lugar só.
///
/// **Por que existe:** o "Valor total do depósito" era lido de um campo da
/// tela, preenchido apenas no `onChanged` do depósito inicial. Quem não
/// digitasse nesse campo (ou mexesse no sinal depois) gravava
/// `proposal_financing.total_deposit = 0` — 2 das 6 propostas em produção
/// estavam assim (medido em 2026-09-22), e o cliente viu como "campo de
/// financiamento zerado". O total agora é calculado na hora de salvar, a
/// partir do sinal e do depósito inicial, e não depende de a tela ter
/// recalculado.
///
/// Tudo aqui é fração: 5% → `0.05`.
library;

/// Lê um percentual digitado ("5", "5%", "5,5", "  10 % ") como fração.
/// Devolve `null` quando não há número — diferente de zero, que é um valor
/// legítimo.
double? parsePercentToFraction(String? raw) {
  if (raw == null) return null;
  final cleaned = raw
      .replaceAll('%', '')
      .replaceAll(RegExp(r'\s'), '')
      .replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  final v = double.tryParse(cleaned);
  if (v == null) return null;
  return v / 100;
}

/// Total do depósito = sinal + depósito inicial (frações). Campo vazio conta
/// como zero, mas o resultado só é `null` quando os DOIS estão vazios — aí
/// não há o que gravar e quem chama decide se bloqueia.
double? totalDepositFraction({String? sinal, String? depositoInicial}) {
  final a = parsePercentToFraction(sinal);
  final b = parsePercentToFraction(depositoInicial);
  if (a == null && b == null) return null;
  return (a ?? 0) + (b ?? 0);
}

/// Prêmio (risco país) conforme o prazo, a partir do cadastro de Taxas.
///
/// O painel calculava `prazo == '5' ? 5% : 7%` chumbado na tela, ignorando
/// `financing_rates.premium_rate_five/seven` — o Admin editava Taxas e nada
/// acontecia (pendência registrada no CLAUDE.md; em produção o cadastro diz
/// 4,8% para 5 anos e as propostas gravaram 5%). Agora vem do cadastro, com o
/// valor antigo só como último recurso.
double premiumRateForTerm({
  required int termYears,
  double? premiumRateFive,
  double? premiumRateSeven,
}) {
  final fromRegistry = termYears <= 5 ? premiumRateFive : premiumRateSeven;
  if (fromRegistry != null && fromRegistry > 0) return fromRegistry;
  return termYears <= 5 ? 0.05 : 0.07;
}
