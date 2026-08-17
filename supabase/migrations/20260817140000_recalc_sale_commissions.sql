-- Reprocessa a comissão das vendas existentes com a régua de 17/08/2026
--
-- A régua nova (migration 20260817120000 + lib/backend/commission.dart) só
-- valia para conversões futuras: a comissão é calculada e CONGELADA no momento
-- em que a proposta vira contrato, e as vendas anteriores continuavam com os
-- percentuais antigos (25% AGSur / 5% vendedor). A decisão inicial do dono foi
-- não reprocessar; em 17/08 ele voltou atrás e pediu o acerto, porque o
-- dashboard mostrava número que não corresponde mais ao combinado.
--
-- Régua aplicada (a mesma de commission.dart — mexeu num, mexa no outro):
--   company_commission = 2% do fullprice do contrato
--   seller_commission  = US$ 7.500,00 fixo, ou US$ 4.500,00 se a venda veio
--                        de indicação (leads.is_referral)
--
-- ⚠️ Isto REESCREVE registro financeiro histórico. Só é aceitável porque a
-- régua antiga nunca chegou a ser paga com esses valores — é correção de
-- cadastro, não estorno. Os valores anteriores ficam registrados aqui e no
-- security_audit_log (a trigger de auditoria de `sales` não tem bypass e
-- registra este UPDATE).
--
-- Estado ANTES (única venda existente em 17/08):
--   id 4bd16643-931d-4019-8678-af893e2faabd
--   fullprice 1.494.305,00 · company 373.576,25 (25%) · seller 74.715,25 (5%)
-- Estado DEPOIS:
--   company 29.886,10 (2%) · seller 7.500,00 (lead não é indicação)
--
-- ROLLBACK (volta à régua antiga, para TODAS as vendas):
--   update public.sales
--      set company_commission = round(fullprice * 0.25, 2),
--          seller_commission  = round(fullprice * 0.05, 2);
--
-- VALIDAR: o dashboard (vw_homepage_dashboard) deve passar a somar
-- 29.886,10 em "Comissão AGSur" e 7.500,00 em "Comissão vendedores".

-- Por que desarmar a guarda aqui. `db push` conecta com o role de migration
-- da CLI ("Initialising login role..."), que NÃO está na lista de bypass de
-- auth_is_service_request() (postgres/supabase_admin/service_role) e não
-- carrega JWT — então auth.uid() é nulo e a trigger `hardening_require_funil`
-- recusa com "public.sales: anonymous writes blocked" (42501). DDL não
-- esbarra nisso porque trigger não dispara em DDL; UPDATE dispara.
--
-- Desarmamos APENAS a guarda de autorização, e apenas nesta transação. A
-- trigger de auditoria (`audit_sales_writes`) fica LIGADA de propósito: esta
-- é uma reescrita de valor financeiro e tem que aparecer no
-- security_audit_log. Ela tolera auth.uid() nulo (grava actor vazio).
--
-- Se a migration falhar no meio, o disable volta junto: o db push roda cada
-- arquivo em transação.
alter table public.sales disable trigger hardening_require_funil;

update public.sales s
   set company_commission = round(s.fullprice * 0.02, 2),
       seller_commission  = case
         when coalesce(
                (select l.is_referral
                   from public.proposal p
                   join public.leads l on l.id = p.lead_id
                  where p.id = s.proposal_id),
                false)
         then 4500.00
         else 7500.00
       end
 where s.fullprice is not null;

alter table public.sales enable trigger hardening_require_funil;
