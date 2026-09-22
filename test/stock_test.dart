import 'package:flutter_test/flutter_test.dart';

import 'package:a_g_sur_back_office/backend/stock.dart';

void main() {
  group('saldo por modelo', () {
    test('conta em estoque, livre, em proposta, reservada, vendida e outras saídas', () {
      final saldo = summarizeStock(const [
        StockUnitSnapshot(modelId: 'a', modelName: 'AT-402B', inStock: true, status: 'Disponível'),
        StockUnitSnapshot(modelId: 'a', modelName: 'AT-402B', inStock: true, status: 'Disponível', openProposals: 2),
        StockUnitSnapshot(modelId: 'a', modelName: 'AT-402B', inStock: true, status: 'Reservado'),
        StockUnitSnapshot(modelId: 'a', modelName: 'AT-402B', inStock: false, status: 'Vendido', hasActiveContract: true),
        StockUnitSnapshot(modelId: 'a', modelName: 'AT-402B', inStock: false, status: 'Baixado'),
      ]);

      expect(saldo, hasLength(1));
      final b = saldo.single;
      expect(b.inStock, 3, reason: 'quantidade = unidades fisicamente no estoque');
      expect(b.available, 1);
      expect(b.inProposal, 1, reason: 'duas propostas na mesma aeronave contam uma aeronave');
      expect(b.reserved, 1);
      expect(b.available + b.inProposal + b.reserved, b.inStock);
      expect(b.sold, 1);
      expect(b.otherOut, 1);
      expect(b.total, 5);
    });

    test('proposta vence o status manual: reservada e em proposta conta como em proposta', () {
      final b = summarizeStock(const [
        StockUnitSnapshot(modelId: 'a', modelName: 'X', inStock: true, status: 'Reservado', openProposals: 1),
      ]).single;
      expect(b.inProposal, 1);
      expect(b.reserved, 0);
    });

    test('proposta de aeronave que já saiu não conta como em proposta', () {
      final b = summarizeStock(const [
        StockUnitSnapshot(modelId: 'a', modelName: 'X', inStock: false, status: 'Vendido', hasActiveContract: true, openProposals: 1),
      ]).single;
      expect(b.inProposal, 0);
      expect(b.sold, 1);
    });

    test('status "Vendido" em unidade ainda no estoque não conta como vendida', () {
      // Dado legado: status comercial manual não tira do estoque — só o
      // livro-razão tira.
      final b = summarizeStock(const [
        StockUnitSnapshot(modelId: 'a', modelName: 'X', inStock: true, status: 'Vendido'),
      ]).single;
      expect(b.inStock, 1);
      expect(b.sold, 0);
    });

    test('destaques primeiro, depois ordem alfabética', () {
      final saldo = summarizeStock(const [
        StockUnitSnapshot(modelId: 'c', modelName: 'Cessna', inStock: true, status: 'Disponível'),
        StockUnitSnapshot(modelId: 'z', modelName: 'Zlin', inStock: true, status: 'Disponível', featured: true),
        StockUnitSnapshot(modelId: 'a', modelName: 'Air Tractor', inStock: true, status: 'Disponível'),
      ]);
      expect(saldo.map((b) => b.modelName), ['Zlin', 'Air Tractor', 'Cessna']);
    });
  });

  group('números de série da entrada em lote', () {
    test('aceita linha, vírgula e ponto e vírgula; apara e descarta vazios', () {
      final p = parseSerials(' 402-1 \n402-2, 402-3;;\n\n 402-4 ');
      expect(p.serials, ['402-1', '402-2', '402-3', '402-4']);
      expect(p.duplicates, isEmpty);
    });

    test('repetido no lote é apontado ignorando caixa, como o índice do banco', () {
      final p = parseSerials('402b-1\n402B-1\n402-2');
      expect(p.serials, ['402b-1', '402-2']);
      expect(p.duplicates, ['402B-1']);
    });
  });

  group('status manual', () {
    test('em estoque não oferece Vendido — quem marca é o contrato', () {
      expect(stockStatusOptions(inStock: true),
          ['Disponível', 'Em negociação', 'Reservado']);
    });

    test('fora do estoque só oferece estados de saída', () {
      expect(stockStatusOptions(inStock: false), ['Vendido', 'Entregue', 'Baixado']);
    });

    test('valor legado continua na lista para o dropdown não abrir vazio', () {
      expect(stockStatusOptions(inStock: true, current: 'Vendido').first, 'Vendido');
    });
  });

  test('só unidade no estoque e sem contrato ativo é vendável', () {
    expect(isStockUnitSellable(inStock: true, hasActiveContract: false), isTrue);
    expect(isStockUnitSellable(inStock: true, hasActiveContract: true), isFalse);
    expect(isStockUnitSellable(inStock: false, hasActiveContract: false), isFalse);
  });

  test('todo motivo das RPCs tem rótulo', () {
    for (final r in [...kStockEntryReasons, ...kStockExitReasons, ...kStockReentryReasons]) {
      expect(kStockReasonLabels.containsKey(r), isTrue, reason: r);
    }
  });
}
