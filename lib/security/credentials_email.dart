import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Envio do e-mail de boas-vindas com as credenciais (e-mail + senha) de um
/// usuário recém-criado, via Edge Function `send-credentials-email` (Resend).
///
/// **Contrato: o envio NUNCA aborta o cadastro.** O usuário já foi criado no
/// auth e em `public.users` quando isto roda — falha de e-mail não pode
/// desfazer nem interromper o fluxo. Em caso de falha, devolvemos `false`,
/// reportamos ao Sentry e o chamador avisa o admin (via [showCredentialsEmailWarning])
/// para repassar a senha manualmente.
///
/// A senha trafega só no corpo da invocação (HTTPS + JWT) e no e-mail — nunca
/// é logada nem enviada ao Sentry.
Future<bool> sendCredentialsEmail({
  required String email,
  required String password,
  required String profileType,
  String? name,
}) async {
  try {
    final response = await SupaFlow.client.functions.invoke(
      'send-credentials-email',
      body: {
        'email': email.trim(),
        'password': password,
        'name': name ?? '',
        'profileType': profileType,
      },
    );
    if (response.status == 200) return true;
    Sentry.captureMessage(
      'E-mail de credenciais falhou (perfil $profileType, status ${response.status})',
      level: SentryLevel.warning,
    );
    return false;
  } catch (e) {
    Sentry.captureMessage(
      'E-mail de credenciais falhou (perfil $profileType): ${e.runtimeType}',
      level: SentryLevel.warning,
    );
    return false;
  }
}

/// Aviso padrão quando o cadastro deu certo mas o e-mail de credenciais não
/// saiu: o admin precisa saber que o usuário NÃO recebeu a senha.
void showCredentialsEmailWarning(BuildContext context) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Usuário criado, mas o e-mail com os dados de acesso não pôde ser '
        'enviado. Repasse o e-mail e a senha manualmente.',
        style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
      ),
      duration: const Duration(milliseconds: 6000),
      backgroundColor: FlutterFlowTheme.of(context).warning,
    ),
  );
}
