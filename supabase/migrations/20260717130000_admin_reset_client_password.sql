-- ============================================================================
-- Reenvio de senha do cliente do app — gera senha nova no servidor.
-- ============================================================================
-- Pedido do cliente (2026-07-17): botão "Reenviar senha" nos detalhes do
-- cliente do painel, para quando o e-mail de credenciais da criação não
-- chegou. O fluxo antigo de resetPasswordForEmail (e-mail nativo do
-- Supabase) está fora de uso — limitado a 2/hora e com template genérico;
-- as credenciais saem pela Edge Function send-credentials-email (Resend).
--
-- A RPC gera a senha AQUI (24 chars hex de gen_random_bytes — atende a
-- política de 8+ e nunca consta em HIBP), grava o hash bcrypt direto em
-- auth.users e devolve a senha em texto para o painel repassar à Edge
-- Function. Sessões/refresh tokens antigos são revogados (se alguém estava
-- logado com a senha antiga, deixa de estar — reset é evento de segurança).
--
-- Permissão: Admin Master ou Admin documentação (mesmo gate da troca de
-- e-mail, admin_update_client_email). Só perfil Cliente.
-- ============================================================================

create or replace function public.admin_reset_client_password(p_user_id uuid)
returns text
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  v_profile  public.profile_types;
  v_password text;
begin
  if not (public.auth_is_admin_master() or public.auth_is_admin_documentacao()) then
    raise exception 'admin_reset_client_password: requer Admin Master ou Admin documentação'
      using errcode = '42501';
  end if;

  select profile_type into v_profile
    from public.users
   where id = p_user_id
     and is_deleted = false;

  if v_profile is null then
    raise exception 'admin_reset_client_password: usuário % não encontrado', p_user_id
      using errcode = 'P0002';
  end if;

  if v_profile <> 'Cliente'::profile_types then
    raise exception 'admin_reset_client_password: só perfis Cliente podem ter a senha reenviada por aqui'
      using errcode = '42501';
  end if;

  -- 24 caracteres hex (letras+dígitos): compatível com a política do GoTrue
  -- (min 8 + HIBP) e forte o bastante para nunca colidir com senha vazada.
  v_password := encode(extensions.gen_random_bytes(12), 'hex');

  update auth.users
     set encrypted_password = extensions.crypt(v_password, extensions.gen_salt('bf'))
   where id = p_user_id;

  -- Revoga sessões/refresh tokens em vigor (best-effort — schema varia por
  -- versão do GoTrue; nunca derruba a transação principal).
  begin
    delete from auth.sessions where user_id = p_user_id;
  exception when others then null;
  end;

  begin
    delete from auth.refresh_tokens where user_id = p_user_id::text;
  exception when others then null;
  end;

  return v_password;
end;
$$;

revoke all on function public.admin_reset_client_password(uuid) from public;
grant execute on function public.admin_reset_client_password(uuid) to authenticated;

comment on function public.admin_reset_client_password(uuid) is
  'Gera senha forte nova para um Cliente do app (hash bcrypt direto em auth.users), revoga as sessões e devolve a senha para o painel reenviar via send-credentials-email. Admin Master ou Admin documentação.';
