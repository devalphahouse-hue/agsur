import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:a_g_sur_back_office/pages/shared/modal_register_lead/modal_register_lead_model.dart';

/// Captura de lead em feira (pedido do cliente, vídeo de 14/08): o vendedor
/// precisa registrar o contato em segundos, então só nome, sobrenome, e-mail e
/// telefone barram o cadastro. CPF, empresa, cargo e endereço são completados
/// depois em `view_edit_lead` — mas quem for preenchido continua validado.
Future<ModalRegisterLeadModel> _modelPronto(WidgetTester tester) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox.shrink();
      }),
    ),
  );
  return ModalRegisterLeadModel()..initState(ctx);
}

void main() {
  testWidgets('campos de feira continuam obrigatórios', (tester) async {
    final m = await _modelPronto(tester);
    final ctx = tester.element(find.byType(SizedBox));

    for (final v in <String? Function(BuildContext, String?)?>[
      m.tFNameTextControllerValidator,
      m.tFLastNameTextControllerValidator,
      m.tFEmailTextControllerValidator,
      m.tFPhoneTextControllerValidator,
    ]) {
      expect(v?.call(ctx, ''), isNotNull,
          reason: 'campo essencial da feira não pode aceitar vazio');
    }

    expect(m.tFEmailTextControllerValidator?.call(ctx, 'sem-arroba'),
        'E-mail inválido');
    expect(m.tFPhoneTextControllerValidator?.call(ctx, '(11) 9'),
        'Telefone inválido');
  });

  testWidgets('CPF, empresa, cargo e endereço aceitam vazio', (tester) async {
    final m = await _modelPronto(tester);
    final ctx = tester.element(find.byType(SizedBox));

    expect(m.tFCpfTextControllerValidator?.call(ctx, ''), isNull);
    expect(m.tFEmpresaTextControllerValidator?.call(ctx, ''), isNull);
    expect(m.tFCargoTextControllerValidator?.call(ctx, ''), isNull);
    expect(m.tFCepTextControllerValidator?.call(ctx, ''), isNull);
    expect(m.tFCityTextControllerValidator?.call(ctx, ''), isNull);
    expect(m.tFZipCodeTextControllerValidator?.call(ctx, ''), isNull);
  });

  testWidgets('formato ainda é cobrado de quem for preenchido',
      (tester) async {
    final m = await _modelPronto(tester);
    final ctx = tester.element(find.byType(SizedBox));

    expect(m.tFCpfTextControllerValidator?.call(ctx, '123.456'), 'CPF inválido');
    expect(m.tFCpfTextControllerValidator?.call(ctx, '111.111.111-11'), isNull);

    expect(m.tFCepTextControllerValidator?.call(ctx, '123'), 'CEP inválido');
    expect(m.tFCepTextControllerValidator?.call(ctx, '12345-678'), isNull);

    expect(m.tFZipCodeTextControllerValidator?.call(ctx, 'S'), 'UF');
    expect(m.tFZipCodeTextControllerValidator?.call(ctx, 'SP'), isNull);
  });
}
