-- Cancelamento de contrato (2026-07-20)
--
-- Contrato NÃO é excluído: é cancelado, e o cancelamento é um registro — com
-- motivo, autor e data. O contrato continua na listagem com o selo "Cancelado",
-- justamente para poder ser consultado e auditado depois.
--
-- Por que as colunas vão em `contract` e não em `proposal`: quem é cancelado é
-- o contrato. A `vw_contract_data` é construída sobre `proposal` (o `id` dela é
-- o id da proposta, e é assim que o painel navega), então a view passa a fazer
-- LEFT JOIN em `contract` para expor os campos novos sem mudar o contrato de
-- interface das telas.
--
-- Motivos são um conjunto fechado (CHECK) em vez de texto livre: assim dá para
-- medir por que os contratos caem. A observação livre fica em coluna separada.
--
-- Permissão: a policy `contract_write_seller` (ALL / auth_is_seller_or_admin)
-- já cobre o UPDATE. O painel restringe adicionalmente a quem tem
-- AccessControl.canEditFunil (Admin Master + documentação).

alter table public.contract
  add column if not exists cancelled_at        timestamptz,
  add column if not exists cancelled_by        uuid references public.users(id),
  add column if not exists cancellation_reason text,
  add column if not exists cancellation_note   text;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'contract_cancellation_reason_chk'
  ) then
    alter table public.contract
      add constraint contract_cancellation_reason_chk
      check (
        cancellation_reason is null
        or cancellation_reason in (
          'desistencia_cliente',
          'reprovacao_credito',
          'problema_aeronave',
          'condicoes_comerciais',
          'outro'
        )
      );
  end if;
end $$;

-- Coerência: ou está cancelado (com data E motivo), ou não está.
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'contract_cancellation_coerente_chk'
  ) then
    alter table public.contract
      add constraint contract_cancellation_coerente_chk
      check (
        (cancelled_at is null and cancellation_reason is null)
        or (cancelled_at is not null and cancellation_reason is not null)
      );
  end if;
end $$;

comment on column public.contract.cancelled_at is
  'Quando o contrato foi cancelado. NULL = contrato ativo.';
comment on column public.contract.cancellation_reason is
  'Motivo fechado do cancelamento — ver contract_cancellation_reason_chk.';
comment on column public.contract.cancellation_note is
  'Observação livre que acompanha o motivo (opcional).';

-- View: colunas novas APENAS acrescentadas no fim, para o `create or replace`
-- ser aceito (ele não permite remover/renomear/reordenar colunas existentes).
create or replace view public.vw_contract_data as
  SELECT p.id,
      p.id_ref,
      p.lead_id,
      p.aircraft_id,
      p.fullprice,
      p.created_at,
      p.created_by,
      p.is_contract,
      a.aircraft_model,
      COALESCE(c.company_name, 'Não cadastrado'::text) AS company_name,
      COALESCE(u.name, 'Não cadastrado'::text) AS created_by_name,
      ct.id                  AS contract_id,
      ct.cancelled_at        AS cancelled_at,
      ct.cancellation_reason AS cancellation_reason,
      ct.cancellation_note   AS cancellation_note,
      cu.name                AS cancelled_by_name
     FROM proposal p
       JOIN aircrafts a ON a.id = p.aircraft_id
       LEFT JOIN company c ON c.lead_id = p.lead_id
       LEFT JOIN users u ON u.id = p.created_by
       LEFT JOIN contract ct ON ct.proposal_id = p.id
       LEFT JOIN users cu ON cu.id = ct.cancelled_by
    WHERE p.active = true AND p.is_deleted = false AND p.is_contract = true
    ORDER BY p.created_at DESC;

-- Reafirma o security_invoker (endurecimento de 2026-06-22). O `create or
-- replace` preserva reloptions, mas deixar explícito evita que uma edição
-- futura da view reabra o buraco sem ninguém perceber.
alter view public.vw_contract_data set (security_invoker = on);
