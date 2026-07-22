-- Vínculo contrato ↔ unidade física do estoque (2026-07-22)
--
-- Pedido do cliente (vídeo de 2026-07-21): depois de cadastrar as unidades
-- físicas em `available_aircrafts` (estoque), vincular a unidade vendida ao
-- cliente — "o legal seria vincular no contrato: abre uma lista de aeronaves
-- e coloca pra ele". O vínculo mora no CONTRATO (é onde a venda se
-- materializa); o cliente é alcançado por `contract."user_Id"`.
--
-- Por que uma coluna em `contract` e não em `available_aircrafts`: a tela e o
-- fluxo partem do contrato ("colocar a aeronave pra ele"), o contrato já
-- carrega o cliente, e a unidade continua sendo gerida pelo estoque sem saber
-- de venda — o status dela ("Vendido" etc.) segue manual, como o cliente opera
-- hoje.
--
-- Integridade:
--   * ON DELETE SET NULL — excluir a unidade do estoque desfaz o vínculo em
--     vez de bloquear a exclusão ou derrubar o contrato.
--   * Índice único parcial — uma unidade física só pode estar em UM contrato
--     ATIVO por vez; contrato cancelado (cancelled_at, migration 20260720120000)
--     libera a unidade para revenda. Tentativa de duplo vínculo devolve 23505
--     e o painel traduz para mensagem amigável.
--
-- Permissão: nada novo. O UPDATE em `contract` já é guardado pela policy
-- `contract_write_seller` (auth_is_seller_or_admin) + trigger de nível
-- `hardening_require_funil` (Admin Master/documentação). SELECT de
-- `available_aircrafts` já é liberado a authenticated (catálogo interno).

alter table public.contract
  add column if not exists available_aircraft_id uuid
    references public.available_aircrafts(id) on delete set null;

comment on column public.contract.available_aircraft_id is
  'Unidade física do estoque (available_aircrafts) entregue neste contrato. '
  'NULL = ainda não vinculada. Única por contrato ativo '
  '(uq_contract_available_aircraft_active).';

-- Uma unidade só pode estar vinculada a um contrato ativo por vez.
create unique index if not exists uq_contract_available_aircraft_active
  on public.contract (available_aircraft_id)
  where available_aircraft_id is not null and cancelled_at is null;

-- Lookup reverso (ex.: "esta unidade está em qual contrato?") e o filtro de
-- unidades já vinculadas no seletor do painel.
create index if not exists idx_contract_available_aircraft_id
  on public.contract (available_aircraft_id)
  where available_aircraft_id is not null;
