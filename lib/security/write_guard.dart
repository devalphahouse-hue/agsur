import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Guarda de escrita — torna visível o bloqueio de RLS.
///
/// **Por que existe.** Num UPDATE/DELETE a RLS do Postgres não levanta erro:
/// ela filtra as linhas *antes* de qualquer trigger BEFORE disparar, então a
/// operação "sucede" afetando 0 linhas e o PostgREST devolve 2xx. O painel,
/// que não checava o retorno, mostrava "salvo com sucesso" e o dado não mudava.
/// Foi assim que o bug do `company` (2026-07-14) passou despercebido: um Admin
/// documentação editava os Dados Empresariais, via a mensagem de sucesso, e
/// nada persistia.
///
/// **Armadilha do `returnRows`.** `SupabaseTable.update`/`delete` têm
/// `returnRows = false` por padrão e nesse modo fazem `await update; return [];`
/// — ou seja, devolvem lista vazia SEMPRE. Checar `isEmpty` sem passar
/// `returnRows: true` acusaria bloqueio em toda escrita. Por isso o callback
/// passado aqui **precisa** usar `returnRows: true`.
///
/// **INSERT é diferente:** `SupabaseTable.insert` usa `.single()`, que lança
/// `PostgrestException` quando a RLS bloqueia (0 linhas). Use [guardInsert].
///
/// Uso típico:
/// ```dart
/// final ok = await guardWrite(context, () => CompanyTable().update(
///       data: {...},
///       matchingRows: (rows) => rows.eqOrNull('id', companyId),
///       returnRows: true, // obrigatório
///     ));
/// if (!ok) return; // não mostre sucesso nem feche a modal
/// ```
const String kWriteBlockedMessage =
    'Você não tem permissão para salvar esta alteração. '
    'Fale com um Admin Master se precisar deste acesso.';

/// Mostra um erro de escrita no padrão visual do painel.
void showWriteError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
      ),
      duration: const Duration(milliseconds: 5000),
      backgroundColor: FlutterFlowTheme.of(context).error,
    ),
  );
}

/// Executa um UPDATE/DELETE e devolve `true` só se ele de fato persistiu.
///
/// O callback DEVE passar `returnRows: true` — ver a nota acima.
///
/// **`silent`** — use `true` em escritas de *segundo plano* (ex.: o sync de
/// `fullprice` que roda no carregamento de `view_contract`/`view_edit_proposal`,
/// fora de qualquer botão). Sem isso, um perfil sem permissão de UPDATE abriria
/// a tela e levaria um alerta vermelho sem ter clicado em nada — trocaríamos um
/// bug silencioso por um alarme falso. Em modo silencioso o bloqueio vai para o
/// Sentry, onde é problema de quem mantém, não do usuário. Escrita disparada por
/// clique deve continuar `silent: false`.
Future<bool> guardWrite(
  BuildContext context,
  Future<List<dynamic>> Function() op, {
  String blockedMessage = kWriteBlockedMessage,
  bool silent = false,
  String? contexto,
}) async {
  try {
    final rows = await op();
    if (rows.isEmpty) {
      _report(context, blockedMessage, silent, contexto);
      return false;
    }
    return true;
  } on PostgrestException catch (e) {
    _report(
      context,
      e.code == '42501' ? blockedMessage : 'Erro ao salvar: ${e.message}',
      silent,
      contexto,
    );
    return false;
  }
}

void _report(
  BuildContext context,
  String message,
  bool silent,
  String? contexto,
) {
  if (silent) {
    Sentry.captureMessage(
      'Escrita bloqueada (${contexto ?? 'sem contexto'}): $message',
      level: SentryLevel.warning,
    );
    return;
  }
  if (context.mounted) showWriteError(context, message);
}

/// Checa o resultado de um UPDATE/DELETE **já executado** com `returnRows: true`,
/// mostrando o erro se ele não afetou nenhuma linha.
///
/// Prefira [guardWrite], que também captura `PostgrestException`. Use este aqui
/// quando envolver a chamada num lambda exigiria reindentar um bloco `data: {}`
/// grande — o diff maior não compensa. O contrato é o mesmo: sem
/// `returnRows: true` na chamada, isto acusaria bloqueio em toda escrita.
///
/// ```dart
/// final rows = await ProposalFinancingTable().update(
///   data: {...},
///   matchingRows: (r) => r.eqOrNull('id', id),
///   returnRows: true, // obrigatório
/// );
/// if (!checkWrite(context, rows)) return;
/// ```
bool checkWrite(
  BuildContext context,
  List<dynamic> rows, {
  String blockedMessage = kWriteBlockedMessage,
}) {
  if (rows.isEmpty) {
    if (context.mounted) showWriteError(context, blockedMessage);
    return false;
  }
  return true;
}

/// Executa um INSERT (que lança em vez de devolver vazio) e devolve a linha
/// criada, ou `null` se a RLS/trigger bloqueou.
Future<T?> guardInsert<T>(
  BuildContext context,
  Future<T> Function() op, {
  String blockedMessage = kWriteBlockedMessage,
}) async {
  try {
    return await op();
  } on PostgrestException catch (e) {
    if (context.mounted) {
      showWriteError(
        context,
        e.code == '42501' ? blockedMessage : 'Erro ao salvar: ${e.message}',
      );
    }
    return null;
  }
}
