-- ============================================================================
-- Segurança 2026-06-22 — fecha leak de `company` (PII) para autenticado genérico.
-- ============================================================================
-- A policy `company_read_authenticated` tinha SELECT `true` → qualquer usuário
-- AUTENTICADO (inclusive Cliente/Piloto) podia listar TODAS as empresas
-- (company_name, cnpj/cpf, phone, email). Restringe a Vendedor/Admin.
--
-- Seguro: o app cliente não usa CompanyTable; as views do cliente
-- (vw_my_aircraft*) NÃO juntam company; vw_contract_data/vw_all_tracking são
-- views do painel (Admin/Vendedor passam por auth_is_seller_or_admin). Painel lê
-- company só como Admin/Vendedor.
-- ============================================================================

drop policy if exists company_read_authenticated on public.company;

create policy company_seller_or_admin_select on public.company
  for select to authenticated
  using (auth_is_seller_or_admin());
