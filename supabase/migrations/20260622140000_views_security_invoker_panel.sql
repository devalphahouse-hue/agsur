-- ============================================================================
-- Segurança 2026-06-22 — fecha IDOR autenticado nas views do painel.
-- ============================================================================
-- As views public.* eram SECURITY DEFINER (security_invoker off) → ignoravam a
-- RLS das tabelas-base. Mesmo após revogar `anon` (migration 20260622130000),
-- qualquer usuário AUTENTICADO (inclusive Cliente/Piloto do app) podia ler dados
-- de terceiros via essas views.
--
-- Liga `security_invoker = on` nas views do painel cuja RLS de base já cobre os
-- perfis certos (verificado): users/leads/contract/proposal/tracking/notes são
-- legíveis por `auth_is_seller_or_admin()` (Admin/Vendedor seguem lendo tudo) e
-- restritos ao dono para Cliente/Piloto (IDOR fechado). company/aircrafts são
-- catálogo (SELECT autenticado); user_aircraft é seller_or_admin OR dono.
--
-- EXCLUÍDAS de propósito:
--  - vw_homepage_dashboard: agrega `financial`/`sales` (admin-only) — ligar aqui
--    zeraria os números para Vendedor. Requer decisão de produto.
--  - vw_my_aircrafts_home / vw_my_aircraft_details: lidas pelo APP CLIENTE, com
--    RLS por cadeia de e-mail; ligar quebraria a leitura do cliente vinculado.
--    (vw_proposal_data e pilot_certificates_view já estavam com invoker on.)
--
-- Reversível: `alter view <v> set (security_invoker = off);`
-- ============================================================================

alter view public.vw_get_clients    set (security_invoker = on);
alter view public.vw_get_pilots     set (security_invoker = on);
alter view public.vw_contract_data  set (security_invoker = on);
alter view public.vw_notes_details  set (security_invoker = on);
alter view public.vw_all_tracking   set (security_invoker = on);
