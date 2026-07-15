-- ============================================================================
-- RBAC do painel — enforcement por nível nos triggers (Fase 7, parte 2)
--
-- ⚠️ NÃO APLICAR DIRETO EM PRODUÇÃO SEM rls-smoke.
-- Esta migration APERTA os triggers de write para respeitar os sub-níveis de
-- Admin (recepção x documentação). Depende dos helpers de
-- 20260701170500_rbac_level_helpers.sql (já aplicados).
--
-- Por que validar antes: os dois apps compartilham o backend. Estas tabelas
-- JÁ eram admin/seller-only (Cliente/Piloto/Oficina nunca escreveram nelas),
-- então o app cliente não é afetado. Mas há uma sutileza no funil↔tracking
-- (abaixo) que precisa ser testada com o fluxo real de conversão do Vendedor.
--
-- Mapa de write por tabela (SELECT continua permissivo p/ autenticados —
-- segregação de leitura por nível é um passo posterior):
--   DOCUMENTAÇÃO (master + documentacao):
--     financing_rates, aircrafts, aircraft_items, available_aircrafts, category
--   FUNIL (master + documentacao + vendedor):
--     leads, proposal, proposal_item, proposal_financing,
--     contract, contract_terms, sales, financial
--   tracking / tracking_details:
--     INSERT  → FUNIL   (a conversão proposta→contrato, feita pelo Vendedor,
--                        cria as 21 etapas — não pode bloquear o Vendedor aqui)
--     UPDATE/DELETE → DOCUMENTAÇÃO (marcar/editar etapa; Vendedor é view-only)
--   ANY-ADMIN (recepção + documentacao, sem vendedor):
--     services_offering (carta de serviços — vista pelos dois níveis)
--
-- NÃO tocadas (envolvem fluxos de Cliente/Piloto/Oficina no app cliente —
-- apertar aqui exige mapear os writes do app cliente + rls-smoke):
--   guarantee, certificates, service_letter, order_parts, requested_parts,
--   pilots/pilot_clients, oficina/oficina_clients, user_aircraft, company,
--   users, address, notes
-- ============================================================================

-- ── Trigger genérica: só DOCUMENTAÇÃO (ou master/service_role) ──────────────
CREATE OR REPLACE FUNCTION public.tg_require_documentacao()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF public.auth_is_service_role() THEN RETURN COALESCE(NEW, OLD); END IF;
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
$$;

-- ── Trigger genérica: FUNIL (documentacao + vendedor + master/service_role) ──
CREATE OR REPLACE FUNCTION public.tg_require_funil()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF public.auth_is_service_role() THEN RETURN COALESCE(NEW, OLD); END IF;
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
$$;

-- =========================== DOCUMENTAÇÃO ===========================
DO $$
DECLARE t text;
  tables text[] := ARRAY['financing_rates','aircrafts','aircraft_items','available_aircrafts','category'];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS hardening_require_admin ON public.%I', t);
    EXECUTE format('DROP TRIGGER IF EXISTS hardening_require_seller_or_admin ON public.%I', t);
    EXECUTE format('DROP TRIGGER IF EXISTS hardening_require_documentacao ON public.%I', t);
    EXECUTE format(
      'CREATE TRIGGER hardening_require_documentacao
         BEFORE INSERT OR UPDATE OR DELETE ON public.%I
         FOR EACH ROW EXECUTE FUNCTION public.tg_require_documentacao()', t);
  END LOOP;
END; $$;

-- =========================== FUNIL ===========================
DO $$
DECLARE t text;
  tables text[] := ARRAY['leads','proposal','proposal_item','proposal_financing',
                         'contract','contract_terms','sales','financial'];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS hardening_require_admin ON public.%I', t);
    EXECUTE format('DROP TRIGGER IF EXISTS hardening_require_seller_or_admin ON public.%I', t);
    EXECUTE format('DROP TRIGGER IF EXISTS hardening_require_funil ON public.%I', t);
    EXECUTE format(
      'CREATE TRIGGER hardening_require_funil
         BEFORE INSERT OR UPDATE OR DELETE ON public.%I
         FOR EACH ROW EXECUTE FUNCTION public.tg_require_funil()', t);
  END LOOP;
END; $$;

-- =========================== TRACKING (INSERT=funil, UPDATE/DELETE=doc) ======
DO $$
DECLARE t text;
  tables text[] := ARRAY['tracking','tracking_details'];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS hardening_require_seller_or_admin ON public.%I', t);
    EXECUTE format('DROP TRIGGER IF EXISTS hardening_require_admin ON public.%I', t);
    EXECUTE format('DROP TRIGGER IF EXISTS hardening_tracking_insert ON public.%I', t);
    EXECUTE format('DROP TRIGGER IF EXISTS hardening_tracking_mutate ON public.%I', t);
    EXECUTE format(
      'CREATE TRIGGER hardening_tracking_insert
         BEFORE INSERT ON public.%I
         FOR EACH ROW EXECUTE FUNCTION public.tg_require_funil()', t);
    EXECUTE format(
      'CREATE TRIGGER hardening_tracking_mutate
         BEFORE UPDATE OR DELETE ON public.%I
         FOR EACH ROW EXECUTE FUNCTION public.tg_require_documentacao()', t);
  END LOOP;
END; $$;

-- =========================== ANY-ADMIN (sem vendedor) ===========================
-- services_offering: carta de serviços — recepção + documentacao, mas não vendedor.
DROP TRIGGER IF EXISTS hardening_require_seller_or_admin ON public.services_offering;
DROP TRIGGER IF EXISTS hardening_require_admin ON public.services_offering;
CREATE TRIGGER hardening_require_admin
  BEFORE INSERT OR UPDATE OR DELETE ON public.services_offering
  FOR EACH ROW EXECUTE FUNCTION public.tg_require_admin();

-- ============================================================================
-- CHECKLIST antes de aplicar em produção:
--   [ ] rls-smoke passa (gh workflow run rls-smoke.yml)
--   [ ] Vendedor: converte proposta → cria contrato + 21 etapas de tracking (INSERT ok)
--   [ ] Vendedor: NÃO consegue marcar etapa de tracking (UPDATE bloqueado)
--   [ ] Documentacao: cria/edita leads/propostas/contratos/aeronaves/taxas/tracking
--   [ ] Recepção: bloqueado em leads/propostas/aeronaves/tracking; ok em carta de serviços
--   [ ] App cliente (Piloto/Oficina): sem regressão (tabelas acima não são escritas por eles)
-- ============================================================================
