-- ============================================================================
-- Exclusão de usuário do app (Cliente / Piloto / Oficina) a partir do painel.
-- ============================================================================
-- Decisão de produto (2026-06-17): "excluir" pelo ícone de lixeira deve REMOVER
-- O ACESSO do usuário e tirá-lo das listas do painel, MAS PRESERVAR contrato,
-- proposta, venda, financeiro e demais registros de negócio que o referenciam.
--
-- Por que NÃO fazemos hard-delete da linha em public.users:
--   - contract.user_Id (e outras tabelas) apontam para public.users.id.
--   - O padrão Supabase é public.users.id REFERENCES auth.users(id) ON DELETE
--     CASCADE. Deletar a linha de auth.users cascataria para public.users e,
--     dependendo da FK de contract, ou apagaria o contrato junto, ou faria o
--     DELETE falhar por violação de FK. Os dois casos quebram o requisito de
--     "deixa o contrato e tudo mais".
--
-- Portanto a exclusão = soft-delete da linha em public.users (some das listas,
-- que filtram is_deleted=false; e bloqueia o gate de login do app via
-- is_active=false) + desativação da identidade no auth (ban), que impede a
-- emissão de novos tokens sem disparar cascata destrutiva. É seguro
-- independentemente da configuração de ON DELETE das FKs da base.
--
-- Só Admin Master executa, e só sobre perfis Cliente/Piloto/Oficina.
-- ============================================================================

create or replace function public.admin_delete_app_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_profile public.profile_types;
begin
  if not public.auth_is_admin_master() then
    raise exception 'admin_delete_app_user: apenas Admin Master'
      using errcode = '42501';
  end if;

  select profile_type into v_profile
    from public.users
   where id = p_user_id;

  if v_profile is null then
    raise exception 'admin_delete_app_user: usuário % não encontrado', p_user_id
      using errcode = 'P0002';
  end if;

  if v_profile not in (
    'Cliente'::profile_types,
    'Piloto'::profile_types,
    'Oficina'::profile_types
  ) then
    raise exception 'admin_delete_app_user: só Cliente/Piloto/Oficina podem ser excluídos por aqui'
      using errcode = '42501';
  end if;

  -- 1) Some das listas do painel (is_deleted=true) e bloqueia o gate de login
  --    do app (is_active=false). A linha é PRESERVADA para manter a integridade
  --    referencial com contrato/proposta/venda/etc. Também zera o device_token
  --    para parar de enviar push. A mudança é auditada pelo trigger de users.
  update public.users
     set is_deleted   = true,
         is_active    = false,
         device_token = null
   where id = p_user_id;

  -- 2) Desativa o acesso no nível do auth: bane a conta (GoTrue recusa login e
  --    refresh enquanto banned_until > now()). Evitamos DELETE em auth.users de
  --    propósito (ver cabeçalho). Revogar sessões/refresh tokens em vigor é
  --    best-effort — o schema de auth varia por versão do GoTrue, então
  --    encapsulamos para nunca derrubar a transação principal.
  update auth.users
     set banned_until = now() + interval '100 years'
   where id = p_user_id;

  begin
    delete from auth.sessions where user_id = p_user_id;
  exception when others then
    null;
  end;

  begin
    delete from auth.refresh_tokens where user_id = p_user_id::text;
  exception when others then
    null;
  end;
end;
$$;

revoke all on function public.admin_delete_app_user(uuid) from public;
grant execute on function public.admin_delete_app_user(uuid) to authenticated;

comment on function public.admin_delete_app_user(uuid) is
  'Exclui (soft) um usuário Cliente/Piloto/Oficina e desativa seu acesso no auth (ban + revogação de sessões), preservando contratos e demais dados de negócio que o referenciam. Apenas Admin Master.';
