-- ============================================================================
-- Audit log para operações sensíveis.
--
-- Tabela append-only (sem UPDATE/DELETE pelo cliente). Triggers AFTER
-- registram mudanças em campos privilegiados em users + qualquer escrita
-- em financial e financing_rates.
--
-- Acesso:
--   - INSERT: livre (via trigger SECURITY DEFINER)
--   - SELECT: só Admin Master
--   - UPDATE/DELETE: ninguém via API (apenas service_role/postgres)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.security_audit_log (
  id bigserial PRIMARY KEY,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  actor_id uuid,
  actor_email text,
  table_name text NOT NULL,
  operation text NOT NULL,
  row_id text,
  changed_fields text[],
  before jsonb,
  after jsonb
);

CREATE INDEX IF NOT EXISTS security_audit_log_occurred_at_idx
  ON public.security_audit_log (occurred_at DESC);
CREATE INDEX IF NOT EXISTS security_audit_log_actor_idx
  ON public.security_audit_log (actor_id);
CREATE INDEX IF NOT EXISTS security_audit_log_table_idx
  ON public.security_audit_log (table_name, occurred_at DESC);

ALTER TABLE public.security_audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS audit_select_admin_master ON public.security_audit_log;
CREATE POLICY audit_select_admin_master
  ON public.security_audit_log
  FOR SELECT
  TO authenticated
  USING (public.auth_is_admin_master());

-- Sem policies de INSERT/UPDATE/DELETE: clientes não escrevem direto.
-- A trigger usa SECURITY DEFINER pra inserir.

-- Trigger genérica para registrar escrita
CREATE OR REPLACE FUNCTION public.tg_audit_write()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_actor uuid := auth.uid();
  v_email text;
  v_changed text[] := ARRAY[]::text[];
  v_before jsonb;
  v_after jsonb;
  v_row_id text;
  k text;
BEGIN
  -- email do actor
  IF v_actor IS NOT NULL THEN
    SELECT email INTO v_email FROM auth.users WHERE id = v_actor;
  END IF;

  IF TG_OP = 'INSERT' THEN
    v_after := to_jsonb(NEW);
    v_row_id := COALESCE(v_after->>'id', '');
  ELSIF TG_OP = 'UPDATE' THEN
    v_before := to_jsonb(OLD);
    v_after := to_jsonb(NEW);
    v_row_id := COALESCE(v_after->>'id', '');
    -- diff: apenas campos que mudaram
    FOR k IN SELECT key FROM jsonb_each(v_after) LOOP
      IF v_before->k IS DISTINCT FROM v_after->k THEN
        v_changed := v_changed || k;
      END IF;
    END LOOP;
  ELSIF TG_OP = 'DELETE' THEN
    v_before := to_jsonb(OLD);
    v_row_id := COALESCE(v_before->>'id', '');
  END IF;

  INSERT INTO public.security_audit_log (
    actor_id, actor_email, table_name, operation, row_id, changed_fields, before, after
  ) VALUES (
    v_actor, v_email, TG_TABLE_NAME, TG_OP, v_row_id, v_changed, v_before, v_after
  );

  RETURN COALESCE(NEW, OLD);
END;
$$;


-- Trigger específica para users: só registra quando campos PRIVILEGIADOS mudam
CREATE OR REPLACE FUNCTION public.tg_audit_users_privileged()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_actor uuid := auth.uid();
  v_email text;
  v_changed text[] := ARRAY[]::text[];
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Auditar todo INSERT em users (criação de conta)
    NULL;
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.profile_type IS DISTINCT FROM OLD.profile_type THEN v_changed := v_changed || 'profile_type'; END IF;
    IF COALESCE(NEW.is_admin,false) IS DISTINCT FROM COALESCE(OLD.is_admin,false) THEN v_changed := v_changed || 'is_admin'; END IF;
    IF COALESCE(NEW.is_active,true) IS DISTINCT FROM COALESCE(OLD.is_active,true) THEN v_changed := v_changed || 'is_active'; END IF;
    IF COALESCE(NEW.is_deleted,false) IS DISTINCT FROM COALESCE(OLD.is_deleted,false) THEN v_changed := v_changed || 'is_deleted'; END IF;
    IF NEW.email IS DISTINCT FROM OLD.email THEN v_changed := v_changed || 'email'; END IF;
    IF NEW.cpf IS DISTINCT FROM OLD.cpf THEN v_changed := v_changed || 'cpf'; END IF;
    IF cardinality(v_changed) = 0 THEN
      RETURN NEW;  -- mudança não-privilegiada, não auditar
    END IF;
  END IF;

  IF v_actor IS NOT NULL THEN
    SELECT email INTO v_email FROM auth.users WHERE id = v_actor;
  END IF;

  INSERT INTO public.security_audit_log (
    actor_id, actor_email, table_name, operation, row_id, changed_fields, before, after
  ) VALUES (
    v_actor, v_email, 'users', TG_OP,
    COALESCE(NEW.id, OLD.id)::text,
    v_changed,
    CASE WHEN TG_OP = 'INSERT' THEN NULL ELSE to_jsonb(OLD) END,
    CASE WHEN TG_OP = 'DELETE' THEN NULL ELSE to_jsonb(NEW) END
  );

  RETURN COALESCE(NEW, OLD);
END;
$$;


DROP TRIGGER IF EXISTS audit_users_privileged ON public.users;
CREATE TRIGGER audit_users_privileged
  AFTER INSERT OR UPDATE OR DELETE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.tg_audit_users_privileged();

DROP TRIGGER IF EXISTS audit_financial_writes ON public.financial;
CREATE TRIGGER audit_financial_writes
  AFTER INSERT OR UPDATE OR DELETE ON public.financial
  FOR EACH ROW EXECUTE FUNCTION public.tg_audit_write();

DROP TRIGGER IF EXISTS audit_financing_rates_writes ON public.financing_rates;
CREATE TRIGGER audit_financing_rates_writes
  AFTER INSERT OR UPDATE OR DELETE ON public.financing_rates
  FOR EACH ROW EXECUTE FUNCTION public.tg_audit_write();

DROP TRIGGER IF EXISTS audit_sales_writes ON public.sales;
CREATE TRIGGER audit_sales_writes
  AFTER INSERT OR UPDATE OR DELETE ON public.sales
  FOR EACH ROW EXECUTE FUNCTION public.tg_audit_write();

DROP TRIGGER IF EXISTS audit_company_writes ON public.company;
CREATE TRIGGER audit_company_writes
  AFTER INSERT OR UPDATE OR DELETE ON public.company
  FOR EACH ROW EXECUTE FUNCTION public.tg_audit_write();

COMMENT ON TABLE public.security_audit_log IS
  'Append-only audit trail. Read=Admin Master only. Write via SECURITY DEFINER triggers.';
