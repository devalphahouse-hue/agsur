-- ============================================================================
-- Defesa em camadas — tabelas restantes
--
-- 1) Tabelas só de gerência (Vendedor/Admin escreve, ninguém mais):
--    notes, user_aircraft, pilot_clients, oficina_clients
--
-- 2) Tabelas com ownership (próprio user escreve E gerência escreve):
--    address       — created_by = caller   OU Vendedor/Admin
--    guarantee     — user_id   = caller    OU Vendedor/Admin OU oficina vinculada
--    pilot_certificates — user_id = caller OU Admin
--    order_parts   — user_id   = caller    OU Admin
--    requested_parts — order pertence ao caller OU Admin
-- ============================================================================

-- =========================== Apenas gerência ===========================
DO $$
DECLARE
  t text;
  tables text[] := ARRAY['notes', 'user_aircraft', 'pilot_clients', 'oficina_clients'];
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


-- =========================== address (created_by) ===========================
CREATE OR REPLACE FUNCTION public.tg_address_ownership()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller_id uuid := auth.uid();
BEGIN
  IF public.auth_is_service_role() THEN RETURN COALESCE(NEW, OLD); END IF;
  IF caller_id IS NULL THEN
    RAISE EXCEPTION 'address: anonymous writes blocked' USING ERRCODE = '42501';
  END IF;
  IF public.auth_is_seller_or_admin() THEN RETURN COALESCE(NEW, OLD); END IF;

  IF TG_OP = 'INSERT' THEN
    IF NEW.created_by IS DISTINCT FROM caller_id THEN
      RAISE EXCEPTION 'address.insert: created_by must equal auth.uid()' USING ERRCODE = '42501';
    END IF;
    RETURN NEW;
  END IF;
  IF TG_OP IN ('UPDATE', 'DELETE') THEN
    IF OLD.created_by IS DISTINCT FROM caller_id THEN
      RAISE EXCEPTION 'address.%: only owner or Vendedor/Admin', TG_OP USING ERRCODE = '42501';
    END IF;
    RETURN COALESCE(NEW, OLD);
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS hardening_address_ownership ON public.address;
CREATE TRIGGER hardening_address_ownership
  BEFORE INSERT OR UPDATE OR DELETE ON public.address
  FOR EACH ROW EXECUTE FUNCTION public.tg_address_ownership();


-- =========================== guarantee (user_id + oficina vinculada) ===========================
CREATE OR REPLACE FUNCTION public.tg_guarantee_ownership()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller_id uuid := auth.uid();
  is_oficina_linked boolean := false;
  target_user uuid;
BEGIN
  IF public.auth_is_service_role() THEN RETURN COALESCE(NEW, OLD); END IF;
  IF caller_id IS NULL THEN
    RAISE EXCEPTION 'guarantee: anonymous writes blocked' USING ERRCODE = '42501';
  END IF;
  IF public.auth_is_seller_or_admin() THEN RETURN COALESCE(NEW, OLD); END IF;

  target_user := COALESCE(NEW.user_id, OLD.user_id);

  -- ownership direto
  IF target_user = caller_id THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  -- oficina vinculada ao cliente
  SELECT EXISTS (
    SELECT 1 FROM public.oficina_clients oc
    WHERE oc.oficina_id = caller_id
      AND oc.client_id = target_user
  ) INTO is_oficina_linked;

  IF is_oficina_linked THEN
    -- oficina criando para cliente vinculado
    IF TG_OP = 'INSERT' AND NEW.created_by IS DISTINCT FROM caller_id THEN
      RAISE EXCEPTION 'guarantee.insert: created_by must equal auth.uid()' USING ERRCODE = '42501';
    END IF;
    RETURN COALESCE(NEW, OLD);
  END IF;

  RAISE EXCEPTION 'guarantee.%: not authorized', TG_OP USING ERRCODE = '42501';
END;
$$;

DROP TRIGGER IF EXISTS hardening_guarantee_ownership ON public.guarantee;
CREATE TRIGGER hardening_guarantee_ownership
  BEFORE INSERT OR UPDATE OR DELETE ON public.guarantee
  FOR EACH ROW EXECUTE FUNCTION public.tg_guarantee_ownership();


-- =========================== pilot_certificates (user_id) ===========================
CREATE OR REPLACE FUNCTION public.tg_pilot_certificates_ownership()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller_id uuid := auth.uid();
BEGIN
  IF public.auth_is_service_role() THEN RETURN COALESCE(NEW, OLD); END IF;
  IF caller_id IS NULL THEN
    RAISE EXCEPTION 'pilot_certificates: anonymous writes blocked' USING ERRCODE = '42501';
  END IF;
  IF public.auth_is_admin() THEN RETURN COALESCE(NEW, OLD); END IF;
  IF COALESCE(NEW.user_id, OLD.user_id) = caller_id THEN RETURN COALESCE(NEW, OLD); END IF;
  RAISE EXCEPTION 'pilot_certificates.%: not authorized', TG_OP USING ERRCODE = '42501';
END;
$$;

DROP TRIGGER IF EXISTS hardening_pilot_certificates_ownership ON public.pilot_certificates;
CREATE TRIGGER hardening_pilot_certificates_ownership
  BEFORE INSERT OR UPDATE OR DELETE ON public.pilot_certificates
  FOR EACH ROW EXECUTE FUNCTION public.tg_pilot_certificates_ownership();


-- =========================== order_parts (user_id) ===========================
CREATE OR REPLACE FUNCTION public.tg_order_parts_ownership()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller_id uuid := auth.uid();
BEGIN
  IF public.auth_is_service_role() THEN RETURN COALESCE(NEW, OLD); END IF;
  IF caller_id IS NULL THEN
    RAISE EXCEPTION 'order_parts: anonymous writes blocked' USING ERRCODE = '42501';
  END IF;
  IF public.auth_is_admin() THEN RETURN COALESCE(NEW, OLD); END IF;
  IF COALESCE(NEW.user_id, OLD.user_id) = caller_id THEN RETURN COALESCE(NEW, OLD); END IF;
  RAISE EXCEPTION 'order_parts.%: not authorized', TG_OP USING ERRCODE = '42501';
END;
$$;

DROP TRIGGER IF EXISTS hardening_order_parts_ownership ON public.order_parts;
CREATE TRIGGER hardening_order_parts_ownership
  BEFORE INSERT OR UPDATE OR DELETE ON public.order_parts
  FOR EACH ROW EXECUTE FUNCTION public.tg_order_parts_ownership();


-- =========================== requested_parts (via order_parts) ===========================
CREATE OR REPLACE FUNCTION public.tg_requested_parts_ownership()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller_id uuid := auth.uid();
  order_owner uuid;
  order_id_target uuid;
BEGIN
  IF public.auth_is_service_role() THEN RETURN COALESCE(NEW, OLD); END IF;
  IF caller_id IS NULL THEN
    RAISE EXCEPTION 'requested_parts: anonymous writes blocked' USING ERRCODE = '42501';
  END IF;
  IF public.auth_is_admin() THEN RETURN COALESCE(NEW, OLD); END IF;

  order_id_target := COALESCE(NEW.order_id, OLD.order_id);
  SELECT user_id INTO order_owner FROM public.order_parts WHERE id = order_id_target;
  IF order_owner = caller_id THEN RETURN COALESCE(NEW, OLD); END IF;
  RAISE EXCEPTION 'requested_parts.%: not authorized', TG_OP USING ERRCODE = '42501';
END;
$$;

DROP TRIGGER IF EXISTS hardening_requested_parts_ownership ON public.requested_parts;
CREATE TRIGGER hardening_requested_parts_ownership
  BEFORE INSERT OR UPDATE OR DELETE ON public.requested_parts
  FOR EACH ROW EXECUTE FUNCTION public.tg_requested_parts_ownership();
