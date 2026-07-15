-- ============================================================================
-- Corrige write de `company`: Admin Master-only → escopo do FUNIL
-- ============================================================================
-- BUG (relatado em 2026-07-14): um colaborador Admin/documentacao não conseguia
-- salvar "Dados Empresariais" ao criar/editar uma proposta. O Vendedor tinha o
-- mesmo problema. Nunca apareceu antes porque todos os usuários ativos são
-- Admin Master.
--
-- Causa — duas camadas, herdadas do endurecimento de 2026-05-08:
--   1. RLS: company_{write,update,delete}_admin_master exigem auth_is_admin_master().
--      Num UPDATE, a RLS não levanta erro — filtra 0 linhas. O PostgREST devolve
--      sucesso e o painel acha que salvou (falha SILENCIOSA).
--   2. Trigger: hardening_require_admin → tg_require_admin() exige auth_is_admin(),
--      o que barra o Vendedor com 42501 (falha ruidosa, mas não tratada na UI).
--
-- Por que estava errado: `public.company` NÃO é o cadastro institucional da
-- Agsur — é a empresa DO LEAD (tem lead_id, cnpj, cpf, phone) e é escrita
-- durante o funil de vendas, por quem cria proposta. A policy de 2026-05-08 foi
-- escrita como se fosse cadastro institucional. A migration de 2026-06-22
-- (company_select_restrict) corrigiu o SELECT e não tocou no write.
--
-- Escopo novo (decisão do dono, 2026-07-14): FUNIL = Admin Master + Admin
-- documentacao + Vendedor. Recepção fica de fora (não enxerga o funil).
-- Alinha `company` com leads/proposal/contract.
--
-- Dependência: helpers auth_is_admin_documentacao() / auth_is_vendedor()
-- (20260701170500_rbac_level_helpers.sql) — verificados como JÁ APLICADOS em
-- produção em 2026-07-14.
--
-- tg_require_funil() é definida aqui porque 20260701171000_rbac_level_enforcement.sql
-- (que também a define, de forma idêntica) ainda NÃO foi aplicada. O CREATE OR
-- REPLACE de lá vira no-op semântico quando a Fase 7 entrar.
--
-- NÃO afeta o app cliente: Cliente/Piloto/Oficina nunca escrevem em company e o
-- SELECT (company_seller_or_admin_select) fica intocado.
-- ============================================================================

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

COMMENT ON FUNCTION public.tg_require_funil() IS
  'Trigger BEFORE: exige acesso ao funil (Admin Master, Admin documentacao ou Vendedor). SECURITY DEFINER.';

-- ── 1) Trigger de company: require_admin → require_funil ────────────────────
DROP TRIGGER IF EXISTS hardening_require_admin ON public.company;
DROP TRIGGER IF EXISTS hardening_require_seller_or_admin ON public.company;
DROP TRIGGER IF EXISTS hardening_require_funil ON public.company;
CREATE TRIGGER hardening_require_funil
  BEFORE INSERT OR UPDATE OR DELETE ON public.company
  FOR EACH ROW EXECUTE FUNCTION public.tg_require_funil();

-- ── 2) Policies de write: admin_master → funil ──────────────────────────────
-- INSERT
DROP POLICY IF EXISTS company_write_admin_master ON public.company;
DROP POLICY IF EXISTS company_write_funil ON public.company;
CREATE POLICY company_write_funil
  ON public.company
  FOR INSERT
  TO authenticated
  WITH CHECK (public.auth_is_admin_documentacao() OR public.auth_is_vendedor());

-- UPDATE
DROP POLICY IF EXISTS company_update_admin_master ON public.company;
DROP POLICY IF EXISTS company_update_funil ON public.company;
CREATE POLICY company_update_funil
  ON public.company
  FOR UPDATE
  TO authenticated
  USING (public.auth_is_admin_documentacao() OR public.auth_is_vendedor())
  WITH CHECK (public.auth_is_admin_documentacao() OR public.auth_is_vendedor());

-- DELETE
DROP POLICY IF EXISTS company_delete_admin_master ON public.company;
DROP POLICY IF EXISTS company_delete_funil ON public.company;
CREATE POLICY company_delete_funil
  ON public.company
  FOR DELETE
  TO authenticated
  USING (public.auth_is_admin_documentacao() OR public.auth_is_vendedor());

-- SELECT (company_seller_or_admin_select) e o audit trigger (audit_company_writes)
-- ficam INTOCADOS de propósito.

-- ============================================================================
-- ROLLBACK (volta ao comportamento Admin Master-only de 2026-05-08):
--   drop trigger if exists hardening_require_funil on public.company;
--   create trigger hardening_require_admin
--     before insert or update or delete on public.company
--     for each row execute function public.tg_require_admin();
--   drop policy if exists company_write_funil on public.company;
--   create policy company_write_admin_master on public.company
--     for insert to authenticated with check (public.auth_is_admin_master());
--   drop policy if exists company_update_funil on public.company;
--   create policy company_update_admin_master on public.company
--     for update to authenticated using (public.auth_is_admin_master())
--     with check (public.auth_is_admin_master());
--   drop policy if exists company_delete_funil on public.company;
--   create policy company_delete_admin_master on public.company
--     for delete to authenticated using (public.auth_is_admin_master());
-- (tg_require_funil() pode ficar — é inerte sem trigger que a use.)
-- ============================================================================

-- ============================================================================
-- CHECKLIST de validação:
--   [ ] Admin Master: cria/edita Dados Empresariais na proposta (sem regressão)
--   [ ] Admin documentacao: edita Dados Empresariais e o valor PERSISTE
--   [ ] Vendedor: cria proposta + edita Dados Empresariais (sem 42501)
--   [ ] Admin recepcao: bloqueado (não vê o funil no client-side de qualquer forma)
--   [ ] App cliente (Cliente/Piloto/Oficina): sem regressão (não escrevem company)
--   [ ] rls-smoke passa
-- ============================================================================
