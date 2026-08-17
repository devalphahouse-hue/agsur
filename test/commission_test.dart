import 'package:flutter_test/flutter_test.dart';

import 'package:a_g_sur_back_office/backend/commission.dart';

void main() {
  group('régua de comissão de 17/08/2026', () {
    test('venda direta: 2% para a AGSur, US\$ 7.500 fixos para o vendedor', () {
      // Contrato real usado para validar a régua com o dono.
      final c = calcularComissao(fullprice: 1494305.00, isIndicacao: false);

      expect(c.company, closeTo(29886.10, 0.001));
      expect(c.seller, 7500.0);
    });

    test('indicação derruba só o vendedor, de 7.500 para 4.500', () {
      final direta = calcularComissao(fullprice: 1494305.00, isIndicacao: false);
      final indicada =
          calcularComissao(fullprice: 1494305.00, isIndicacao: true);

      expect(indicada.seller, 4500.0);
      expect(indicada.company, direta.company,
          reason: 'a indicação não muda a comissão da AGSur');
      expect(direta.seller - indicada.seller, kSellerReferralGiveback);
      expect(kSellerReferralGiveback, 3000.0);
    });

    test('comissão do vendedor não escala com o tamanho da venda', () {
      final pequena = calcularComissao(fullprice: 50000, isIndicacao: false);
      final grande = calcularComissao(fullprice: 9000000, isIndicacao: false);

      expect(pequena.seller, grande.seller);
      expect(grande.company, closeTo(180000.0, 0.001));
    });

    test('preço zerado/negativo não gera comissão negativa para a empresa', () {
      for (final preco in <double>[0, -1, -1494305.00, double.nan]) {
        final c = calcularComissao(fullprice: preco, isIndicacao: false);
        expect(c.company, 0.0, reason: 'fullprice $preco');
        expect(c.seller, kSellerCommissionFlat,
            reason: 'a do vendedor é fixa mesmo assim');
      }
    });

    test('a régua antiga (25%/5%) não é mais aplicada', () {
      final c = calcularComissao(fullprice: 1494305.00, isIndicacao: false);

      expect(c.company, isNot(closeTo(373576.25, 0.01)));
      expect(c.seller, isNot(closeTo(74715.25, 0.01)));
    });
  });
}
