import 'package:flutter_test/flutter_test.dart';
import 'package:a_g_sur_back_office/security/password_utils.dart';

void main() {
  group('generateAppUserPassword', () {
    test('tem exatamente 8 caracteres (pedido do cliente 2026-08-26)', () {
      for (var i = 0; i < 200; i++) {
        expect(generateAppUserPassword().length, kAppUserPasswordLength);
      }
    });

    test('ainda passa no strongPasswordValidator', () {
      // O encurtamento não pode fazer o próprio formulário recusar a senha
      // que ele acabou de gerar.
      for (var i = 0; i < 200; i++) {
        expect(strongPasswordValidator(generateAppUserPassword()), isNull);
      }
    });

    test('mantém uma de cada classe (minúscula, maiúscula, dígito, símbolo)',
        () {
      for (var i = 0; i < 200; i++) {
        final p = generateAppUserPassword();
        expect(p.contains(RegExp(r'[a-z]')), isTrue, reason: p);
        expect(p.contains(RegExp(r'[A-Z]')), isTrue, reason: p);
        expect(p.contains(RegExp(r'[0-9]')), isTrue, reason: p);
        expect(p.contains(RegExp(r'[!@#\$%&*?\-_]')), isTrue, reason: p);
      }
    });
  });

  test('staff do painel continua em 16 — não unificar com o app', () {
    expect(generateStrongPassword().length, 16);
  });
}
