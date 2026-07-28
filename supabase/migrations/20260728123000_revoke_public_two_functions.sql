-- ============================================================================
-- Complemento de 20260728120000 (F3) — as duas funções que o revoke não pegou.
-- ============================================================================
-- A verificação pós-aplicação de 20260728120000 mostrou que `anon` CONTINUAVA
-- executando duas das sete:
--
--   auth_is_linked_to_aircraft_model(uuid)   has_function_privilege → true
--   get_proposal_details(uuid)               has_function_privilege → true
--
-- Motivo (ACL das duas):
--   =X/postgres | postgres=X/postgres | authenticated=X/postgres | service_role=X/postgres
--    ^^^^^^^^^^ grantee vazio = PUBLIC
--
-- Estas duas nunca receberam o grant DIRETO para `anon` — elas ficaram só com
-- o grant a PUBLIC (são justamente as que a auditoria apontou como "sem revoke
-- nenhum"). Logo, `REVOKE ... FROM anon` não tinha o que revogar: anon executa
-- por HERANÇA de PUBLIC.
--
-- É o espelho exato da armadilha registrada em 20260722202000. Vale a pena
-- guardar as duas metades juntas, porque uma não substitui a outra:
--
--   • REVOKE FROM public → NÃO remove um grant direto a anon.
--   • REVOKE FROM anon   → NÃO remove o grant herdado de PUBLIC.
--
-- Para fechar de verdade é preciso revogar de PUBLIC **e** de anon, e só então
-- conceder explicitamente a quem deve executar.
--
-- `authenticated` e `service_role` já têm grant próprio nas duas (visível no
-- ACL acima), então revogar de PUBLIC não tira acesso de nenhum fluxo real:
-- get_proposal_details é chamada pelo painel logado (api_calls.dart) e
-- auth_is_linked_to_aircraft_model é helper de RLS usado dentro das views.
-- ============================================================================

REVOKE ALL ON FUNCTION public.auth_is_linked_to_aircraft_model(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_proposal_details(uuid)             FROM PUBLIC;

-- Reafirma o grant de quem deve executar (idempotente; já existia).
GRANT EXECUTE ON FUNCTION public.auth_is_linked_to_aircraft_model(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_proposal_details(uuid)             TO authenticated, service_role;

-- Conferência (deve devolver false nas duas):
--   select p.proname, has_function_privilege('anon', p.oid, 'EXECUTE')
--     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
--    where n.nspname = 'public'
--      and p.proname in ('auth_is_linked_to_aircraft_model','get_proposal_details');
--
-- Rollback: GRANT EXECUTE ON FUNCTION <nome> TO PUBLIC;
