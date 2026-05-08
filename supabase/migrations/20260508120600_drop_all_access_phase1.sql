-- ============================================================================
-- FASE 2 RLS — Drop all_access em tabelas de baixo risco operacional
--
-- Mantém all_access nas tabelas com fluxos cliente complexos (proposal,
-- contract, tracking, etc.) — essas serão tratadas na FASE 3 quando o
-- domínio cliente estiver mapeado em detalhe.
--
-- Tabelas neste batch:
--   users       — read: admin OU próprio user; demais writes via trigger
--   financial   — só Admin (writes já bloqueados por trigger; agora reads também)
--   financing_rates — idem (só Admin)
--   sales       — idem (só Admin)
--   company     — read: authenticated; write: Admin Master (write já via trigger)
--
-- PostgREST combina policies com OR. Drop all_access deixa só as policies
-- específicas listadas aqui.
-- ============================================================================

-- =========================== users ===========================
DROP POLICY IF EXISTS all_access ON public.users;

-- SELECT: admin lê todos (pelo painel) OU próprio user (pelo app)
DROP POLICY IF EXISTS users_self_or_admin_select ON public.users;
CREATE POLICY users_self_or_admin_select
  ON public.users
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid()
    OR public.auth_is_seller_or_admin()
  );

-- INSERT: já existia user_security_insert; reaproveitamos. Apenas garantir que existe.
DROP POLICY IF EXISTS user_security_insert ON public.users;
CREATE POLICY user_security_insert
  ON public.users
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- UPDATE: próprio user (a trigger já bloqueia campos sensíveis)
--         OU Admin Master (via trigger, pode tudo)
DROP POLICY IF EXISTS user_security_update ON public.users;
CREATE POLICY user_security_update
  ON public.users
  FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid()
    OR public.auth_is_admin_master()
  )
  WITH CHECK (
    id = auth.uid()
    OR public.auth_is_admin_master()
  );

-- DELETE: só Admin Master OU self
DROP POLICY IF EXISTS users_self_or_admin_master_delete ON public.users;
CREATE POLICY users_self_or_admin_master_delete
  ON public.users
  FOR DELETE
  TO authenticated
  USING (
    id = auth.uid()
    OR public.auth_is_admin_master()
  );


-- =========================== financial ===========================
DROP POLICY IF EXISTS all_access ON public.financial;
DROP POLICY IF EXISTS admin_only ON public.financial;
CREATE POLICY admin_only
  ON public.financial
  FOR ALL
  TO authenticated
  USING (public.auth_is_admin())
  WITH CHECK (public.auth_is_admin());


-- =========================== financing_rates ===========================
DROP POLICY IF EXISTS all_access ON public.financing_rates;
DROP POLICY IF EXISTS admin_only ON public.financing_rates;
CREATE POLICY admin_only
  ON public.financing_rates
  FOR ALL
  TO authenticated
  USING (public.auth_is_admin())
  WITH CHECK (public.auth_is_admin());


-- =========================== sales ===========================
DROP POLICY IF EXISTS all_access ON public.sales;
DROP POLICY IF EXISTS admin_only ON public.sales;
CREATE POLICY admin_only
  ON public.sales
  FOR ALL
  TO authenticated
  USING (public.auth_is_admin())
  WITH CHECK (public.auth_is_admin());


-- =========================== company ===========================
DROP POLICY IF EXISTS all_access ON public.company;
-- read: qualquer usuário autenticado (footer/header da empresa)
DROP POLICY IF EXISTS company_read_authenticated ON public.company;
CREATE POLICY company_read_authenticated
  ON public.company
  FOR SELECT
  TO authenticated
  USING (true);
-- write: Admin Master (writes já bloqueados pela trigger genérica também)
DROP POLICY IF EXISTS company_write_admin_master ON public.company;
CREATE POLICY company_write_admin_master
  ON public.company
  FOR INSERT
  TO authenticated
  WITH CHECK (public.auth_is_admin_master());
DROP POLICY IF EXISTS company_update_admin_master ON public.company;
CREATE POLICY company_update_admin_master
  ON public.company
  FOR UPDATE
  TO authenticated
  USING (public.auth_is_admin_master())
  WITH CHECK (public.auth_is_admin_master());
DROP POLICY IF EXISTS company_delete_admin_master ON public.company;
CREATE POLICY company_delete_admin_master
  ON public.company
  FOR DELETE
  TO authenticated
  USING (public.auth_is_admin_master());
