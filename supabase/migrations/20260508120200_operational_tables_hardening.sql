-- ============================================================================
-- Defesa em camadas — tabelas operacionais
--
-- Bloqueia writes (INSERT/UPDATE/DELETE) por perfis que não deveriam
-- escrever nelas (Cliente/Piloto/Oficina), mesmo se a policy all_access
-- ainda existir. Permite leitura — não toca SELECT.
--
-- Categorias:
--   ADMIN_ONLY (Admin Master, Admin, is_admin=true):
--     financial, financing_rates, company, sales
--
--   SELLER_OR_ADMIN (+ Vendedor):
--     proposal, proposal_item, proposal_financing,
--     contract, contract_terms, leads,
--     aircrafts, aircraft_items, available_aircrafts,
--     category, services_offering, services,
--     tracking, tracking_details
--
-- Não inclui (intencionalmente): users (já tem trigger próprio),
-- guarantee, certificates, service_letter, order_parts, requested_parts,
-- pilot_clients, oficina_clients, address, notes, user_aircraft —
-- esses têm fluxos que envolvem Cliente/Piloto/Oficina e merecem
-- regras mais específicas (próxima migration).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.tg_require_admin()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF public.auth_is_service_role() THEN
    RETURN COALESCE(NEW, OLD);
  END IF;
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION '%.%: anonymous writes blocked', TG_TABLE_SCHEMA, TG_TABLE_NAME
      USING ERRCODE = '42501';
  END IF;
  IF NOT public.auth_is_admin() THEN
    RAISE EXCEPTION '%.%: requires Admin/Admin Master profile', TG_TABLE_SCHEMA, TG_TABLE_NAME
      USING ERRCODE = '42501';
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

COMMENT ON FUNCTION public.tg_require_admin() IS
  'Trigger genérica: bloqueia writes (INSERT/UPDATE/DELETE) exceto para Admin/Admin Master/service_role.';


CREATE OR REPLACE FUNCTION public.tg_require_seller_or_admin()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF public.auth_is_service_role() THEN
    RETURN COALESCE(NEW, OLD);
  END IF;
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION '%.%: anonymous writes blocked', TG_TABLE_SCHEMA, TG_TABLE_NAME
      USING ERRCODE = '42501';
  END IF;
  IF NOT public.auth_is_seller_or_admin() THEN
    RAISE EXCEPTION '%.%: requires Vendedor/Admin/Admin Master profile', TG_TABLE_SCHEMA, TG_TABLE_NAME
      USING ERRCODE = '42501';
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

COMMENT ON FUNCTION public.tg_require_seller_or_admin() IS
  'Trigger genérica: bloqueia writes exceto para Vendedor/Admin/Admin Master/service_role.';


-- =========================== ADMIN_ONLY ===========================
DO $$
DECLARE
  t text;
  tables text[] := ARRAY['financial', 'financing_rates', 'company', 'sales'];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS hardening_require_admin ON public.%I', t);
    EXECUTE format(
      'CREATE TRIGGER hardening_require_admin
         BEFORE INSERT OR UPDATE OR DELETE ON public.%I
         FOR EACH ROW EXECUTE FUNCTION public.tg_require_admin()',
      t
    );
  END LOOP;
END;
$$;


-- =========================== SELLER_OR_ADMIN ===========================
DO $$
DECLARE
  t text;
  tables text[] := ARRAY[
    'proposal', 'proposal_item', 'proposal_financing',
    'contract', 'contract_terms', 'leads',
    'aircrafts', 'aircraft_items', 'available_aircrafts',
    'category', 'services_offering',
    'tracking', 'tracking_details'
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
