import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// DSN do Sentry vem via --dart-define=SENTRY_DSN=... ou variável de ambiente.
/// Sem DSN, `runWithSentry` faz `runApp` direto (no-op).
const String _kSentryDsn =
    String.fromEnvironment('SENTRY_DSN', defaultValue: '');
const String _kEnvName =
    String.fromEnvironment('APP_ENV', defaultValue: 'development');
const String _kRelease =
    String.fromEnvironment('APP_RELEASE', defaultValue: 'agsur-painel@dev');

bool get isSentryEnabled => _kSentryDsn.isNotEmpty;

/// Wraps a builder so all errors (Flutter, async zone, isolate) são reportadas
/// pro Sentry. Em dev sem DSN, apenas chama `runApp(builder())`.
Future<void> runWithSentry(Widget Function() builder) async {
  if (!isSentryEnabled) {
    runApp(builder());
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = _kSentryDsn;
      options.environment = _kEnvName;
      options.release = _kRelease;
      // Em produção, 10% de traces; dev/staging, 100%.
      options.tracesSampleRate = _kEnvName == 'production' ? 0.1 : 1.0;
      options.attachScreenshot = false; // privacidade
      options.sendDefaultPii = false; // não envia IP/user-agent automático
      options.debug = kDebugMode && _kEnvName != 'production';

      // Filtro: nunca enviar PII em headers (Authorization, apikey, Cookie)
      options.beforeSend = (event, hint) {
        if (event.request != null) {
          final cleanedHeaders = Map<String, String>.from(event.request!.headers)
            ..remove('Authorization')
            ..remove('apikey')
            ..remove('Cookie');
          return event.copyWith(
            request: event.request!.copyWith(headers: cleanedHeaders),
          );
        }
        return event;
      };
    },
    appRunner: () => runApp(builder()),
  );
}

/// Anexa o id do usuário atual a futuros eventos. Chamar após login.
/// Não envia email/nome — só o uuid, suficiente pra correlacionar com banco.
Future<void> setSentryUser(String? userId) async {
  if (!isSentryEnabled) return;
  await Sentry.configureScope((scope) async {
    if (userId == null) {
      await scope.setUser(null);
    } else {
      await scope.setUser(SentryUser(id: userId));
    }
  });
}
