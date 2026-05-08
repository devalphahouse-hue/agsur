-- ============================================================================
-- Fix: tg_audit_users_privileged usava `v_changed || 'string'` que ambíguo
-- entre concat de array e concat de string. Trocar por array_append explícito.
-- ============================================================================

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
    NULL;
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.profile_type IS DISTINCT FROM OLD.profile_type THEN
      v_changed := array_append(v_changed, 'profile_type');
    END IF;
    IF COALESCE(NEW.is_admin,false) IS DISTINCT FROM COALESCE(OLD.is_admin,false) THEN
      v_changed := array_append(v_changed, 'is_admin');
    END IF;
    IF COALESCE(NEW.is_active,true) IS DISTINCT FROM COALESCE(OLD.is_active,true) THEN
      v_changed := array_append(v_changed, 'is_active');
    END IF;
    IF COALESCE(NEW.is_deleted,false) IS DISTINCT FROM COALESCE(OLD.is_deleted,false) THEN
      v_changed := array_append(v_changed, 'is_deleted');
    END IF;
    IF NEW.email IS DISTINCT FROM OLD.email THEN
      v_changed := array_append(v_changed, 'email');
    END IF;
    IF NEW.cpf IS DISTINCT FROM OLD.cpf THEN
      v_changed := array_append(v_changed, 'cpf');
    END IF;
    IF cardinality(v_changed) = 0 THEN
      RETURN NEW;
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
