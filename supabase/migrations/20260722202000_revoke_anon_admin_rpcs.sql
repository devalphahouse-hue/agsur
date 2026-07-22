-- ============================================================================
-- Revoga EXECUTE de anon nas RPCs administrativas
-- ============================================================================
-- Descoberto na revisão da 20260722201000: as default privileges do Supabase
-- concedem EXECUTE em função nova de public DIRETAMENTE a anon/authenticated/
-- service_role — então o padrão "revoke all from public + grant to
-- authenticated" usado em todas as RPCs admin NÃO removia o grant direto de
-- anon. Nenhuma exposição real aconteceu: todas têm gate interno de perfil
-- (auth_is_admin_master()/funil), que devolve 42501 para anon. Isto é
-- defesa em camadas: anon não deve nem poder CHAMAR função administrativa.
--
-- Idempotente; reversível com grant execute ... to anon (não fazer).
-- ============================================================================

revoke execute on function public.admin_delete_app_user(uuid) from anon;
revoke execute on function public.admin_purge_orphan_auth_user(text) from anon;
revoke execute on function public.admin_update_client_email(uuid, text) from anon;
revoke execute on function public.admin_reset_client_password(uuid) from anon;
revoke execute on function public.admin_release_stuck_email(text) from anon;
