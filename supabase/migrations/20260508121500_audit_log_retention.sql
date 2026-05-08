-- ============================================================================
-- Política de retenção do security_audit_log.
--
-- Cria função purge_security_audit_log(retention_days) que apaga linhas
-- mais velhas que N dias. Default: 365 dias.
--
-- Para AGENDAR a execução automática, opções:
--   1) Habilitar pg_cron (Studio → Database → Extensions → pg_cron)
--      Depois rodar como service_role:
--        SELECT cron.schedule('audit-purge-daily', '0 3 * * *',
--          $$SELECT public.purge_security_audit_log(365)$$);
--   2) Edge Function com cron Vercel/GitHub Actions chamando RPC.
--
-- A função é SECURITY DEFINER + restrita a service_role + Admin Master.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.purge_security_audit_log(retention_days int DEFAULT 365)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_deleted bigint;
BEGIN
  -- Só Admin Master ou service_role podem executar
  IF NOT (public.auth_is_service_role() OR public.auth_is_admin_master()) THEN
    RAISE EXCEPTION 'purge_security_audit_log: requires Admin Master or service_role'
      USING ERRCODE = '42501';
  END IF;

  IF retention_days < 30 THEN
    RAISE EXCEPTION 'purge_security_audit_log: retention_days must be >= 30 (got %)', retention_days
      USING ERRCODE = '22023';
  END IF;

  WITH deleted AS (
    DELETE FROM public.security_audit_log
    WHERE occurred_at < (now() - make_interval(days => retention_days))
    RETURNING 1
  )
  SELECT COUNT(*) INTO v_deleted FROM deleted;

  -- Auto-audita o purge no próprio audit_log (visibilidade)
  INSERT INTO public.security_audit_log (
    actor_id, actor_email, table_name, operation, row_id, changed_fields, before, after
  ) VALUES (
    auth.uid(), NULL, 'security_audit_log', 'PURGE', NULL,
    ARRAY['retention_days']::text[],
    NULL,
    jsonb_build_object('deleted_rows', v_deleted, 'retention_days', retention_days)
  );

  RETURN v_deleted;
END;
$$;

REVOKE ALL ON FUNCTION public.purge_security_audit_log(int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purge_security_audit_log(int) TO authenticated, service_role;

COMMENT ON FUNCTION public.purge_security_audit_log(int) IS
  'Apaga security_audit_log > N dias (default 365). Restrito a Admin Master / service_role. Auto-audita.';
