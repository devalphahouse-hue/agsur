import 'dart:convert';

/// Decodifica o claim `aal` (Authenticator Assurance Level) de um JWT do
/// Supabase. Retorna 'aal1' (default) se o token estiver malformado.
///
/// O JWT é trusted aqui — chamado depois de signInWithPassword bem sucedido,
/// não precisa validar assinatura.
String decodeJwtAal(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return 'aal1';
    var payload = parts[1];
    payload += '=' * ((4 - payload.length % 4) % 4);
    final decoded = utf8.decode(base64Url.decode(payload));
    final claims = jsonDecode(decoded) as Map<String, dynamic>;
    return (claims['aal'] as String?) ?? 'aal1';
  } catch (_) {
    return 'aal1';
  }
}

/// Lê uma claim arbitrária. Retorna null se ausente ou JWT malformado.
T? decodeJwtClaim<T>(String token, String claim) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    var payload = parts[1];
    payload += '=' * ((4 - payload.length % 4) % 4);
    final decoded = utf8.decode(base64Url.decode(payload));
    final claims = jsonDecode(decoded) as Map<String, dynamic>;
    final v = claims[claim];
    return v is T ? v : null;
  } catch (_) {
    return null;
  }
}
