import '/backend/supabase/supabase.dart';

/// Autocura do 422 `user_already_exists` na criação de acesso de cliente.
///
/// Chama a RPC `admin_release_stuck_email` (migration 20260722201000), que
/// libera o e-mail SOMENTE se ele estiver preso em conta excluída
/// (soft-delete com e-mail não-tombstoneado) ou órfã (auth sem linha em
/// `public.users`). Conta ativa nunca é tocada.
///
/// Retornos da RPC: `livre` (nada preso), `ativo` (pertence a cadastro
/// ativo — o chamador deve explicar o conflito), `liberado` (tombstone
/// aplicado — o chamador pode repetir o signup UMA vez). `null` = a própria
/// RPC falhou (sem permissão/rede) — trate como não-liberado.
Future<String?> releaseStuckEmail(String email) async {
  try {
    final result = await SupaFlow.client
        .rpc('admin_release_stuck_email', params: {'p_email': email});
    return result as String?;
  } catch (_) {
    return null;
  }
}
