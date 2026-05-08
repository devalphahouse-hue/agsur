-- ============================================================================
-- Defesa em camadas — public.users
--
-- Bloqueia escalation de privilégio mesmo se uma policy permissiva (all_access)
-- ainda existir. Triggers BEFORE rodam SEMPRE, independente de RLS.
--
-- Regras:
--   INSERT direto:
--     - service_role/postgres: livre
--     - resto: pode inserir só se NEW.id = auth.uid() E
--              profile_type ∈ ('Cliente','Piloto','Oficina') E
--              is_admin = false
--     (Admin/Vendedor/Admin Master só são criados pelo painel via REST do auth + atualização posterior por Admin Master.)
--
--   UPDATE:
--     - service_role/postgres: livre
--     - Admin Master: pode tudo
--     - Próprio user (auth.uid() = OLD.id): pode mudar campos pessoais
--       (name, lastname, fullname, profile_photo_url, phone, device_token, status)
--       NUNCA pode mudar: id, email, cpf, profile_type, is_admin, is_active, is_deleted, lead_id, job_title_admin
--     - Outros usuários: bloqueado
--
--   DELETE:
--     - service_role/postgres: livre
--     - Admin Master: livre
--     - Próprio user (auto-delete de conta): livre
--     - resto: bloqueado
-- ============================================================================

CREATE OR REPLACE FUNCTION public.tg_users_block_privilege_escalation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller_id uuid := auth.uid();
  is_master boolean := false;
  is_self boolean := false;
BEGIN
  -- bypass para service_role/postgres
  IF public.auth_is_service_role() THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  -- caller anônimo (sem JWT) não pode fazer NADA aqui
  IF caller_id IS NULL THEN
    RAISE EXCEPTION 'users: anonymous writes not allowed' USING ERRCODE = '42501';
  END IF;

  is_master := public.auth_is_admin_master();

  -- =========================== INSERT ===========================
  IF TG_OP = 'INSERT' THEN
    IF is_master THEN
      RETURN NEW;
    END IF;

    -- Self-insert (signup)
    IF NEW.id IS NULL OR NEW.id <> caller_id THEN
      RAISE EXCEPTION 'users.insert: only Admin Master can create rows for other users'
        USING ERRCODE = '42501';
    END IF;

    IF NEW.profile_type NOT IN (
      'Cliente'::profile_types,
      'Piloto'::profile_types,
      'Oficina'::profile_types
    ) THEN
      RAISE EXCEPTION 'users.insert: self-signup limited to Cliente/Piloto/Oficina'
        USING ERRCODE = '42501';
    END IF;

    IF COALESCE(NEW.is_admin, false) <> false THEN
      RAISE EXCEPTION 'users.insert: cannot self-assign is_admin'
        USING ERRCODE = '42501';
    END IF;

    RETURN NEW;
  END IF;

  -- =========================== UPDATE ===========================
  IF TG_OP = 'UPDATE' THEN
    IF is_master THEN
      RETURN NEW;
    END IF;

    is_self := (caller_id = OLD.id);

    IF NOT is_self THEN
      RAISE EXCEPTION 'users.update: only Admin Master can edit other users'
        USING ERRCODE = '42501';
    END IF;

    -- Campos imutáveis pelo próprio usuário
    IF NEW.id IS DISTINCT FROM OLD.id THEN
      RAISE EXCEPTION 'users.update: id is immutable' USING ERRCODE = '42501';
    END IF;

    IF NEW.email IS DISTINCT FROM OLD.email THEN
      RAISE EXCEPTION 'users.update: email change requires Admin Master' USING ERRCODE = '42501';
    END IF;

    IF NEW.cpf IS DISTINCT FROM OLD.cpf THEN
      RAISE EXCEPTION 'users.update: cpf change requires Admin Master' USING ERRCODE = '42501';
    END IF;

    IF NEW.profile_type IS DISTINCT FROM OLD.profile_type THEN
      RAISE EXCEPTION 'users.update: profile_type change requires Admin Master' USING ERRCODE = '42501';
    END IF;

    IF COALESCE(NEW.is_admin, false) IS DISTINCT FROM COALESCE(OLD.is_admin, false) THEN
      RAISE EXCEPTION 'users.update: is_admin change requires Admin Master' USING ERRCODE = '42501';
    END IF;

    IF COALESCE(NEW.is_active, true) IS DISTINCT FROM COALESCE(OLD.is_active, true) THEN
      RAISE EXCEPTION 'users.update: is_active change requires Admin Master' USING ERRCODE = '42501';
    END IF;

    IF COALESCE(NEW.is_deleted, false) IS DISTINCT FROM COALESCE(OLD.is_deleted, false) THEN
      RAISE EXCEPTION 'users.update: is_deleted change requires Admin Master' USING ERRCODE = '42501';
    END IF;

    IF NEW.lead_id IS DISTINCT FROM OLD.lead_id THEN
      RAISE EXCEPTION 'users.update: lead_id change requires Admin Master' USING ERRCODE = '42501';
    END IF;

    IF NEW.job_title_admin IS DISTINCT FROM OLD.job_title_admin THEN
      RAISE EXCEPTION 'users.update: job_title_admin change requires Admin Master' USING ERRCODE = '42501';
    END IF;

    -- Campos pessoais (name, lastname, fullname, profile_photo_url, phone, device_token, status, created_at)
    -- ficam liberados.
    RETURN NEW;
  END IF;

  -- =========================== DELETE ===========================
  IF TG_OP = 'DELETE' THEN
    IF is_master OR caller_id = OLD.id THEN
      RETURN OLD;
    END IF;
    RAISE EXCEPTION 'users.delete: only Admin Master or the user itself can delete'
      USING ERRCODE = '42501';
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

COMMENT ON FUNCTION public.tg_users_block_privilege_escalation() IS
  'Defesa em camadas: bloqueia escalation/edição não autorizada em public.users mesmo se policy permissiva existir.';

DROP TRIGGER IF EXISTS users_block_privilege_escalation ON public.users;
CREATE TRIGGER users_block_privilege_escalation
  BEFORE INSERT OR UPDATE OR DELETE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.tg_users_block_privilege_escalation();
