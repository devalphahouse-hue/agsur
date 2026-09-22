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

  group('aeronave que a proposta pode escolher', () {
    test('no estoque e sem contrato ativo', () {
      expect(isStockUnitSellable(inStock: true, hasActiveContract: false), isTrue);
      expect(isStockUnitSellable(inStock: true, hasActiveContract: true), isFalse);
      expect(isStockUnitSellable(inStock: false, hasActiveContract: false), isFalse);
    });

    test('com status: só Disponível e Em negociação (reunião de 22/09/2026)', () {
      for (final ok in ['Disponível', 'Em negociação', 'em negociacao ']) {
        expect(
            isStockUnitSellable(
                inStock: true, hasActiveContract: false, status: ok),
            isTrue,
            reason: ok);
      }
      for (final no in ['Reservado', 'Vendido', 'Baixado', '']) {
        expect(
            isStockUnitSellable(
                inStock: true, hasActiveContract: false, status: no),
            isFalse,
            reason: no);
      }
    });
  });

  group('entrega estimada', () {
    test('fabricação + 60 dias', () {
      expect(estimateStockDelivery(DateTime(2026, 3, 10)), DateTime(2026, 5, 9));
      expect(kStockDeliveryOffsetDays, 60);
    });

    test('vira o ano e o mês sem erro', () {
      expect(estimateStockDelivery(DateTime(2026, 11, 20)), DateTime(2027, 1, 19));
    });
  });

  group('planilha do estoque', () {
    test('lê serial e data de fabricação em vários formatos e separadores', () {
      final p = parseStockSheet('402B-1560\t10/03/2026\n'
          '402B-1561;2026-04-01\n'
          '402B-1562, 15-05-26\n');
      expect(p.problems, isEmpty);
      expect(p.units.map((u) => u.serialNumber),
          ['402B-1560', '402B-1561', '402B-1562']);
      expect(p.units[0].manufacture, DateTime(2026, 3, 10));
      expect(p.units[1].manufacture, DateTime(2026, 4, 1));
      expect(p.units[2].manufacture, DateTime(2026, 5, 15));
    });

    test('aponta linha sem data, data inválida e serial repetido', () {
      final p = parseStockSheet('402B-1560\n'
          '402B-1561;31/02/2026\n'
          '402B-1562;01/01/2026\n'
          '402b-1562;02/01/2026');
      expect(p.units.map((u) => u.serialNumber), ['402B-1562']);
      expect(p.problems, hasLength(3));
      expect(p.problems[0], contains('nº de série e a data'));
      expect(p.problems[1], contains('inválida'));
      expect(p.problems[2], contains('repetido'));
    });

    test('ignora o cabeçalho da planilha e linhas vazias', () {
      final p = parseStockSheet('Serial;Data de fabricação\n\n402B-1;01/01/2026\n');
      expect(p.problems, isEmpty);
      expect(p.units, hasLength(1));
    });

    test('nada colado vira um aviso, não uma lista vazia silenciosa', () {
      expect(parseStockSheet('   ').problems, hasLength(1));
    });
  });

  test('todo motivo das RPCs tem rótulo', () {
    for (final r in [...kStockEntryReasons, ...kStockExitReasons, ...kStockReentryReasons]) {
      expect(kStockReasonLabels.containsKey(r), isTrue, reason: r);
    }
  });
}
