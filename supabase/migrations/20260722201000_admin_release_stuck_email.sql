-- ============================================================================
-- RPC admin_release_stuck_email — autocura do 422 na criação de cliente
-- ============================================================================
-- Mesmo com o backfill (20260722200000), uma conta órfã nova pode nascer de um
-- signup interrompido (aconteceu em 17-18/07, DEPOIS da RPC de rollback
-- existir — o rollback client-side não roda em todo caminho de falha). Sem
-- esta RPC, cada órfã nova volta a travar a conversão proposta→contrato com o
-- 422 user_already_exists até alguém destravar o e-mail na mão.
--
-- O painel passa a chamá-la quando o signup recusa E a re-busca não encontra
-- cadastro ativo reutilizável: se o e-mail estiver preso em conta EXCLUÍDA
-- (is_deleted=true) ou ÓRFÃ (sem linha em public.users), a RPC aplica o
-- tombstone (mesma mecânica da admin_delete_app_user) e o painel repete o
-- signup UMA vez. Conta ATIVA nunca é tocada — retorna 'ativo' e o painel
-- explica o conflito ao usuário.
--
-- Retorno (text):
--   'livre'    — nada preso no auth com este e-mail (nada a fazer);
--   'ativo'    — o e-mail pertence a um cadastro ATIVO (não tocado);
--   'liberado' — estava preso (excluído ou órfã); tombstone aplicado, e-mail
--                liberado para signup.
--
-- Permissão: quem opera o funil (Admin Master, Admin documentação, Vendedor) —
-- os mesmos perfis que convertem proposta e criam cliente. SECURITY DEFINER
-- com search_path fixo; EXECUTE revogado de public/anon.
-- ============================================================================

create or replace function public.admin_release_stuck_email(p_email text)
returns text
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid        uuid;
  v_old_email  text;
  v_tomb       text;
  v_has_users  boolean;
  v_is_deleted boolean;
begin
  if not (
    public.auth_is_admin_master()
    or public.auth_is_admin_documentacao()
    or public.auth_is_vendedor()
  ) then
    raise exception 'admin_release_stuck_email: sem permissão'
      using errcode = '42501';
  end if;

  if p_email is null or length(trim(p_email)) = 0 then
    return 'livre';
  end if;

  -- Nunca opere sobre um tombstone (evita re-tombstonear ou enumerar).
  if lower(trim(p_email)) like 'deleted+%@deleted.agsur.local' then
    return 'livre';
  end if;

  select au.id, au.email
    into v_uid, v_old_email
    from auth.users au
   where lower(au.email) = lower(trim(p_email))
   order by au.created_at desc
   limit 1;

  if v_uid is null then
    return 'livre';
  end if;

  select exists(select 1 from public.users pu where pu.id = v_uid)
    into v_has_users;

  if v_has_users then
    select pu.is_deleted into v_is_deleted
      from public.users pu
     where pu.id = v_uid;
    if coalesce(v_is_deleted, false) = false then
      -- Cadastro válido: NUNCA liberar por aqui.
      return 'ativo';
    end if;
  end if;

  v_tomb := 'deleted+' || v_uid::text || '@deleted.agsur.local';

  if v_has_users then
    -- Caso soft-deleted com e-mail ainda preso (legado que escapar do
    -- backfill): alinha public.users ao estado da admin_delete_app_user.
    update public.users
       set email        = v_tomb,
           is_active    = false,
           device_token = null
     where id = v_uid;
  end if;

  update auth.users
     set email        = v_tomb,
         banned_until = now() + interval '100 years'
   where id = v_uid;

  -- identities: best-effort (schema varia por versão do GoTrue), como na
  -- admin_delete_app_user.
  begin
    update auth.identities
       set identity_data =
             jsonb_set(coalesce(identity_data, '{}'::jsonb), '{email}', to_jsonb(v_tomb))
     where user_id = v_uid;
  exception when others then null;
  end;
  begin
    update auth.identities set email = v_tomb where user_id = v_uid;
  exception when others then null;
  end;
  begin
    update auth.identities
       set provider_id = v_uid::text
     where user_id = v_uid
       and provider = 'email'
       and v_old_email is not null
       and provider_id = v_old_email;
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

  return 'liberado';
end;
$$;

revoke all on function public.admin_release_stuck_email(text) from public;
grant execute on function public.admin_release_stuck_email(text) to authenticated;

comment on function public.admin_release_stuck_email(text) is
  'Libera um e-mail preso no auth (conta excluída com e-mail não-tombstoneado ou conta órfã sem public.users) aplicando o tombstone da admin_delete_app_user. Conta ativa nunca é tocada (retorna ''ativo''). Usada pela autocura do 422 na conversão proposta→contrato e na criação manual de cliente. Perfis do funil.';
