-- ============================================================================
-- Defesa em camadas para Agsur (parte 1 de N).
-- Cria helpers de segurança usados pelos triggers nas próximas migrations.
-- Não toca em policies existentes — RLS atual continua igual.
-- ============================================================================

-- Helper: verifica se o caller é Admin Master.
-- SECURITY DEFINER + search_path fixo para evitar shadowing.
CREATE OR REPLACE FUNCTION public.auth_is_admin_master()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = auth.uid()
      AND u.profile_type = 'Admin Master'::profile_types
  );
$$;

COMMENT ON FUNCTION public.auth_is_admin_master() IS
  'Retorna true se o caller (auth.uid()) tem profile_type = Admin Master. SECURITY DEFINER para bypassar RLS na users.';

REVOKE ALL ON FUNCTION public.auth_is_admin_master() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_is_admin_master() TO authenticated, anon, service_role;


-- Helper: verifica se o caller é Admin (Admin OU Admin Master).
CREATE OR REPLACE FUNCTION public.auth_is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = auth.uid()
      AND (
        u.profile_type IN ('Admin Master'::profile_types, 'Admin'::profile_types)
        OR u.is_admin = true
      )
  );
$$;

COMMENT ON FUNCTION public.auth_is_admin() IS
  'Retorna true se o caller é Admin Master, Admin ou is_admin=true. SECURITY DEFINER.';

REVOKE ALL ON FUNCTION public.auth_is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_is_admin() TO authenticated, anon, service_role;


-- Helper: verifica se o caller é Vendedor (ou superior).
CREATE OR REPLACE FUNCTION public.auth_is_seller_or_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = auth.uid()
      AND (
        u.profile_type IN ('Admin Master'::profile_types, 'Admin'::profile_types, 'Vendedor'::profile_types)
        OR u.is_admin = true
      )
  );
$$;

COMMENT ON FUNCTION public.auth_is_seller_or_admin() IS
  'Retorna true se o caller é Vendedor, Admin ou Admin Master. SECURITY DEFINER.';

REVOKE ALL ON FUNCTION public.auth_is_seller_or_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_is_seller_or_admin() TO authenticated, anon, service_role;


-- Helper: verifica se o caller atual está rodando com role privilegiada
-- (service_role ou postgres). Usado para permitir flows do auth/serviço.
CREATE OR REPLACE FUNCTION public.auth_is_service_role()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT current_setting('request.jwt.claims', true)::jsonb->>'role' = 'service_role'
      OR current_user IN ('postgres', 'supabase_admin', 'service_role');
$$;

COMMENT ON FUNCTION public.auth_is_service_role() IS
  'True quando a query roda como service_role/postgres. Permite bypass das checagens.';

REVOKE ALL ON FUNCTION public.auth_is_service_role() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_is_service_role() TO authenticated, anon, service_role;
