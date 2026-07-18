-- ============================================================================
-- Troca de e-mail de cliente já convertido (contrato) — atômica.
-- ============================================================================
-- Pedido do cliente (2026-07-17): o e-mail precisa ser editável em todo o
-- funil. Antes da conversão proposta→contrato basta atualizar leads.email
-- (RLS de leads já permite para vendedor/admin). DEPOIS da conversão o
-- e-mail é o LOGIN do cliente no app E a chave de acesso dele aos próprios
-- dados (RLS do app cliente compara auth_user_email() com leads.email — ver
-- 20260610120200_tracking_linked_client_select). Trocar só um dos lugares
-- quebra login ou acesso; por isso esta RPC troca TUDO na mesma transação:
--
--   public.users.email  → login/lookup do painel (coluna imutável por
--                         trigger para o próprio usuário; aqui roda como
--                         definer, mesma mecânica do admin_delete_app_user)
--   auth.users.email    → login no GoTrue
--   auth.identities     → identity_data/email/provider_id (varia por versão
--                         do GoTrue; best-effort como no delete)
--   leads.email         → RLS por e-mail do app cliente + exibição do funil
--
-- Sessões/refresh tokens do cliente são revogados (best-effort): o JWT
-- carrega claim de e-mail usada pela RLS — sessão antiga ficaria com o
-- e-mail velho até expirar. O cliente loga de novo com o e-mail novo.
--
-- Permissão: quem edita o funil — Admin Master ou Admin nível documentação
-- (mesmo gate do canEditFunil client-side / tg_require_funil, sem vendedor:
-- trocar login de conta existente é mais sensível que editar lead).
-- ============================================================================

create or replace function public.admin_update_client_email(
  p_user_id  uuid,
  p_new_email text
)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_profile   public.profile_types;
  v_lead_id   uuid;
  v_old_email text;
  v_new_email text := lower(trim(p_new_email));
begin
  if not (public.auth_is_admin_master() or public.auth_is_admin_documentacao()) then
    raise exception 'admin_update_client_email: requer Admin Master ou Admin documentação'
      using errcode = '42501';
  end if;

  if v_new_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
    raise exception 'admin_update_client_email: e-mail inválido'
      using errcode = '22000';
  end if;

  select profile_type, lead_id, email
    into v_profile, v_lead_id, v_old_email
    from public.users
   where id = p_user_id;

  if v_profile is null then
    raise exception 'admin_update_client_email: usuário % não encontrado', p_user_id
      using errcode = 'P0002';
  end if;

  if v_profile <> 'Cliente'::profile_types then
    raise exception 'admin_update_client_email: só perfis Cliente podem ser alterados por aqui'
      using errcode = '42501';
  end if;

  if v_new_email = lower(coalesce(v_old_email, '')) then
    return; -- nada a fazer
  end if;

  -- Unicidade: o e-mail novo não pode pertencer a outra conta (auth ou painel).
  if exists (select 1 from auth.users u
              where lower(u.email) = v_new_email and u.id <> p_user_id)
     or exists (select 1 from public.users pu
                 where lower(pu.email) = v_new_email and pu.id <> p_user_id) then
    raise exception 'admin_update_client_email: o e-mail % já está em uso', v_new_email
      using errcode = '23505';
  end if;

  -- 1) Painel (auditado pelo trigger de users).
  update public.users
     set email = v_new_email
   where id = p_user_id;

  -- 2) Login no GoTrue.
  update auth.users
     set email = v_new_email
   where id = p_user_id;

  -- 3) Identities — o schema varia por versão do GoTrue; cada passo é
  --    encapsulado para nunca derrubar a transação principal (mesma
  --    mecânica do admin_delete_app_user).
  begin
    update auth.identities
       set identity_data =
             jsonb_set(coalesce(identity_data, '{}'::jsonb), '{email}', to_jsonb(v_new_email))
     where user_id = p_user_id;
  exception when others then null;
  end;

  begin
    update auth.identities set email = v_new_email where user_id = p_user_id;
  exception when others then null;
  end;

  begin
    -- Versões antigas usam provider_id = e-mail para o provider 'email'.
    update auth.identities
       set provider_id = v_new_email
     where user_id = p_user_id
       and provider = 'email'
       and v_old_email is not null
       and lower(provider_id) = lower(v_old_email);
  exception when others then null;
  end;

  -- 4) Lead vinculado — RLS por e-mail do app cliente e exibição do funil.
  if v_lead_id is not null then
    update public.leads
       set email = v_new_email
     where id = v_lead_id;
  end if;

  -- 5) Revoga sessões/refresh tokens (best-effort): o claim de e-mail do JWT
  --    antigo não bate mais com leads/users; o cliente reloga com o novo.
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

revoke all on function public.admin_update_client_email(uuid, text) from public;
grant execute on function public.admin_update_client_email(uuid, text) to authenticated;

comment on function public.admin_update_client_email(uuid, text) is
  'Troca o e-mail de um Cliente já convertido em contrato: public.users + auth.users + auth.identities + leads na mesma transação, revogando sessões (o e-mail é login e chave de RLS do app cliente). Admin Master ou Admin documentação.';
