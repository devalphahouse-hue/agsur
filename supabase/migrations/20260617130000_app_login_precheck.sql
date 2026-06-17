-- ============================================================================
-- Pré-check de login do app cliente (Cliente/Piloto/Oficina).
-- ============================================================================
-- A RPC `check_app_access` (não versionada, no Studio) devolve só o profile_type
-- e, na prática, filtra usuários inativos — ou seja, para um usuário DESATIVADO
-- ela retorna NULL, indistinguível de "email desconhecido". Com isso o app não
-- conseguia mostrar a mensagem de conta desativada: caía no signIn, criava
-- sessão e o redirect do router deslogava em silêncio.
--
-- Esta RPC devolve o estado completo da conta (perfil + ativo + excluído) ANTES
-- do signIn, para que o app possa barrar e EXPLICAR (sem criar sessão). Retorna
-- NULL quando o email não existe (o app então segue pro signIn e deixa o
-- Supabase devolver o erro genérico de credencial, sem enumerar contas).
--
-- Executável por anon (pré-login), SECURITY DEFINER. Mantém a mesma postura de
-- exposição já adotada pela check_app_access.
-- ============================================================================

create or replace function public.app_login_precheck(p_email text)
returns json
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_result json;
begin
  select json_build_object(
           'profile_type', profile_type,
           'is_active',  coalesce(is_active, true),
           'is_deleted', coalesce(is_deleted, false)
         )
    into v_result
    from public.users
   where lower(email) = lower(p_email)
   limit 1;

  return v_result; -- NULL se o email não existe
end;
$$;

revoke all on function public.app_login_precheck(text) from public;
grant execute on function public.app_login_precheck(text) to anon, authenticated;

comment on function public.app_login_precheck(text) is
  'Pré-login do app cliente: retorna {profile_type, is_active, is_deleted} do usuário pelo email, ou NULL se não existe. Permite ao app barrar e explicar conta desativada/excluída ANTES do signIn.';
