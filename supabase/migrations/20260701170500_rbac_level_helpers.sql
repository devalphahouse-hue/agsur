-- ============================================================================
-- RBAC do painel — helpers de nível (Fase 7, parte 1: aditivo, JÁ APLICADO)
--
-- Funções SECURITY DEFINER que distinguem os sub-níveis de Admin introduzidos
-- em 20260701170000_users_access_level.sql (coluna users.access_level).
--
-- São ADITIVAS: nada as referencia ainda. A aplicação nos triggers está na
-- migration 20260701171000_rbac_level_enforcement.sql (a validar com rls-smoke
-- antes de produção — ver comentários lá).
-- ============================================================================

-- access_level do caller (NULL para quem não é Admin).
CREATE OR REPLACE FUNCTION public.auth_access_level()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT u.access_level FROM public.users u WHERE u.id = auth.uid();
$$;
REVOKE ALL ON FUNCTION public.auth_access_level() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_access_level() TO authenticated, anon, service_role;

-- Documentação: Admin Master OU Admin com access_level='documentacao'.
CREATE OR REPLACE FUNCTION public.auth_is_admin_documentacao()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users u WHERE u.id = auth.uid()
      AND (u.profile_type = 'Admin Master'::profile_types
           OR (u.profile_type = 'Admin'::profile_types AND u.access_level = 'documentacao'))
  );
$$;
REVOKE ALL ON FUNCTION public.auth_is_admin_documentacao() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_is_admin_documentacao() TO authenticated, anon, service_role;

-- Recepção: Admin Master OU Admin com access_level != 'documentacao' (recepcao/NULL).
CREATE OR REPLACE FUNCTION public.auth_is_admin_recepcao()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users u WHERE u.id = auth.uid()
      AND (u.profile_type = 'Admin Master'::profile_types
           OR (u.profile_type = 'Admin'::profile_types AND COALESCE(u.access_level,'recepcao') <> 'documentacao'))
  );
$$;
REVOKE ALL ON FUNCTION public.auth_is_admin_recepcao() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_is_admin_recepcao() TO authenticated, anon, service_role;

-- Vendedor puro (para o gate do funil, que soma documentação + vendedor).
CREATE OR REPLACE FUNCTION public.auth_is_vendedor()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users u WHERE u.id = auth.uid()
      AND u.profile_type = 'Vendedor'::profile_types
  );
$$;
REVOKE ALL ON FUNCTION public.auth_is_vendedor() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_is_vendedor() TO authenticated, anon, service_role;
