/// Decisão de reuso de cliente na conversão proposta→contrato.
///
/// A conversão procura um cliente existente pelo e-mail confirmado. Reusar em
/// silêncio já pendurou contrato no cadastro de OUTRA pessoa (caso real de
/// 2026-07-29: dois leads de teste com o mesmo e-mail — o contrato do segundo
/// saiu no cliente do primeiro e o lead nunca saiu do funil, porque o caminho
/// de reuso não gravava `users.lead_id`, que é o que classifica lead como
/// convertido em `lead_conversion.dart`).
///
/// A decisão é pura (sem I/O) para ser testável; quem aplica é
/// `view_edit_proposal_widget.dart`.
enum ClientReuseDecision {
  /// Sem cadastro ativo com o e-mail: segue o fluxo normal de criação.
  criarNovo,

  /// Recompra: o cliente existente já pertence a este lead. Reusa como hoje.
  reusarMesmoLead,

  /// Cliente existente sem lead vinculado (ex.: criado à mão na tela
  /// Clientes antes de 2026-07-29). Reusa E grava o `lead_id` — sem o
  /// vínculo o lead nunca sai da lista de leads.
  reusarEVincular,

  /// O e-mail pertence a um cliente de OUTRO lead. Converter penduraria o
  /// contrato (e o rastreio no app) no cadastro de outra pessoa — bloquear
  /// e pedir correção do e-mail.
  bloquearOutroLead,

  /// O e-mail pertence a um usuário que não é Cliente (perfil do painel,
  /// piloto, oficina). Nunca é alvo válido de conversão — bloquear.
  bloquearNaoCliente,
}

ClientReuseDecision decideClientReuse({
  required String proposalLeadId,
  required bool userExists,
  bool existingIsCliente = false,
  String? existingLeadId,
}) {
  if (!userExists) {
    return ClientReuseDecision.criarNovo;
  }
  if (!existingIsCliente) {
    return ClientReuseDecision.bloquearNaoCliente;
  }
  final linkedLeadId = existingLeadId?.trim() ?? '';
  if (linkedLeadId.isEmpty) {
    return ClientReuseDecision.reusarEVincular;
  }
  return linkedLeadId == proposalLeadId
      ? ClientReuseDecision.reusarMesmoLead
      : ClientReuseDecision.bloquearOutroLead;
}
