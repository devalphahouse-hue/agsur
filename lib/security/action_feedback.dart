import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'write_guard.dart';

/// Feedback padrão de qualquer ação do usuário no painel.
///
/// **Por que existe.** Os handlers de botão/confirmação eram `() async {...}`
/// sem `try/catch`: uma exceção subia pelo callback assíncrono e ninguém a
/// pegava. O resultado era sempre o mesmo — o `Navigator.pop` nunca rodava, o
/// diálogo ficava aberto, o botão girando, e o usuário sem a menor ideia do que
/// aconteceu. Foi assim na criação de proposta (2026-07-20: 17 propostas
/// órfãs criadas antes do erro) e na exclusão de cliente (a RPC recusa quem não
/// é Admin Master e a tela simplesmente não respondia).
///
/// [runAction] garante três coisas em TODA ação:
/// 1. o diálogo fecha, com sucesso ou erro;
/// 2. o usuário vê uma mensagem em pt-BR nos dois casos;
/// 3. o erro técnico vai para o Sentry, não para a tela.
///
/// Complementa (não substitui) o [guardWrite]: aquele detecta o bloqueio
/// *silencioso* da RLS num UPDATE/DELETE, em que o Postgres devolve 2xx com 0
/// linhas e nada é lançado. Use `guardWrite` dentro do `action` quando a
/// operação for UPDATE/DELETE.
///
/// ```dart
/// confirmBtnAction: () async {
///   await runAction(
///     context,
///     dialogContext: dialogContext,
///     success: 'Cliente excluído',
///     action: () => SupaFlow.client.rpc('admin_delete_app_user', ...),
///   );
/// }
/// ```
Future<bool> runAction(
  BuildContext context, {
  required Future<void> Function() action,

  /// Mensagem verde ao dar certo. `null` = sucesso sem toast (use quando a
  /// própria tela já muda de forma óbvia, ex.: navegar para outra página).
  String? success,

  /// Diálogo a fechar antes de mostrar a mensagem. Fecha nos DOIS caminhos —
  /// é o que impede a tela travada.
  BuildContext? dialogContext,

  /// Fallback quando o erro não é reconhecido.
  String failure = 'Não foi possível concluir a ação. Tente novamente.',

  /// Rótulo do ponto de chamada no Sentry (ex.: 'clientes.excluir').
  String? contexto,

  /// Ação de segundo plano: erro vai só para o Sentry, sem alarmar quem não
  /// clicou em nada. Mesmo critério do `silent` do [guardWrite].
  bool silent = false,
}) async {
  try {
    await action();
    if (dialogContext != null && dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    if (success != null && !silent && context.mounted) {
      showActionSuccess(context, success);
    }
    return true;
  } catch (e, st) {
    if (dialogContext != null && dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    Sentry.captureException(
      e,
      stackTrace: st,
      withScope: (scope) => scope.setTag('acao', contexto ?? 'sem contexto'),
    );
    if (!silent && context.mounted) {
      showWriteError(context, mensagemDeErro(e, fallback: failure));
    }
    return false;
  }
}

/// Igual ao [runAction], mas devolve o resultado da ação (ou `null` em erro).
///
/// Use quando a ação **produz** algo que a tela precisa — o levantamento de
/// impacto antes de uma exclusão, por exemplo. Sem isso, uma consulta que
/// falhasse deixaria a tela sem reação nenhuma.
Future<T?> runActionWithResult<T>(
  BuildContext context, {
  required Future<T> Function() action,
  String? success,
  BuildContext? dialogContext,
  String failure = 'Não foi possível concluir a ação. Tente novamente.',
  String? contexto,
}) async {
  try {
    final resultado = await action();
    if (dialogContext != null && dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    if (success != null && context.mounted) {
      showActionSuccess(context, success);
    }
    return resultado;
  } catch (e, st) {
    if (dialogContext != null && dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    await Sentry.captureException(
      e,
      stackTrace: st,
      withScope: (scope) => scope.setTag('acao', contexto ?? 'sem contexto'),
    );
    if (context.mounted) {
      showWriteError(context, mensagemDeErro(e, fallback: failure));
    }
    return null;
  }
}

/// Mostra a confirmação de sucesso no padrão visual do painel.
void showActionSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Color(0xFF313131)),
      ),
      duration: const Duration(seconds: 3),
      backgroundColor: FlutterFlowTheme.of(context).primary,
    ),
  );
}

/// Traduz a exceção para uma frase que o usuário entenda.
///
/// Os códigos são os do Postgres/PostgREST que este painel realmente produz —
/// vale manter a lista curta e honesta: o que não estiver aqui cai no
/// [fallback] genérico em vez de vazar `PostgrestException(code: 23505, ...)`
/// na cara do usuário.
String mensagemDeErro(Object e, {required String fallback}) {
  // Upload de arquivo. A validação local já escreve em pt-BR para humanos
  // (extensão fora da whitelist, arquivo vazio/grande) — repassar é melhor que
  // esconder atrás do genérico, porque diz o que fazer para dar certo.
  if (e is StorageUploadException) return e.message;
  if (e is StorageException) {
    final m = e.message.toLowerCase();
    if (m.contains('mime') || m.contains('content type')) {
      return 'Este tipo de arquivo não é aceito neste campo.';
    }
    if (m.contains('maximum allowed size') || m.contains('too large')) {
      return 'Arquivo grande demais para o servidor.';
    }
    if (e.statusCode == '403' || m.contains('row-level security')) {
      return kWriteBlockedMessage;
    }
    return 'Não foi possível enviar o arquivo. Tente novamente.';
  }

  if (e is PostgrestException) {
    switch (e.code) {
      case '42501': // insufficient_privilege — RLS ou trigger de guarda
        return kWriteBlockedMessage;
      case '23505': // unique_violation
        return 'Já existe um registro com esses dados.';
      case '23503': // foreign_key_violation
        return 'Este registro está vinculado a outros e não pode ser alterado.';
      case '23502': // not_null_violation
        return 'Preencha todos os campos obrigatórios.';
      case '22P02': // invalid_text_representation
        return 'Há um campo com formato inválido nesta tela.';
      case 'PGRST116': // 0 linhas onde se esperava 1
        return 'Registro não encontrado. Atualize a página e tente de novo.';
    }
    // Mensagens que a RPC levanta com RAISE EXCEPTION e são escritas para
    // humanos — repassar é melhor que esconder atrás do genérico.
    if (e.message.contains('Admin Master')) {
      return 'Só o Admin Master pode fazer isso.';
    }
    return fallback;
  }

  final texto = e.toString();
  if (texto.contains('42501') || texto.contains('Admin Master')) {
    return 'Só o Admin Master pode fazer isso.';
  }
  if (texto.contains('SocketException') ||
      texto.contains('ClientException') ||
      texto.contains('Failed host lookup')) {
    return 'Sem conexão com o servidor. Verifique a internet e tente de novo.';
  }
  if (texto.contains('Null check operator')) {
    // Campo obrigatório não preenchido chegando até o insert.
    return 'Preencha todos os campos obrigatórios antes de continuar.';
  }
  return fallback;
}
