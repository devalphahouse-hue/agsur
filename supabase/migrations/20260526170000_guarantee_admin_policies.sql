-- ============================================================================
-- Garante que QUALQUER admin (Admin/Admin Master por profile_type, não só
-- is_admin=true) veja e revise as solicitações de garantia no painel.
--
-- As policies existentes (adm_select/adm_update) checavam apenas
-- users.is_admin = true, mas há Admin/Admin Master com is_admin=false no banco,
-- que então não enxergavam nenhuma garantia. Adicionamos policies permissivas
-- baseadas em auth_is_admin() (profile_type Admin/Admin Master OU is_admin),
-- consistente com o resto do schema. Permissivas (OR), só liberam.
-- ============================================================================

DROP POLICY IF EXISTS guarantee_admin_select ON public.guarantee;
CREATE POLICY guarantee_admin_select
  ON public.guarantee
  FOR SELECT TO authenticated
  USING (public.auth_is_admin());

DROP POLICY IF EXISTS guarantee_admin_write ON public.guarantee;
CREATE POLICY guarantee_admin_write
  ON public.guarantee
  FOR ALL TO authenticated
  USING (public.auth_is_admin())
  WITH CHECK (public.auth_is_admin());
