import 'package:flutter_test/flutter_test.dart';

import 'package:a_g_sur_back_office/backend/financing.dart';

void main() {
  group('percentual digitado', () {
    test('aceita as formas que a tela produz', () {
      expect(parsePercentToFraction('5'), closeTo(0.05, 1e-9));
      expect(parsePercentToFraction('5%'), closeTo(0.05, 1e-9));
      expect(parsePercentToFraction(' 10 % '), closeTo(0.10, 1e-9));
      expect(parsePercentToFraction('5,5'), closeTo(0.055, 1e-9));
    });

    test('vazio e lixo viram null, não zero', () {
      expect(parsePercentToFraction(''), isNull);
      expect(parsePercentToFraction('   '), isNull);
      expect(parsePercentToFraction('%'), isNull);
      expect(parsePercentToFraction('abc'), isNull);
      expect(parsePercentToFraction(null), isNull);
      // Zero digitado é valor, não ausência.
      expect(parsePercentToFraction('0'), 0.0);
    });
  });

  group('total do depósito', () {
    test('soma sinal e depósito inicial', () {
      expect(totalDepositFraction(sinal: '5%', depositoInicial: '10%'),
          closeTo(0.15, 1e-9));
      expect(totalDepositFraction(sinal: '5', depositoInicial: '10,2'),
          closeTo(0.152, 1e-9));
    });

    test('campo vazio conta como zero — era isso que gravava total 0', () {
      expect(totalDepositFraction(sinal: '5%', depositoInicial: ''),
          closeTo(0.05, 1e-9));
      expect(totalDepositFraction(sinal: '', depositoInicial: '10%'),
          closeTo(0.10, 1e-9));
    });

    test('os dois vazios devolvem null, para a tela bloquear', () {
      expect(totalDepositFraction(sinal: '', depositoInicial: ''), isNull);
      expect(totalDepositFraction(), isNull);
    });
  });

  group('prêmio por prazo', () {
    test('usa o cadastro de Taxas', () {
      expect(
          premiumRateForTerm(
              termYears: 5, premiumRateFive: 0.048, premiumRateSeven: 0.07),
          0.048);
      expect(
          premiumRateForTerm(
              termYears: 7, premiumRateFive: 0.048, premiumRateSeven: 0.072),
          0.072);
    });

    test('cadastro zerado ou ausente cai no valor histórico', () {
      expect(premiumRateForTerm(termYears: 5), 0.05);
      expect(premiumRateForTerm(termYears: 7), 0.07);
      expect(premiumRateForTerm(termYears: 5, premiumRateFive: 0), 0.05);
      expect(premiumRateForTerm(termYears: 7, premiumRateSeven: 0), 0.07);
    });

    test('prazo acima de 5 usa a faixa de 7 anos', () {
      expect(
          premiumRateForTerm(
              termYears: 10, premiumRateFive: 0.048, premiumRateSeven: 0.07),
          0.07);
    });
  });
}
