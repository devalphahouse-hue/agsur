-- ============================================================================
-- Defesa em camadas — tabelas administrativas restantes
--
-- aircraft_documents, aircraft_manuals — Admin/Vendedor (gerência da aeronave)
-- certificates                          — Admin/Vendedor (emissão)
-- service_letter                        — Admin/Vendedor
-- internal_logs                         — apenas service_role
-- ============================================================================

DO $$
DECLARE
  t text;
  tables text[] := ARRAY[
    'aircraft_documents', 'aircraft_manuals',
    'certificates', 'service_letter'
  ];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS hardening_require_seller_or_admin ON public.%I', t);
    EXECUTE format(
      'CREATE TRIGGER hardening_require_seller_or_admin
         BEFORE INSERT OR UPDATE OR DELETE ON public.%I
         FOR EACH ROW EXECUTE FUNCTION public.tg_require_seller_or_admin()',
      t
    );
  END LOOP;
END;
$$;


-- internal_logs: só service_role pode escrever (logs nunca via cliente)
CREATE OR REPLACE FUNCTION public.tg_require_service_role()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF public.auth_is_service_role() THEN
    RETURN COALESCE(NEW, OLD);
  END IF;
  RAISE EXCEPTION '%.%: writes restricted to service_role', TG_TABLE_SCHEMA, TG_TABLE_NAME
    USING ERRCODE = '42501';
END;
$$;

DROP TRIGGER IF EXISTS hardening_require_service_role ON public.internal_logs;
CREATE TRIGGER hardening_require_service_role
  BEFORE INSERT OR UPDATE OR DELETE ON public.internal_logs
  FOR EACH ROW EXECUTE FUNCTION public.tg_require_service_role();
