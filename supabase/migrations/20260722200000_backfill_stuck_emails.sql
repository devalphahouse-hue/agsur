-- ============================================================================
-- Backfill 2026-07-22 — libera TODOS os e-mails presos no auth (legado + órfãs)
-- ============================================================================
-- Contexto: o tombstone que libera o e-mail na exclusão só entrou na
-- admin_delete_app_user em 20260622120000. Quem foi excluído antes (4 pela RPC
-- antiga + 49 marcados por UPDATE direto, sem ban) segurou o e-mail no
-- auth.users para sempre. Além deles, sobraram contas de auth ÓRFÃS (sem linha
-- em public.users) de signups interrompidos — inclusive 2 recentes (17-18/07).
--
-- Sintoma dos dois casos: o painel busca o cliente com is_deleted=false (não
-- acha), cai no signup, toma 422 user_already_exists e aborta — deadlock
-- permanente da conversão proposta→contrato para aquele e-mail. Medido em
-- 2026-07-20/22; 6 casos já haviam sido destravados na mão com este mesmo
-- procedimento (felter.dev, piloto.felter, csilva_thiago, jeroni,
-- rodrigozuanazzi, thg_usa).
--
-- O que faz (idempotente — os filtros excluem quem já tem tombstone):
--   1) Usuários soft-deleted (public.users.is_deleted=true) com e-mail ainda
--      preso no auth: aplica o MESMO tombstone da admin_delete_app_user
--      (public.users + auth.users + identities), revoga sessões e BANE a
--      conta (decisão do dono, 2026-07-22: os 49 excluídos por UPDATE direto
--      ficam banidos como a RPC teria feito — conta "excluída" não loga).
--   2) Contas de auth órfãs (sem linha em public.users): tombstone no auth +
--      identities, ban e revogação de sessões. Preferido ao hard-delete da
--      admin_purge_orphan_auth_user por ser reversível (rename, não DELETE).
--
-- NUNCA toca em conta com public.users ativo (is_deleted=false) — o critério
-- de cada laço garante isso por construção.
--
-- Rollback pontual: rename do e-mail de volta + banned_until=null (o e-mail
-- original não é gravado aqui; recuperável do audit log / backup se preciso).
-- ============================================================================

do $$
declare
  r      record;
  v_tomb text;
begin
  -- ── 1) Legado soft-deleted: users.is_deleted=true, e-mail preso no auth ──
  for r in
    select u.id, au.email as auth_email
      from public.users u
      join auth.users au on au.id = u.id
     where u.is_deleted = true
       and au.email not like 'deleted+%@deleted.agsur.local'
  loop
    v_tomb := 'deleted+' || r.id::text || '@deleted.agsur.local';

    update public.users
       set email        = v_tomb,
           is_active    = false,
           device_token = null
     where id = r.id;

    update auth.users
       set email        = v_tomb,
           banned_until = now() + interval '100 years'
     where id = r.id;

    -- identities: mesmo best-effort da admin_delete_app_user (o schema de
    -- auth.identities varia por versão do GoTrue).
    begin
      update auth.identities
         set identity_data =
               jsonb_set(coalesce(identity_data, '{}'::jsonb), '{email}', to_jsonb(v_tomb))
       where user_id = r.id;
    exception when others then null;
    end;
    begin
      update auth.identities set email = v_tomb where user_id = r.id;
    exception when others then null;
    end;
    begin
      update auth.identities
         set provider_id = r.id::text
       where user_id = r.id
         and provider = 'email'
         and provider_id = r.auth_email;
    exception when others then null;
    end;

    begin
      delete from auth.sessions where user_id = r.id;
    exception when others then null;
    end;
    begin
      delete from auth.refresh_tokens where user_id = r.id::text;
    exception when others then null;
    end;
  end loop;

  -- ── 2) Órfãs: conta em auth.users SEM linha em public.users ──────────────
  -- Guarda de idade: uma conversão EM ANDAMENTO no momento do push tem uma
  -- janela (signup feito, insert local em voo) em que a conta é tecnicamente
  -- órfã — não pode ser tombstoneada. 1h cobre a janela com folga.
  for r in
    select au.id, au.email as auth_email
      from auth.users au
     where not exists (select 1 from public.users pu where pu.id = au.id)
       and au.email not like 'deleted+%@deleted.agsur.local'
       and au.created_at < now() - interval '1 hour'
  loop
    v_tomb := 'deleted+' || r.id::text || '@deleted.agsur.local';

    update auth.users
       set email        = v_tomb,
           banned_until = now() + interval '100 years'
     where id = r.id;

    begin
      update auth.identities
         set identity_data =
               jsonb_set(coalesce(identity_data, '{}'::jsonb), '{email}', to_jsonb(v_tomb))
       where user_id = r.id;
    exception when others then null;
    end;
    begin
      update auth.identities set email = v_tomb where user_id = r.id;
    exception when others then null;
    end;
    begin
      update auth.identities
         set provider_id = r.id::text
       where user_id = r.id
         and provider = 'email'
         and provider_id = r.auth_email;
    exception when others then null;
    end;

    begin
      delete from auth.sessions where user_id = r.id;
    exception when others then null;
    end;
    begin
      delete from auth.refresh_tokens where user_id = r.id::text;
    exception when others then null;
    end;
  end loop;
end $$;
