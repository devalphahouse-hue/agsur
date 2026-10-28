import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:a_g_sur_back_office/backend/commercial.dart';
import 'package:a_g_sur_back_office/pages/commercial/commissions_widget.dart';
import 'package:a_g_sur_back_office/security/access_control.dart';

void main() {
  test('decimal amounts preserve cents without accepting grouping or exponents',
      () {
    expect(commercialDecimal('7500,05'), '7500.05');
    expect(commercialDecimal('0.01'), '0.01');
    for (final invalid in [
      '1.000,00',
      '-1',
      'NaN',
      'Infinity',
      '1e3',
      '1.001',
      '1,2,3',
      ''
    ]) {
      expect(commercialDecimal(invalid), isNull, reason: invalid);
    }
  });
  test('commission and signature navigation respects the permission matrix',
      () {
    expect(AccessControl.canView(PanelRole.adminMaster, 'Commissions'), isTrue);
    expect(AccessControl.canView(PanelRole.vendedor, 'Commissions'), isTrue);
    expect(AccessControl.canView(PanelRole.adminDocumentacao, 'Commissions'),
        isFalse);
    expect(
        AccessControl.canView(PanelRole.adminRecepcao, 'Commissions'), isFalse);
    expect(AccessControl.canView(PanelRole.adminDocumentacao, 'Signatures'),
        isTrue);
    expect(AccessControl.canView(PanelRole.vendedor, 'Signatures'), isTrue);
    expect(AccessControl.canView(PanelRole.none, 'Signatures'), isFalse);
  });
  testWidgets('commercial form validates decimal input and releases the dialog',
      (tester) async {
    Map<String, String>? result;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () async {
                      result = await commercialForm(context,
                          title: 'Ratear',
                          fields: const [
                            CommercialInput('gross', 'Valor bruto',
                                decimal: true)
                          ]);
                    },
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '1.000,00');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('Use um valor positivo, sem milhar, com até 2 casas'),
        findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '7500,05');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(result, {'gross': '7500,05'});
    expect(tester.takeException(), isNull);
  });
}
