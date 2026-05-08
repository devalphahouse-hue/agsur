import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:a_g_sur_back_office/security/jwt_utils.dart';

/// Helper: monta um JWT (HS256) só pra testar decode. Assinatura é dummy
/// porque os helpers não validam assinatura — confiam que o token veio do
/// Supabase.
String _mockJwt(Map<String, dynamic> payload) {
  String b64(String s) => base64Url.encode(utf8.encode(s)).replaceAll('=', '');
  final header = b64(jsonEncode({'alg': 'HS256', 'typ': 'JWT'}));
  final body = b64(jsonEncode(payload));
  return '$header.$body.dummy_signature';
}

void main() {
  group('decodeJwtAal', () {
    test('aal2 (MFA verificado)', () {
      final token = _mockJwt({'aal': 'aal2', 'sub': 'abc'});
      expect(decodeJwtAal(token), 'aal2');
    });

    test('aal1 (sem MFA)', () {
      final token = _mockJwt({'aal': 'aal1', 'sub': 'abc'});
      expect(decodeJwtAal(token), 'aal1');
    });

    test('sem claim aal → fallback aal1', () {
      final token = _mockJwt({'sub': 'abc'});
      expect(decodeJwtAal(token), 'aal1');
    });

    test('JWT malformado → aal1', () {
      expect(decodeJwtAal(''), 'aal1');
      expect(decodeJwtAal('not.a.jwt'), 'aal1');
      expect(decodeJwtAal('abc'), 'aal1');
    });

    test('JWT com base64 inválido → aal1', () {
      expect(decodeJwtAal('invalid.@@@@.sig'), 'aal1');
    });
  });

  group('decodeJwtClaim', () {
    test('lê claim string', () {
      final token = _mockJwt({'profile_type': 'Admin Master'});
      expect(decodeJwtClaim<String>(token, 'profile_type'), 'Admin Master');
    });

    test('claim ausente → null', () {
      final token = _mockJwt({'sub': 'abc'});
      expect(decodeJwtClaim<String>(token, 'profile_type'), isNull);
    });

    test('tipo não bate → null', () {
      final token = _mockJwt({'count': 5});
      expect(decodeJwtClaim<String>(token, 'count'), isNull);
      expect(decodeJwtClaim<int>(token, 'count'), 5);
    });

    test('JWT malformado → null', () {
      expect(decodeJwtClaim<String>('garbage', 'sub'), isNull);
    });
  });
}
