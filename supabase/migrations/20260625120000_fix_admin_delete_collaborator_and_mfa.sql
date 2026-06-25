-- ============================================================================
-- Fix 2026-06-25 — admin_delete_app_user: enum de colaborador + remoção de MFA.
-- ============================================================================
-- Dois problemas na versão anterior (migration 20260622120000):
--
--  1) A lista de perfis excluíveis usava 'Colaborador'::profile_types, mas o
--     enum profile_types NÃO tem esse valor. "Colaborador" é só um rótulo de
--     UI; no banco o colaborador é profile_type = 'Admin' (a tela
--     Colaboradores filtra por 'Admin' e o cadastro grava 'Admin'). O cast
--     constante 'Colaborador'::profile_types estourava 22P02
--     ("invalid input value for enum profile_types: Colaborador") em TODA
--     chamada da RPC — não só na exclusão de colaborador — deixando a função
--     de exclusão completamente quebrada. Troca por 'Admin'::profile_types.
--     Admin Master ('Admin Master') e 'Admin2' continuam fora da lista, logo
--     protegidos. Exclusão segue exclusiva de Admin Master.
--
--  2) Ao excluir, os fatores de MFA/authenticator (TOTP) enrolados em
--     auth.mfa_factors NÃO eram removidos. Agora são apagados (best-effort,
--     junto com a revogação de sessões/refresh tokens) para que nenhum
--     authenticator fique pendurado na conta banida.
--
-- Demais comportamentos preservados da 20260622120000: soft-delete + ban +
-- liberação do e-mail via tombstone em public.users / auth.users /
-- auth.identities, preservando contratos e FKs.
-- ============================================================================

create or replace function public.admin_delete_app_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_profile   public.profile_types;
  v_old_email text;
  v_tomb      text;
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
    'Oficina'::profile_types,
    'Vendedor'::profile_types,
    'Admin'::profile_types
  ) then
    raise exception 'admin_delete_app_user: perfil % não pode ser excluído por aqui', v_profile
      using errcode = '42501';
  end if;

  select email into v_old_email from auth.users where id = p_user_id;

  -- Tombstone único por usuário — libera o e-mail original para recadastro sem
  -- DELETE (que cascatearia em public.users / contratos).
  v_tomb := 'deleted+' || p_user_id::text || '@deleted.agsur.local';

  -- 1) Soft-delete no painel + libera o e-mail em public.users. A linha é
  --    PRESERVADA (integridade referencial com contrato/proposta/venda). A
  --    mudança é auditada pelo trigger de users.
  update public.users
     set is_deleted   = true,
         is_active    = false,
         device_token = null,
         email        = v_tomb
   where id = p_user_id;

  -- 2) Bane a conta e libera o e-mail no auth.users. Sem DELETE de propósito
  --    (ver cabeçalho da migration 20260617120000).
  update auth.users
     set banned_until = now() + interval '100 years',
         email        = v_tomb
   where id = p_user_id;

  -- 3) Libera o e-mail nas identities. O schema de auth.identities varia por
  --    versão do GoTrue, então cada passo é encapsulado para nunca derrubar a
  --    transação principal.
  begin
    update auth.identities
       set identity_data =
             jsonb_set(coalesce(identity_data, '{}'::jsonb), '{email}', to_jsonb(v_tomb))
     where user_id = p_user_id;
  exception when others then null;
  end;

  begin
    -- Coluna 'email' existe em versões mais novas do GoTrue.
    update auth.identities set email = v_tomb where user_id = p_user_id;
  exception when others then null;
  end;

  begin
    -- Versões antigas usam provider_id = e-mail para o provider 'email'.
    update auth.identities
       set provider_id = p_user_id::text
     where user_id = p_user_id
       and provider = 'email'
       and v_old_email is not null
       and provider_id = v_old_email;
  exception when others then null;
  end;

  -- 4) Revoga sessões/refresh tokens em vigor (best-effort).
  begin
    delete from auth.sessions where user_id = p_user_id;
  exception when others then null;
  end;

  begin
    delete from auth.refresh_tokens where user_id = p_user_id::text;
  exception when others then null;
  end;

  -- 5) Remove os fatores de MFA/authenticator (TOTP) enrolados. Sem isso o
  --    authenticator ficava pendurado na conta banida. Best-effort: a tabela
  --    auth.mfa_factors existe nas versões do GoTrue com MFA; encapsulado para
  --    não derrubar a transação em ambientes sem ela.
  begin
    delete from auth.mfa_factors where user_id = p_user_id;
  exception when others then null;
  end;
end;
$$;

revoke all on function public.admin_delete_app_user(uuid) from public;
grant execute on function public.admin_delete_app_user(uuid) to authenticated;

comment on function public.admin_delete_app_user(uuid) is
  'Exclui (soft) um usuário Cliente/Piloto/Oficina/Vendedor/Admin(colaborador), bane seu acesso no auth, remove fatores MFA e LIBERA o e-mail para recadastro (tombstone em public.users/auth.users/auth.identities), preservando contratos e demais dados. Apenas Admin Master.';
