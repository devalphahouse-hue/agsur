import 'package:flutter_test/flutter_test.dart';
import 'package:a_g_sur_back_office/backend/phone.dart';

void main() {
  final fixtures = <String?, String?>{
    '(11) 98765-4321': '+5511987654321',
    '(11) 98765.4321': '+5511987654321',
    '11 98765 4321': '+5511987654321',
    '+55 (11) 98765-4321': '+5511987654321',
    '005511987654321': '+5511987654321',
    '02111987654321': '+5511987654321',
    '(11) 3456-7890': '+551134567890',
    '': null,
    null: null,
    'abc': null,
    '11111111111': null,
    '(01) 98765-4321': null,
    '5511887654321': null,
    '123': null,
  };
  for (final f in fixtures.entries) {
    test('telefone ${f.key}', () => expect(toE164Br(f.key), f.value));
  }
  test('fixo é válido mas pede confirmação de uso do WhatsApp', () {
    expect(isLikelyWhatsApp('(11) 3456-7890'), false);
    expect(isLikelyWhatsApp('(11) 98765-4321'), true);
  });
  test(
      'prévia contém o parâmetro normalizado e limita Unicode por pontos de código',
      () {
    expect(whatsappParameter('Nota\n com\t detalhes', subject: 'Atendimento'),
        'Atendimento — Nota com detalhes');
    final text = whatsappParameter('😀' * 1000);
    expect(text.runes.length, 860);
    expect(text.endsWith('…'), true);
    expect(whatsappPreview('Texto').contains('agendado: Texto.'), true);
    expect(whatsappPreview('x' * 2000).runes.length, lessThanOrEqualTo(1024));
  });
}
