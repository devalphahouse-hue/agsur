-- ============================================================================
-- Fix 2026-07-15 — triggers de guarda eram NO-OP dentro de SECURITY DEFINER.
-- ============================================================================
-- Bug: as funções de trigger de guarda são SECURITY DEFINER (dono: postgres).
-- Dentro de função SECURITY DEFINER, current_user é o DONO da função — então o
-- curto-circuito public.auth_is_service_role() (que checa current_user IN
-- ('postgres','supabase_admin','service_role')) retornava TRUE para QUALQUER
-- chamador, e as triggers liberavam tudo sem checar perfil. Efeito: a "defesa
-- em camadas" (batch 2026-05-08) e o enforcement da Fase 7 (20260701171000)
-- nunca bloquearam nada; a RLS era a única camada real. Descoberto em
-- 2026-07-15 validando a Fase 7 por personificação.
--
-- Correção: novo helper auth_is_service_request() usando session_user — que
-- NÃO muda em contexto SECURITY DEFINER. Semântica:
--   - request PostgREST de usuário (anon/authenticated): session_user =
--     'authenticator' e claims sem service_role → SEM bypass (enforcement vale);
--   - service key via PostgREST: claims role='service_role' → bypass;
--   - conexão administrativa direta (psql/CLI/Management API): session_user =
--     postgres/supabase_admin → bypass (migrations e operação seguem ok);
--   - RPC SECURITY DEFINER chamada por usuário: SEM bypass — a trigger avalia
--     o perfil do usuário chamador via auth.uid() (comportamento desejado).
--
-- Escopo (corpo idêntico ao de produção, só a 1ª checagem muda):
--   tg_require_admin, tg_require_seller_or_admin, tg_require_documentacao,
--   tg_require_funil, tg_block_edit_when_soft_deleted.
--
-- FORA do escopo (mantêm o bypass antigo = continuam neutralizadas; RLS segue
-- sendo o guarda real; armar exige reconciliar as regras com os fluxos do
-- painel antes — vendedor cria cliente na conversão, recepção cadastra
-- piloto/oficina):
--   tg_users_block_privilege_escalation, tg_address_ownership,
--   tg_guarantee_ownership, tg_order_parts_ownership,
--   tg_pilot_certificates_ownership, tg_requested_parts_ownership.
--   tg_require_service_role (gate do security_audit_log) fica como está DE
--   PROPÓSITO: os inserts de audit vêm de funções definer e dependem do
--   bypass por current_user.
--   tg_audit_write / tg_audit_users_privileged não têm o bug (sem bypass).
--
-- Validação pós-aplicação: signup de cliente de teste via anon key + tentativa
-- de INSERT em aircrafts/leads via PostgREST → 42501 com a mensagem da trigger
-- ('requires ...'), + rls-smoke + fluxos reais do painel (master/documentação/
-- vendedor). Rollback: recriar as 5 funções trocando auth_is_service_request()
-- de volta por auth_is_service_role().
-- ============================================================================

CREATE OR REPLACE FUNCTION public.auth_is_service_request()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT current_setting('request.jwt.claims', true)::jsonb->>'role' = 'service_role'
      OR session_user IN ('postgres', 'supabase_admin', 'service_role');
$$;

COMMENT ON FUNCTION public.auth_is_service_request() IS
  'True para request de service_role ou conexão administrativa direta (session_user). Ao contrário de auth_is_service_role(), NÃO retorna true só por rodar dentro de função SECURITY DEFINER — use este em triggers de guarda.';

GRANT EXECUTE ON FUNCTION public.auth_is_service_request() TO authenticated, anon, service_role;

-- ── tg_require_admin (corpo de produção; só a checagem de bypass mudou) ──
CREATE OR REPLACE FUNCTION public.tg_require_admin()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF public.auth_is_service_request() THEN
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
$function$;

-- ── tg_require_seller_or_admin (corpo de produção; só a checagem de bypass mudou) ──
CREATE OR REPLACE FUNCTION public.tg_require_seller_or_admin()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF public.auth_is_service_request() THEN
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
$function$;

-- ── tg_require_documentacao (corpo de produção; só a checagem de bypass mudou) ──
CREATE OR REPLACE FUNCTION public.tg_require_documentacao()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF public.auth_is_service_request() THEN RETURN COALESCE(NEW, OLD); END IF;
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION '%.%: anonymous writes blocked', TG_TABLE_SCHEMA, TG_TABLE_NAME
      USING ERRCODE = '42501';
  END IF;
  IF NOT public.auth_is_admin_documentacao() THEN
    RAISE EXCEPTION '%.%: requires Admin documentacao / Admin Master', TG_TABLE_SCHEMA, TG_TABLE_NAME
      USING ERRCODE = '42501';
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$function$;

-- ── tg_require_funil (corpo de produção; só a checagem de bypass mudou) ──
CREATE OR REPLACE FUNCTION public.tg_require_funil()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF public.auth_is_service_request() THEN RETURN COALESCE(NEW, OLD); END IF;
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION '%.%: anonymous writes blocked', TG_TABLE_SCHEMA, TG_TABLE_NAME
      USING ERRCODE = '42501';
  END IF;
  IF NOT (public.auth_is_admin_documentacao() OR public.auth_is_vendedor()) THEN
    RAISE EXCEPTION '%.%: requires funil access (documentacao/vendedor/master)', TG_TABLE_SCHEMA, TG_TABLE_NAME
      USING ERRCODE = '42501';
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$function$;

-- ── tg_block_edit_when_soft_deleted (corpo de produção; só a checagem de bypass mudou) ──
CREATE OR REPLACE FUNCTION public.tg_block_edit_when_soft_deleted()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF public.auth_is_service_request() THEN RETURN NEW; END IF;
  IF public.auth_is_admin_master() THEN RETURN NEW; END IF;

  -- Caller comum: se o registro jÃ¡ estava marcado como deletado, bloqueia.
  IF COALESCE(OLD.is_deleted, false) = true THEN
    RAISE EXCEPTION '%.%: cannot edit a soft-deleted row (only Admin Master)',
      TG_TABLE_SCHEMA, TG_TABLE_NAME
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$function$;

