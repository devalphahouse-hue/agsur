/// Regras do estoque de aeronaves (migration `20260922120000_stock_movements`).
///
/// O banco é a fonte da verdade — os CHECKs de `stock_movements.reason` e as
/// RPCs `stock_entry`/`stock_exit`/`stock_reentry` recusam o que não estiver
/// aqui. Este arquivo só espelha os conjuntos para a UI e concentra a conta
/// do saldo por modelo, para ela não ficar espalhada nas telas.
/// **Mexeu num motivo lá, mexa aqui** (mesma regra do `MotivoCancelamento`).
///
/// Modelo mental:
/// - Avião é item serializado: cada unidade é uma linha em
///   `available_aircrafts`, com nº de série obrigatório e único.
/// - `in_stock` diz se ela está fisicamente no estoque. Só muda por
///   lançamento no livro-razão (`stock_movements`), nunca por UPDATE direto.
/// - "Em proposta" é CALCULADO: aeronave no estoque escolhida em proposta
///   ativa (`proposal.available_aircraft_id`, não excluída, não convertida).
///   Não mexe no status.
/// - `status` é o estado comercial para exibição. Em estoque: Disponível /
///   Em negociação / Reservado (manual). Fora: Vendido (trigger do contrato),
///   Entregue (manual) ou Baixado (saída manual).
/// - A **saída por venda acontece na conversão da proposta em contrato**
///   (trigger no banco). Cancelar o contrato devolve a unidade sozinho.
library;

/// Motivos de lançamento — espelham o CHECK de `stock_movements.reason`.
const Map<String, String> kStockReasonLabels = {
  'saldo_inicial': 'Saldo inicial',
  'compra': 'Compra',
  'importacao': 'Importação',
  'devolucao_cliente': 'Devolução do cliente',
  'cancelamento_contrato': 'Cancelamento de contrato',
  'desvinculo_contrato': 'Troca/desvínculo de contrato',
  'venda_contrato': 'Venda (contrato)',
  'baixa': 'Baixa',
  'devolucao_fabricante': 'Devolução ao fabricante',
  'ajuste_inventario': 'Ajuste de inventário',
};

/// Motivos aceitos pela RPC `stock_entry` (entrada de unidades novas).
const List<String> kStockEntryReasons = [
  'compra',
  'importacao',
  'devolucao_cliente',
  'ajuste_inventario',
];

/// Motivos aceitos pela RPC `stock_exit`. Venda não está aqui de propósito:
/// quem dá saída por venda é o contrato.
const List<String> kStockExitReasons = [
  'baixa',
  'devolucao_fabricante',
  'ajuste_inventario',
];

/// Motivos aceitos pela RPC `stock_reentry` (unidade que saiu e voltou).
const List<String> kStockReentryReasons = [
  'devolucao_cliente',
  'ajuste_inventario',
];

String stockReasonLabel(String reason) => kStockReasonLabels[reason] ?? reason;

/// Status que a pessoa pode escolher à mão, conforme a unidade esteja ou não
/// no estoque. `Vendido` fica de fora do primeiro grupo: quem marca é o
/// contrato. O valor atual sempre entra na lista (dado legado não some do
/// dropdown).
List<String> stockStatusOptions({required bool inStock, String? current}) {
  final base = inStock
      ? const ['Disponível', 'Em negociação', 'Reservado']
      : const ['Vendido', 'Entregue', 'Baixado'];
  if (current == null || current.isEmpty || base.contains(current)) {
    return List.of(base);
  }
  return [current, ...base];
}

/// Unidade "livre para vender": no estoque e sem contrato ativo. É o que o
/// seletor da proposta e do contrato oferecem.
bool isStockUnitSellable({
  required bool inStock,
  required bool hasActiveContract,
}) =>
    inStock && !hasActiveContract;

/// Visão mínima de uma unidade para a conta do saldo — desacoplada da row do
/// Supabase para poder ser testada.
class StockUnitSnapshot {
  const StockUnitSnapshot({
    required this.modelId,
    required this.modelName,
    required this.inStock,
    required this.status,
    this.featured = false,
    this.hasActiveContract = false,
    this.openProposals = 0,
  });

  final String modelId;
  final String modelName;
  final bool inStock;
  final String status;
  final bool featured;
  final bool hasActiveContract;

  /// Propostas ativas (não excluídas, ainda não convertidas) que escolheram
  /// esta aeronave. Várias podem disputar a mesma.
  final int openProposals;
}

/// Saldo de um modelo do catálogo.
class StockModelBalance {
  StockModelBalance({
    required this.modelId,
    required this.modelName,
    required this.featured,
  });

  final String modelId;
  final String modelName;
  final bool featured;

  /// Unidades fisicamente no estoque (a "quantidade"). É a soma de
  /// [available] + [inProposal] + [reserved].
  int inStock = 0;

  /// Em estoque, sem proposta e sem reserva manual — livres para oferecer.
  int available = 0;

  /// Em estoque e escolhidas em ao menos uma proposta ativa (automático).
  int inProposal = 0;

  /// Em estoque, sem proposta, mas marcadas à mão como Em negociação ou
  /// Reservado (ex.: reserva para um cliente que ainda nem tem proposta).
  int reserved = 0;

  /// Fora do estoque por venda (contrato ativo).
  int sold = 0;

  /// Fora do estoque por outro motivo (baixa, entregue sem contrato...).
  int otherOut = 0;

  int get total => inStock + sold + otherOut;
}

/// Agrupa as unidades por modelo. Ordena com os destaques primeiro e, dentro
/// de cada grupo, por nome.
List<StockModelBalance> summarizeStock(Iterable<StockUnitSnapshot> units) {
  final byModel = <String, StockModelBalance>{};
  for (final u in units) {
    final b = byModel.putIfAbsent(
      u.modelId,
      () => StockModelBalance(
        modelId: u.modelId,
        modelName: u.modelName,
        featured: u.featured,
      ),
    );
    if (u.inStock) {
      b.inStock++;
      final s = u.status.toLowerCase();
      if (u.openProposals > 0) {
        b.inProposal++;
      } else if (s.contains('negocia') || s.contains('reserv')) {
        b.reserved++;
      } else {
        b.available++;
      }
    } else if (u.hasActiveContract) {
      b.sold++;
    } else {
      b.otherOut++;
    }
  }
  final list = byModel.values.toList()
    ..sort((a, b) {
      if (a.featured != b.featured) return a.featured ? -1 : 1;
      return a.modelName.toLowerCase().compareTo(b.modelName.toLowerCase());
    });
  return list;
}

/// Quebra o texto colado/digitado na entrada em lote em números de série:
/// um por linha, vírgula ou ponto e vírgula; apara espaços e descarta vazios.
/// Duplicados no próprio lote (ignorando caixa, como o índice único do
/// banco) voltam em [ParsedSerials.duplicates] para a tela recusar antes de
/// chamar a RPC.
ParsedSerials parseSerials(String raw) {
  final serials = <String>[];
  final seen = <String>{};
  final duplicates = <String>{};
  for (final part in raw.split(RegExp(r'[\n,;]'))) {
    final s = part.trim();
    if (s.isEmpty) continue;
    final key = s.toLowerCase();
    if (!seen.add(key)) {
      duplicates.add(s);
      continue;
    }
    serials.add(s);
  }
  return ParsedSerials(serials, duplicates.toList());
}

class ParsedSerials {
  const ParsedSerials(this.serials, this.duplicates);
  final List<String> serials;
  final List<String> duplicates;
}
