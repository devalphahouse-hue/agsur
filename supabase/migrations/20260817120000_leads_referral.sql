-- Indicação de venda no lead (2026-08-17)
--
-- Pedido do dono: marcar que uma venda veio de indicação de terceiro e
-- registrar quem indicou (nome, telefone, e-mail) e quanto foi acordado com
-- essa pessoa. A marcação muda a comissão do vendedor na conversão:
-- US$ 7.500,00 numa venda direta, US$ 4.500,00 quando é indicação (a régua
-- inteira vive em `lib/backend/commission.dart`).
--
-- POR QUE NO LEAD, e não no cliente. O pedido original foi "incluir no
-- cadastro do cliente". Só que o cliente nasce DENTRO da conversão
-- proposta→contrato, na mesma transação lógica em que `sales` é inserida com
-- a comissão já calculada — marcar depois exigiria recalcular e reescrever
-- uma venda existente. No lead o dado nasce junto com o contato, viaja pela
-- proposta e chega na conversão a tempo da comissão sair certa de primeira.
-- Decisão confirmada com o dono em 17/08.
--
-- Escopo deliberado: só captura + efeito na comissão. O card INDICAÇÃO (perda
-- agregada paga a terceiros) ficou explicitamente para depois — por isso
-- `referral_agreed_value` já é gravado agora, mesmo sem nada lê-lo ainda: sem
-- ele, o card futuro nasceria sem histórico.
--
-- Permissão: nada novo. São colunas de `leads`, que já é escrita pelo funil
-- (policies de lead + trigger `hardening_require_funil`). Colunas novas
-- herdam a RLS da tabela; não há policy por coluna aqui.
--
-- ROLLBACK:
--   alter table public.leads
--     drop column if exists is_referral,
--     drop column if exists referral_name,
--     drop column if exists referral_phone,
--     drop column if exists referral_email,
--     drop column if exists referral_agreed_value;
--
-- VALIDAR depois de aplicar:
--   1. Cadastrar lead SEM marcar indicação -> is_referral = false, demais NULL.
--   2. Cadastrar lead COM indicação -> os 4 campos preenchidos.
--   3. Converter uma proposta de lead indicado -> sales.seller_commission = 4500.
--   4. Converter uma proposta de lead direto  -> sales.seller_commission = 7500.
--   5. Vendas anteriores a esta data seguem com a régua velha (25%/5%): nada
--      foi reprocessado, por decisão do dono.

alter table public.leads
  add column if not exists is_referral boolean not null default false,
  add column if not exists referral_name text,
  add column if not exists referral_phone text,
  add column if not exists referral_email text,
  add column if not exists referral_agreed_value numeric(14, 2);

comment on column public.leads.is_referral is
  'Venda veio de indicação de terceiro. Lido na conversão para decidir a '
  'comissão do vendedor (7500 direta / 4500 indicação) — ver '
  'lib/backend/commission.dart.';

comment on column public.leads.referral_agreed_value is
  'Valor acordado com quem indicou, em dólar. Ainda não é lido por nenhuma '
  'tela: existe para alimentar o card INDICAÇÃO quando ele for construído.';

-- Coerência: ou não é indicação e não há dados de indicador, ou é indicação e
-- pelo menos o nome de quem indicou está preenchido. Sem isto o `is_referral`
-- vira um booleano solto e o card futuro soma linhas órfãs.
-- NOT VALID: aplica só a linhas novas/alteradas, sem quebrar o push por causa
-- de lead legado (todos nascem com is_referral=false, então na prática não há
-- linha violando — mas o NOT VALID mantém o deploy seguro se houver).
alter table public.leads
  drop constraint if exists leads_referral_coerente;

alter table public.leads
  add constraint leads_referral_coerente check (
    is_referral = false
    or (referral_name is not null and length(btrim(referral_name)) > 0)
  ) not valid;
