-- ============================================================================
-- QA/Segurança 2026-06-22 — fecha exposição de dados SEM LOGIN + search_path.
-- ============================================================================
-- Achado (auditoria 2026-06-22): o role `anon` (chave pública embarcada no bundle
-- web) tinha privilégios em TODAS as views `public.*`, e essas views são
-- SECURITY DEFINER (security_invoker off) → ignoram RLS. Resultado: PII/financeiro
-- (clientes, contratos, propostas, pilotos, dashboard) era legível SEM
-- autenticação via PostgREST. Esta migration REVOGA todo acesso de `anon` às
-- views — nada legítimo usa `anon` para lê-las (painel e app exigem login).
--
-- Também corrige `is_adm(uuid)`: era SECURITY DEFINER SEM `search_path` fixo
-- (risco de escalonamento por search_path injection).
--
-- NÃO mexe em `authenticated` nem liga `security_invoker` (isso fecha o IDOR
-- autenticado, mas exige validação por perfil — Vendedor/app cliente — para não
-- quebrar leituras legítimas; tratado em etapa separada).
-- ============================================================================

-- 1) Revoga TODO privilégio de `anon` em todas as views do schema public.
do $$
declare r record;
begin
  for r in
    select c.relname
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public' and c.relkind = 'v'
  loop
    execute format('revoke all on public.%I from anon', r.relname);
  end loop;
end $$;

-- 2) Fixa search_path da função SECURITY DEFINER legada.
alter function public.is_adm(uuid) set search_path = public;
