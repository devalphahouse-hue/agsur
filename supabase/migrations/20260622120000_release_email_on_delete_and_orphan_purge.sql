-- ============================================================================
-- QA 2026-06-22 — Liberação de e-mail na exclusão + rollback de conta órfã.
-- ============================================================================
-- Dois problemas reportados pelo QA:
--
--  BUG-008/009: ao excluir um usuário (piloto/oficina/vendedor/colaborador) o
--    e-mail continuava preso no auth (ban de 100 anos), impedindo recadastro do
--    mesmo e-mail. Além disso, Vendedor e Colaborador eram excluídos por UPDATE
--    direto no painel — sem ban no auth (continuavam conseguindo logar) e sem
--    liberar o e-mail.
--
--  BUG-005: na criação de cliente, se a conta de auth era criada mas o INSERT
--    em public.users falhava, sobrava uma conta de auth órfã ("fake access").
--
-- Esta migration:
--   1) admin_delete_app_user: mantém o soft-delete + ban (preserva contratos e
--      FKs, ver migration 20260617120000), mas agora também LIBERA o e-mail —
--      renomeia para um tombstone único em public.users, auth.users e
--      (best-effort) auth.identities. O e-mail original volta a poder ser
--      recadastrado; a conta antiga segue banida e fora das listas. Passa a
--      aceitar também Vendedor e Colaborador (Admin/Admin Master continuam
--      fora). Continua exclusivo de Admin Master.
--   2) admin_purge_orphan_auth_user: remove uma conta de auth ÓRFÃ (que não tem
--      linha correspondente em public.users) pelo e-mail. Usada como rollback
--      pelo painel quando o signup cria a conta mas o registro local falha.
--      A guarda "sem public.users" garante que NUNCA apaga um usuário válido.
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
    'Colaborador'::profile_types
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
end;
$$;

revoke all on function public.admin_delete_app_user(uuid) from public;
grant execute on function public.admin_delete_app_user(uuid) to authenticated;

comment on function public.admin_delete_app_user(uuid) is
  'Exclui (soft) um usuário Cliente/Piloto/Oficina/Vendedor/Colaborador, bane seu acesso no auth e LIBERA o e-mail para recadastro (tombstone em public.users/auth.users/auth.identities), preservando contratos e demais dados. Apenas Admin Master.';

-- ----------------------------------------------------------------------------

create or replace function public.admin_purge_orphan_auth_user(p_email text)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid;
begin
  if not public.auth_is_seller_or_admin() then
    raise exception 'admin_purge_orphan_auth_user: sem permissão'
      using errcode = '42501';
  end if;

  if p_email is null or length(trim(p_email)) = 0 then
    return;
  end if;

  -- Só considera ÓRFÃOS: conta em auth.users SEM linha em public.users. Um
  -- usuário válido sempre tem public.users — então jamais é apagado por aqui.
  select au.id into v_uid
    from auth.users au
   where lower(au.email) = lower(trim(p_email))
     and not exists (select 1 from public.users pu where pu.id = au.id)
   order by au.created_at desc
   limit 1;

  if v_uid is null then
    return;
  end if;

  begin
    delete from auth.identities where user_id = v_uid;
  exception when others then null;
  end;
  begin
    delete from auth.sessions where user_id = v_uid;
  exception when others then null;
  end;
  begin
    delete from auth.refresh_tokens where user_id = v_uid::text;
  exception when others then null;
  end;

  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.admin_purge_orphan_auth_user(text) from public;
grant execute on function public.admin_purge_orphan_auth_user(text) to authenticated;

comment on function public.admin_purge_orphan_auth_user(text) is
  'Remove uma conta de auth ÓRFÃ (sem linha em public.users) pelo e-mail. Usada como rollback quando o signup cria a conta mas o registro local falha. A guarda "sem public.users" impede apagar usuários válidos.';
