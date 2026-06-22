-- ============================================================================
-- Segurança 2026-06-22 — fecha leak de agregados financeiros no dashboard.
-- ============================================================================
-- vw_homepage_dashboard era SECURITY DEFINER e agrega `financial`/`sales`
-- (tabelas admin-only) → qualquer usuário AUTENTICADO podia ler agregados
-- financeiros da empresa via PostgREST direto.
--
-- Liga security_invoker=on. Seguro porque:
--  - todos os getters do VwHomepageDashboardRow são nullable (int?/double?);
--  - a UI do painel já gateia os widgets financeiros por isAdminMaster;
--  - sob invoker: Admin (is_admin) vê tudo; Vendedor recebe NULL nos campos de
--    financial/sales (admin-only) — sem crash, e a UI já os esconde; Cliente/
--    Piloto ficam filtrados pela RLS (leak fechado).
--
-- VALIDAR: dashboard do Admin Master deve carregar com números completos; o do
-- Vendedor não deve quebrar. Rollback: alter view ... set (security_invoker=off).
-- ============================================================================

alter view public.vw_homepage_dashboard set (security_invoker = on);
