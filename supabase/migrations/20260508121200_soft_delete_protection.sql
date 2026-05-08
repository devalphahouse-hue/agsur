-- ============================================================================
-- Soft-delete protection
--
-- Bloqueia UPDATE em registros já marcados is_deleted=true (exceto Admin Master
-- ou service_role). Evita "ressurreição via edit" — alguém com permissão de
-- escrita normal não consegue alterar dados de um registro logicamente
-- deletado, nem reverter is_deleted para false.
--
-- Tabelas alvo (todas com coluna is_deleted): certificates, leads,
-- pilot_certificates, proposal, service_letter, services_offering, users.
-- (users já tem trigger própria; aplicamos somente nas demais.)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.tg_block_edit_when_soft_deleted()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF public.auth_is_service_role() THEN RETURN NEW; END IF;
  IF public.auth_is_admin_master() THEN RETURN NEW; END IF;

  -- Caller comum: se o registro já estava marcado como deletado, bloqueia.
  IF COALESCE(OLD.is_deleted, false) = true THEN
    RAISE EXCEPTION '%.%: cannot edit a soft-deleted row (only Admin Master)',
      TG_TABLE_SCHEMA, TG_TABLE_NAME
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$$;

DO $$
DECLARE
  t text;
  tables text[] := ARRAY[
    'certificates', 'leads', 'pilot_certificates',
    'proposal', 'service_letter', 'services_offering'
  ];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS hardening_block_soft_deleted_edit ON public.%I',
      t
    );
    EXECUTE format(
      'CREATE TRIGGER hardening_block_soft_deleted_edit
         BEFORE UPDATE ON public.%I
         FOR EACH ROW EXECUTE FUNCTION public.tg_block_edit_when_soft_deleted()',
      t
    );
  END LOOP;
END;
$$;
