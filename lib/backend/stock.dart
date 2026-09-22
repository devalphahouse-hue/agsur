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

/// Dias entre a data de fabricação e a entrega estimada (regra do cliente,
/// 2026-09-22: "fabricação + 60 dias, por conta da configuração e da
/// documentação"). O banco aplica o mesmo número em `stock_entry`
/// (`stock_delivery_offset_days()`, migration 20260922160000) — mudou aqui,
/// mude lá.
const int kStockDeliveryOffsetDays = 60;

/// Entrega estimada a partir da fabricação. A tela preenche com isto e deixa
/// editar; o banco usa o mesmo cálculo quando a entrega não vem informada.
DateTime estimateStockDelivery(DateTime manufacture) =>
    DateTime(manufacture.year, manufacture.month,
        manufacture.day + kStockDeliveryOffsetDays);

/// Status que a proposta aceita (reunião de 2026-09-22: o vendedor escolhe
/// aeronave "Disponível" ou "Em negociação"). `Reservado` fica de fora: é a
/// reserva manual para outro cliente.
const List<String> kStockProposalStatuses = ['Disponível', 'Em negociação'];

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

/// Unidade que a proposta/contrato pode escolher: no estoque, sem contrato
/// ativo e com status que o cliente aceita ([kStockProposalStatuses]). Sem
/// [status] informado, só checa estoque e contrato (uso interno do estoque).
bool isStockUnitSellable({
  required bool inStock,
  required bool hasActiveContract,
  String? status,
}) {
  if (!inStock || hasActiveContract) return false;
  if (status == null) return true;
  final s = _foldStatus(status);
  return kStockProposalStatuses.any((v) => _foldStatus(v) == s);
}

/// Normaliza status para comparar: sem espaços, minúsculo e sem acento — há
/// linha antiga gravada como "em negociacao".
String _foldStatus(String v) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
  const to = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
  final out = StringBuffer();
  for (final ch in v.trim().toLowerCase().split('')) {
    final i = from.indexOf(ch);
    out.write(i >= 0 ? to[i].toLowerCase() : ch);
  }
  return out.toString();
}

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

/// Uma linha colada da planilha do estoque: nº de série + data de fabricação.
class SheetUnit {
  const SheetUnit(this.serialNumber, this.manufacture);
  final String serialNumber;
  final DateTime manufacture;
}

class ParsedSheet {
  const ParsedSheet(this.units, this.problems);
  final List<SheetUnit> units;

  /// Linhas que não deu para ler, já com o motivo — a tela mostra e não envia
  /// nada até estarem resolvidas.
  final List<String> problems;
}

/// Lê o que foi colado da planilha (uma aeronave por linha, nº de série e data
/// de fabricação separados por tabulação, ponto e vírgula ou vírgula).
/// Aceita data `dd/MM/aaaa`, `dd-MM-aaaa` e `aaaa-MM-dd`. A entrega não vem na
/// planilha: é calculada como fabricação + [kStockDeliveryOffsetDays].
ParsedSheet parseStockSheet(String raw) {
  final units = <SheetUnit>[];
  final problems = <String>[];
  final seen = <String>{};
  for (final rawLine in raw.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    final parts = line
        .split(RegExp(r'[\t;,]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length < 2) {
      problems.add('"$line": informe o nº de série e a data de fabricação.');
      continue;
    }
    final serial = parts.first;
    // Cabeçalho da planilha colado junto.
    if (serial.toLowerCase().startsWith('serial') ||
        serial.toLowerCase().startsWith('n')  && parts[1].toLowerCase().contains('fabric')) {
      continue;
    }
    final date = parseSheetDate(parts[1]);
    if (date == null) {
      problems.add('"$line": data de fabricação inválida ("${parts[1]}").');
      continue;
    }
    if (!seen.add(serial.toLowerCase())) {
      problems.add('"$serial": repetido na lista.');
      continue;
    }
    units.add(SheetUnit(serial, date));
  }
  if (units.isEmpty && problems.isEmpty) {
    problems.add('Cole ao menos uma linha: nº de série e data de fabricação.');
  }
  return ParsedSheet(units, problems);
}

/// Data em `dd/MM/aaaa`, `dd-MM-aaaa` ou `aaaa-MM-dd`. `null` se não der.
DateTime? parseSheetDate(String raw) {
  final v = raw.trim();
  final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(v);
  if (iso != null) {
    return _safeDate(int.parse(iso.group(1)!), int.parse(iso.group(2)!),
        int.parse(iso.group(3)!));
  }
  final br = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})$').firstMatch(v);
  if (br != null) {
    var year = int.parse(br.group(3)!);
    if (year < 100) year += 2000;
    return _safeDate(year, int.parse(br.group(2)!), int.parse(br.group(1)!));
  }
  return null;
}

DateTime? _safeDate(int y, int m, int d) {
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  final dt = DateTime(y, m, d);
  return (dt.year == y && dt.month == m && dt.day == d) ? dt : null;
}
