import '/backend/supabase/supabase.dart';

/// O que será afetado por uma exclusão no funil — calculado ANTES de excluir,
/// para a modal poder avisar o usuário.
///
/// **Por que a cascata não é do banco.** Só três tabelas do funil têm
/// soft-delete: `leads.is_deleted`, `proposal.is_deleted` e
/// `user_aircraft.deleted`. Contrato, venda, financeiro, esteira, empresa e
/// notas NÃO têm. Então não existe um `ON DELETE CASCADE` que resolva: a
/// "exclusão" é uma combinação de marcações que faz cada tela parar de mostrar
/// o registro.
///
/// **O que some por tabelama:**
/// - `proposal.is_deleted = true` some com a proposta E com o contrato dela, de
///   graça: a `vw_contract_data` filtra por essa coluna. É por isso que excluir
///   contrato é marcar a proposta — a tabela `contract` não tem a coluna.
/// - `tracking` é a exceção: a `vw_all_tracking` **não filtra** nada, então a
///   esteira só some apagando as linhas de verdade. É irreversível, mas as 21
///   etapas são regeneráveis pelo template.
class DeletionImpact {
  const DeletionImpact({
    required this.propostaIds,
    required this.contratos,
    required this.userAircraftIds,
    required this.etapasTracking,
    required this.temClienteComAcesso,
  });

  /// Propostas que serão marcadas como excluídas (inclui as convertidas).
  final List<String> propostaIds;

  /// Quantas dessas propostas já viraram contrato.
  final int contratos;

  /// Aeronaves em esteira ligadas a essas propostas.
  final List<String> userAircraftIds;

  /// Linhas de `tracking` que serão APAGADAS em definitivo.
  final int etapasTracking;

  /// O lead já virou cliente com acesso ao app. Excluir não tira o login dele
  /// (os helpers de autorização não olham `is_deleted`), mas a esteira apagada
  /// some do app do cliente — que é dado que ele vê.
  final bool temClienteComAcesso;

  int get propostas => propostaIds.length;
  bool get temAlgoAlemDoPrincipal =>
      propostas > 0 || contratos > 0 || etapasTracking > 0;
}

/// Levanta o impacto de excluir um lead (tudo que pende dele).
Future<DeletionImpact> previewLeadDeletion(String leadId) async {
  final propostas = await ProposalTable().queryRows(
    queryFn: (q) => q.eqOrNull('lead_id', leadId).eqOrNull('is_deleted', false),
  );
  final cliente = await UsersTable().queryRows(
    queryFn: (q) => q.eqOrNull('lead_id', leadId).eqOrNull('is_deleted', false),
  );
  return _montarImpacto(
    propostas: propostas,
    temClienteComAcesso: cliente.isNotEmpty,
  );
}

/// Levanta o impacto de excluir UMA proposta (ou o contrato dela).
Future<DeletionImpact> previewProposalDeletion(String proposalId) async {
  final propostas = await ProposalTable().queryRows(
    queryFn: (q) => q.eqOrNull('id', proposalId),
  );
  return _montarImpacto(propostas: propostas, temClienteComAcesso: false);
}

Future<DeletionImpact> _montarImpacto({
  required List<ProposalRow> propostas,
  required bool temClienteComAcesso,
}) async {
  final ids = propostas.map((p) => p.id).toList();
  final contratos = propostas.where((p) => p.isContract == true).length;

  var aeronaveIds = <String>[];
  var etapas = 0;
  if (ids.isNotEmpty) {
    final aeronaves = await UserAircraftTable().queryRows(
      queryFn: (q) => q.inFilter('proposal_id', ids),
    );
    aeronaveIds = aeronaves.map((a) => a.id).toList();
    if (aeronaveIds.isNotEmpty) {
      final tracking = await TrackingTable().queryRows(
        queryFn: (q) => q.inFilter('user_aircraft', aeronaveIds),
      );
      etapas = tracking.length;
    }
  }

  return DeletionImpact(
    propostaIds: ids,
    contratos: contratos,
    userAircraftIds: aeronaveIds,
    etapasTracking: etapas,
    temClienteComAcesso: temClienteComAcesso,
  );
}

/// Executa a cascata. Lança em erro — quem chama deve usar `runAction`.
///
/// Ordem importa: as linhas filhas de `tracking` saem primeiro (FK), depois as
/// marcações sobem do específico para o geral.
Future<void> executeCascadeDelete(
  DeletionImpact impacto, {
  String? leadId,
}) async {
  // 1) Esteira: apagada de verdade (não tem soft-delete e a view não filtra).
  if (impacto.userAircraftIds.isNotEmpty) {
    final tracking = await TrackingTable().queryRows(
      queryFn: (q) => q.inFilter('user_aircraft', impacto.userAircraftIds),
    );
    final trackingIds = tracking.map((t) => t.id).toList();
    if (trackingIds.isNotEmpty) {
      await TrackingDetailsTable().delete(
        matchingRows: (q) => q.inFilter('tracking_id', trackingIds),
      );
      await TrackingTable().delete(
        matchingRows: (q) => q.inFilter('id', trackingIds),
      );
    }
    // 2) Aeronave: soft-delete (preserva o vínculo com o contrato).
    await UserAircraftTable().update(
      data: {'deleted': true},
      matchingRows: (q) => q.inFilter('id', impacto.userAircraftIds),
      returnRows: true,
    );
  }

  // 3) Propostas — leva os contratos junto (vw_contract_data filtra por aqui).
  if (impacto.propostaIds.isNotEmpty) {
    await ProposalTable().update(
      data: {'is_deleted': true},
      matchingRows: (q) => q.inFilter('id', impacto.propostaIds),
      returnRows: true,
    );
  }

  // 4) O lead por último.
  if (leadId != null) {
    await LeadsTable().update(
      data: {'is_deleted': true},
      matchingRows: (q) => q.eqOrNull('id', leadId),
      returnRows: true,
    );
  }
}

/// Linhas do "o que será excluído" para a modal de confirmação.
List<String> resumoDoImpacto(DeletionImpact i, {required String principal}) {
  return [
    principal,
    if (i.propostas > 0)
      '${i.propostas} ${i.propostas == 1 ? 'proposta' : 'propostas'}',
    if (i.contratos > 0)
      '${i.contratos} ${i.contratos == 1 ? 'contrato' : 'contratos'}',
    if (i.userAircraftIds.isNotEmpty)
      '${i.userAircraftIds.length} '
          '${i.userAircraftIds.length == 1 ? 'aeronave' : 'aeronaves'}',
  ];
}
