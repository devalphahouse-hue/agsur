import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';

/// Classifica um lead como "ainda lead" ou "já virou cliente".
///
/// **Por que isso não é uma coluna em `leads`:** a linha de `leads` NÃO pode ser
/// apagada nem marcada como excluída quando o lead vira cliente. Ela é a chave
/// de autorização do app cliente — `auth_owns_proposal` e
/// `auth_owns_user_aircraft` (ambas SECURITY DEFINER) fazem
/// `JOIN leads l ON l.id = p.lead_id WHERE lower(l.email) = lower(auth_user_email())`.
/// Sumir com o lead = o cliente perde acesso à própria aeronave no app.
///
/// A conversão é derivada de `users.lead_id`: existe um usuário não-excluído
/// apontando para este lead? Então ele é cliente. Nada é gravado no lead.
///
/// Isso também é o que permite a **recompra**: uma segunda proposta para o mesmo
/// cliente é apenas uma proposta nova com o MESMO `lead_id`, e a conversão
/// reaproveita o `users` existente em vez de criar acesso duplicado.
class LeadConversion {
  LeadConversion._();

  static const _cacheKey = 'leads.convertedIds';

  /// Ids de leads que já possuem cliente vinculado.
  static Future<Set<String>> convertedLeadIds({
    Duration ttl = const Duration(minutes: 2),
  }) async {
    final rows = await QueryCache.fetch<List<UsersRow>>(
      key: _cacheKey,
      ttl: ttl,
      fetcher: () => UsersTable().queryRows(
        queryFn: (q) => q.eqOrNull('is_deleted', false),
      ),
    );
    return rows
        .map((u) => u.leadId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  /// Invalidar depois de converter proposta em contrato (ou excluir cliente),
  /// senão a listagem de Leads segue mostrando quem acabou de virar cliente.
  static void invalidate() => QueryCache.invalidate(_cacheKey);
}
