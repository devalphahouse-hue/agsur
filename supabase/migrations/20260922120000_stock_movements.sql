-- Estoque de aeronaves com movimentações + vínculo proposta/contrato (2026-09-22)
--
-- Pedido do cliente ("Gestão de Aeronaves em Estoque & Vínculo Contratual"):
-- estoque de verdade — entradas e saídas registradas, quantidade por modelo,
-- histórico que ninguém apaga —, destaque de modelos no catálogo e a unidade
-- escolhida já na proposta, saindo do estoque quando a proposta vira contrato.
--
-- Decisões de produto (usuário, 2026-09-22):
--   * Catálogo (`aircrafts`) = modelos vendidos; estoque (`available_aircrafts`)
--     = aviões físicos. Destaque é do MODELO (`aircrafts.featured`).
--   * Avião é item serializado: cada unidade é uma linha, com nº de série
--     OBRIGATÓRIO e único. Quantidade por modelo = unidades com in_stock.
--   * Saída automática ao converter a proposta em contrato (não na entrega).
--     Cancelar o contrato devolve a unidade (estorno automático).
--   * Valor da minuta continua vindo do catálogo; a unidade só contribui com
--     nº de série, prefixo e ano de fabricação.
--
-- Modelo:
--   * `stock_movements` — livro-razão imutável (sem UPDATE/DELETE para
--     ninguém). Cada linha é uma unidade entrando ou saindo. Erro se corrige
--     com um lançamento inverso (motivo `ajuste_inventario`).
--   * `available_aircraft_logs` — log de alteração de campos da unidade
--     (status, prefixo, serial...), preenchido por trigger.
--   * `available_aircrafts.in_stock` — espelho do último lançamento. Só as
--     funções deste arquivo mexem nele (guarda abaixo).
--
-- Permissão — o ponto delicado:
--   Escrita em `available_aircrafts` é de Admin documentação/Master
--   (`hardening_require_documentacao`), mas quem converte proposta é o
--   Vendedor. A baixa automática precisa atualizar a unidade sem abrir a
--   tabela para o funil. Solução: a guarda da tabela passa a ser própria
--   (`tg_available_aircrafts_guard`) e aceita, além de documentação, a escrita
--   feita DENTRO das funções SECURITY DEFINER deste arquivo, que ligam a flag
--   transacional `agsur.stock_sync`. PostgREST não expõe `set_config` (só o
--   schema public), então o cliente não consegue ligar a flag; e nesse
--   caminho só `in_stock`/`status`/`update_by` podem mudar.
--   Movimentações e logs não têm policy de escrita: nascem só pelas funções.

-- ── 1) Catálogo: destaque ────────────────────────────────────────────────────
alter table public.aircrafts
  add column if not exists featured boolean not null default false;

comment on column public.aircrafts.featured is
  'Modelo em destaque no catálogo interno (filtro rápido da proposta).';

-- ── 2) Unidade: prefixo, em-estoque, serial obrigatório e único ─────────────
alter table public.available_aircrafts
  add column if not exists registration_prefix text,
  add column if not exists in_stock boolean not null default true;

comment on column public.available_aircrafts.registration_prefix is
  'Prefixo/matrícula ANAC (ex.: PR-ABC). Opcional: importada só recebe no RAB.';
comment on column public.available_aircrafts.in_stock is
  'Espelho do último lançamento em stock_movements. Não editar à mão.';

alter table public.available_aircrafts
  drop constraint if exists ck_available_aircrafts_serial_not_blank;
alter table public.available_aircrafts
  add constraint ck_available_aircrafts_serial_not_blank
  check (btrim(serial_number) <> '');

create unique index if not exists uq_available_aircrafts_serial
  on public.available_aircrafts (lower(btrim(serial_number)));

-- ── 3) Proposta: unidade escolhida ───────────────────────────────────────────
alter table public.proposal
  add column if not exists available_aircraft_id uuid
    references public.available_aircrafts(id) on delete set null;

comment on column public.proposal.available_aircraft_id is
  'Unidade do estoque escolhida na proposta. Várias propostas podem disputar '
  'a mesma unidade; o contrato herda na conversão e aí ela sai do estoque.';

create index if not exists idx_proposal_available_aircraft_id
  on public.proposal (available_aircraft_id)
  where available_aircraft_id is not null;

-- ── 4) Livro-razão de movimentações ──────────────────────────────────────────
create table if not exists public.stock_movements (
  id                    uuid primary key default gen_random_uuid(),
  available_aircraft_id uuid not null
    references public.available_aircrafts(id) on delete restrict,
  -- Modelo no momento do lançamento (a unidade pode ter o modelo corrigido
  -- depois; o saldo histórico por modelo não pode andar junto).
  aircraft_model        uuid not null references public.aircrafts(id),
  movement_type         text not null
    check (movement_type in ('entrada', 'saida')),
  reason                text not null
    check (reason in (
      -- entrada
      'saldo_inicial', 'compra', 'importacao', 'devolucao_cliente',
      'cancelamento_contrato', 'desvinculo_contrato',
      -- saída
      'venda_contrato', 'baixa', 'devolucao_fabricante',
      -- os dois sentidos
      'ajuste_inventario'
    )),
  note                  text,
  contract_id           uuid references public.contract(id) on delete set null,
  batch_id              uuid,
  created_by            uuid default auth.uid(),
  created_at            timestamptz not null default now()
);

comment on table public.stock_movements is
  'Entradas e saídas do estoque de aeronaves. Imutável: nasce só pelas '
  'funções stock_* e pelo trigger de contrato; correção = lançamento inverso.';

create index if not exists idx_stock_movements_unit
  on public.stock_movements (available_aircraft_id, created_at desc);
create index if not exists idx_stock_movements_created_at
  on public.stock_movements (created_at desc);
create index if not exists idx_stock_movements_model
  on public.stock_movements (aircraft_model);

-- ── 5) Log de alterações da unidade ──────────────────────────────────────────
create table if not exists public.available_aircraft_logs (
  id                    uuid primary key default gen_random_uuid(),
  available_aircraft_id uuid not null
    references public.available_aircrafts(id) on delete restrict,
  action                text not null check (action in ('insert', 'update')),
  -- {"coluna": {"old": ..., "new": ...}} — só o que mudou.
  changes               jsonb not null,
  changed_by            uuid default auth.uid(),
  changed_at            timestamptz not null default now()
);

create index if not exists idx_available_aircraft_logs_unit
  on public.available_aircraft_logs (available_aircraft_id, changed_at desc);

-- Nota de privilégio: o default ACL do schema public concede EXECUTE/ALL
-- direto a anon e authenticated em todo objeto novo, então `revoke ... from
-- public` sozinho não fecha nada (ver 20260728123000). Tudo abaixo revoga dos
-- três e concede só o necessário.

-- ── 6) RLS: leitura para o painel, escrita só pelas funções ─────────────────
alter table public.stock_movements         enable row level security;
alter table public.available_aircraft_logs enable row level security;

revoke all on public.stock_movements         from anon, authenticated;
revoke all on public.available_aircraft_logs from anon, authenticated;
grant select on public.stock_movements         to authenticated;
grant select on public.available_aircraft_logs to authenticated;

drop policy if exists stock_movements_select on public.stock_movements;
create policy stock_movements_select on public.stock_movements
  for select to authenticated using (public.auth_is_seller_or_admin());

drop policy if exists available_aircraft_logs_select on public.available_aircraft_logs;
create policy available_aircraft_logs_select on public.available_aircraft_logs
  for select to authenticated using (public.auth_is_seller_or_admin());

-- ── 7) Guarda própria de available_aircrafts ────────────────────────────────
create or replace function public.tg_available_aircrafts_guard()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sync boolean := coalesce(current_setting('agsur.stock_sync', true), '') = 'on';
begin
  if public.auth_is_service_request() then
    return coalesce(new, old);
  end if;

  if v_sync then
    -- Caminho interno (funções stock_* / trigger de contrato). Para quem não
    -- é documentação, só o espelho de estoque pode mudar.
    if tg_op = 'UPDATE' and not public.auth_is_admin_documentacao() then
      if (to_jsonb(new) - array['in_stock', 'status', 'update_by'])
         is distinct from
         (to_jsonb(old) - array['in_stock', 'status', 'update_by']) then
        raise exception 'available_aircrafts: sincronização de estoque só altera status'
          using errcode = '42501';
      end if;
    end if;
    return coalesce(new, old);
  end if;

  if auth.uid() is null then
    raise exception '%.%: anonymous writes blocked', tg_table_schema, tg_table_name
      using errcode = '42501';
  end if;
  if not public.auth_is_admin_documentacao() then
    raise exception '%.%: requires Admin documentacao / Admin Master', tg_table_schema, tg_table_name
      using errcode = '42501';
  end if;

  -- Mesmo para documentação: entrada/saída só pelo livro-razão.
  if tg_op = 'INSERT' then
    raise exception 'Use a entrada de estoque para cadastrar aeronaves.'
      using errcode = '42501';
  end if;
  if tg_op = 'DELETE' then
    raise exception 'Aeronave do estoque não se exclui: registre uma saída.'
      using errcode = '42501';
  end if;
  if new.in_stock is distinct from old.in_stock then
    raise exception 'Use entrada/saída de estoque para mudar a disponibilidade.'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

revoke all on function public.tg_available_aircrafts_guard() from public, anon, authenticated;

drop trigger if exists hardening_require_documentacao on public.available_aircrafts;
drop trigger if exists hardening_available_aircrafts_guard on public.available_aircrafts;
create trigger hardening_available_aircrafts_guard
  before insert or update or delete on public.available_aircrafts
  for each row execute function public.tg_available_aircrafts_guard();

-- ── 8) Log automático de alterações da unidade ───────────────────────────────
create or replace function public.tg_available_aircrafts_log()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_changes jsonb := '{}'::jsonb;
  v_new jsonb := to_jsonb(new);
  v_old jsonb;
  k text;
begin
  if tg_op = 'INSERT' then
    insert into public.available_aircraft_logs (available_aircraft_id, action, changes)
    values (new.id, 'insert',
            v_new - array['id', 'created_at', 'created_by', 'update_by']);
    return new;
  end if;

  v_old := to_jsonb(old);
  for k in select jsonb_object_keys(v_new) loop
    -- in_stock já fica no livro-razão; aqui só o que é editado à mão.
    if k in ('update_by', 'created_at', 'created_by', 'in_stock') then continue; end if;
    if v_new -> k is distinct from v_old -> k then
      v_changes := v_changes || jsonb_build_object(
        k, jsonb_build_object('old', v_old -> k, 'new', v_new -> k));
    end if;
  end loop;

  if v_changes <> '{}'::jsonb then
    insert into public.available_aircraft_logs (available_aircraft_id, action, changes)
    values (new.id, 'update', v_changes);
  end if;
  return new;
end;
$$;

revoke all on function public.tg_available_aircrafts_log() from public, anon, authenticated;

drop trigger if exists trg_available_aircrafts_log on public.available_aircrafts;
create trigger trg_available_aircrafts_log
  after insert or update on public.available_aircrafts
  for each row execute function public.tg_available_aircrafts_log();

-- ── 9) Núcleo: lançar movimento + atualizar espelho ─────────────────────────
-- Interna (sem grant): valida o sentido contra o estado atual da unidade.
create or replace function public._stock_move(
  p_unit_id     uuid,
  p_type        text,
  p_reason      text,
  p_note        text,
  p_contract_id uuid,
  p_batch_id    uuid,
  p_status      text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_unit public.available_aircrafts;
begin
  select * into v_unit from public.available_aircrafts
   where id = p_unit_id for update;
  if not found then
    raise exception 'Unidade do estoque não encontrada.' using errcode = 'P0002';
  end if;

  if p_type = 'saida' and not v_unit.in_stock then
    raise exception 'A aeronave S/N % não está em estoque.', v_unit.serial_number
      using errcode = 'P0001';
  end if;
  if p_type = 'entrada' and v_unit.in_stock then
    raise exception 'A aeronave S/N % já está em estoque.', v_unit.serial_number
      using errcode = 'P0001';
  end if;

  insert into public.stock_movements
    (available_aircraft_id, aircraft_model, movement_type, reason, note,
     contract_id, batch_id)
  values
    (p_unit_id, v_unit.aircraft_model, p_type, p_reason, nullif(btrim(p_note), ''),
     p_contract_id, p_batch_id);

  perform set_config('agsur.stock_sync', 'on', true);
  update public.available_aircrafts
     set in_stock  = (p_type = 'entrada'),
         status    = coalesce(p_status, status),
         update_by = coalesce(auth.uid(), update_by)
   where id = p_unit_id;
  perform set_config('agsur.stock_sync', 'off', true);
end;
$$;

revoke all on function public._stock_move(uuid, text, text, text, uuid, uuid, text) from public, anon, authenticated;

-- ── 10) RPCs manuais (Admin documentação/Master) ─────────────────────────────
-- Entrada: um modelo, N unidades (cada uma com serial). Datas comuns ao lote
-- vêm por unidade no JSON — a tela preenche igual para todas por padrão.
--   p_units = [{"serial_number": "...", "registration_prefix": "...",
--               "manufacture_date": "YYYY-MM-DD", "configuration_deadline": "...",
--               "delivery_date": "...", "entry_year": "2026"}]
create or replace function public.stock_entry(
  p_aircraft_model uuid,
  p_reason         text,
  p_note           text,
  p_units          jsonb
)
returns setof uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_batch uuid := gen_random_uuid();
  v_unit  jsonb;
  v_id    uuid;
  v_sn    text;
begin
  if not public.auth_is_admin_documentacao() then
    raise exception 'Somente Admin documentação ou Admin Master movimenta o estoque.'
      using errcode = '42501';
  end if;
  if p_reason not in ('compra', 'importacao', 'devolucao_cliente', 'ajuste_inventario') then
    raise exception 'Motivo de entrada inválido: %', p_reason using errcode = '22023';
  end if;
  if p_units is null or jsonb_typeof(p_units) <> 'array' or jsonb_array_length(p_units) = 0 then
    raise exception 'Informe ao menos uma aeronave.' using errcode = '22023';
  end if;
  if not exists (select 1 from public.aircrafts a
                  where a.id = p_aircraft_model and not coalesce(a.deleted, false)) then
    raise exception 'Modelo do catálogo não encontrado.' using errcode = 'P0002';
  end if;

  for v_unit in select * from jsonb_array_elements(p_units) loop
    v_sn := btrim(coalesce(v_unit ->> 'serial_number', ''));
    if v_sn = '' then
      raise exception 'Número de série é obrigatório em todas as aeronaves.'
        using errcode = '22023';
    end if;

    perform set_config('agsur.stock_sync', 'on', true);
    insert into public.available_aircrafts
      (aircraft_model, serial_number, registration_prefix, manufacture_date,
       configuration_deadline, delivery_date, entry_year, status, in_stock,
       created_by, update_by)
    values
      (p_aircraft_model, v_sn,
       nullif(btrim(v_unit ->> 'registration_prefix'), ''),
       (v_unit ->> 'manufacture_date')::date,
       (v_unit ->> 'configuration_deadline')::date,
       (v_unit ->> 'delivery_date')::date,
       coalesce(nullif(v_unit ->> 'entry_year', ''),
                extract(year from current_date)::text),
       'Disponível', true, auth.uid(), auth.uid())
    returning id into v_id;
    perform set_config('agsur.stock_sync', 'off', true);

    insert into public.stock_movements
      (available_aircraft_id, aircraft_model, movement_type, reason, note, batch_id)
    values
      (v_id, p_aircraft_model, 'entrada', p_reason, nullif(btrim(p_note), ''), v_batch);

    return next v_id;
  end loop;
end;
$$;

-- Saída manual (baixa, devolução ao fabricante, ajuste). Venda NÃO passa
-- aqui — é o contrato que dá saída.
create or replace function public.stock_exit(
  p_unit_id uuid,
  p_reason  text,
  p_note    text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.auth_is_admin_documentacao() then
    raise exception 'Somente Admin documentação ou Admin Master movimenta o estoque.'
      using errcode = '42501';
  end if;
  if p_reason not in ('baixa', 'devolucao_fabricante', 'ajuste_inventario') then
    raise exception 'Motivo de saída inválido: %', p_reason using errcode = '22023';
  end if;
  if exists (select 1 from public.contract c
              where c.available_aircraft_id = p_unit_id and c.cancelled_at is null) then
    raise exception 'Aeronave vinculada a contrato ativo: desvincule ou cancele o contrato.'
      using errcode = 'P0001';
  end if;
  perform public._stock_move(p_unit_id, 'saida', p_reason, p_note, null, null, 'Baixado');
end;
$$;

-- Reentrada manual de uma unidade que saiu (devolução do cliente, ajuste).
create or replace function public.stock_reentry(
  p_unit_id uuid,
  p_reason  text,
  p_note    text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.auth_is_admin_documentacao() then
    raise exception 'Somente Admin documentação ou Admin Master movimenta o estoque.'
      using errcode = '42501';
  end if;
  if p_reason not in ('devolucao_cliente', 'ajuste_inventario') then
    raise exception 'Motivo de entrada inválido: %', p_reason using errcode = '22023';
  end if;
  if exists (select 1 from public.contract c
              where c.available_aircraft_id = p_unit_id and c.cancelled_at is null) then
    raise exception 'Aeronave vinculada a contrato ativo: cancele o contrato para devolvê-la.'
      using errcode = 'P0001';
  end if;
  perform public._stock_move(p_unit_id, 'entrada', p_reason, p_note, null, null, 'Disponível');
end;
$$;

revoke all on function public.stock_entry(uuid, text, text, jsonb) from public, anon;
revoke all on function public.stock_exit(uuid, text, text)         from public, anon;
revoke all on function public.stock_reentry(uuid, text, text)      from public, anon;
grant execute on function public.stock_entry(uuid, text, text, jsonb) to authenticated;
grant execute on function public.stock_exit(uuid, text, text)         to authenticated;
grant execute on function public.stock_reentry(uuid, text, text)      to authenticated;

-- ── 11) Proposta: unidade precisa ser do modelo e estar em estoque ──────────
create or replace function public.tg_proposal_stock_unit_check()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_unit public.available_aircrafts;
begin
  if new.available_aircraft_id is null then
    return new;
  end if;
  if tg_op = 'UPDATE'
     and new.available_aircraft_id is not distinct from old.available_aircraft_id
     and new.aircraft_id is not distinct from old.aircraft_id then
    return new;
  end if;

  select * into v_unit from public.available_aircrafts
   where id = new.available_aircraft_id;
  if v_unit.aircraft_model is distinct from new.aircraft_id then
    raise exception 'A aeronave do estoque é de outro modelo que o da proposta.'
      using errcode = 'P0001';
  end if;
  -- Só exige estoque quando a unidade muda (proposta antiga não trava).
  if (tg_op = 'INSERT' or new.available_aircraft_id is distinct from old.available_aircraft_id)
     and not v_unit.in_stock then
    raise exception 'A aeronave S/N % não está mais em estoque.', v_unit.serial_number
      using errcode = 'P0001';
  end if;
  return new;
end;
$$;

revoke all on function public.tg_proposal_stock_unit_check() from public, anon, authenticated;

drop trigger if exists trg_proposal_stock_unit_check on public.proposal;
create trigger trg_proposal_stock_unit_check
  before insert or update of available_aircraft_id, aircraft_id on public.proposal
  for each row execute function public.tg_proposal_stock_unit_check();

-- ── 12) Contrato: herda da proposta, valida, dá saída / estorno ─────────────
create or replace function public.tg_contract_stock_before()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_unit  public.available_aircrafts;
  v_model uuid;
begin
  if tg_op = 'INSERT' and new.available_aircraft_id is null then
    select p.available_aircraft_id into new.available_aircraft_id
      from public.proposal p where p.id = new.proposal_id;
  end if;

  -- Só valida quando uma unidade passa a ocupar um contrato ativo.
  if new.available_aircraft_id is null or new.cancelled_at is not null then
    return new;
  end if;
  if tg_op = 'UPDATE'
     and new.available_aircraft_id is not distinct from old.available_aircraft_id
     and old.cancelled_at is null then
    return new;
  end if;

  select * into v_unit from public.available_aircrafts
   where id = new.available_aircraft_id;
  if not found then
    raise exception 'Unidade do estoque não encontrada.' using errcode = 'P0002';
  end if;
  select p.aircraft_id into v_model from public.proposal p where p.id = new.proposal_id;
  if v_unit.aircraft_model is distinct from v_model then
    raise exception 'A aeronave do estoque é de outro modelo que o da proposta.'
      using errcode = 'P0001';
  end if;
  if not v_unit.in_stock then
    raise exception 'A aeronave S/N % não está em estoque.', v_unit.serial_number
      using errcode = 'P0001';
  end if;
  return new;
end;
$$;

create or replace function public.tg_contract_stock_after()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old_unit   uuid := case when tg_op = 'UPDATE' then old.available_aircraft_id end;
  v_old_active boolean := tg_op = 'UPDATE' and old.cancelled_at is null;
  v_new_active boolean := new.cancelled_at is null;
begin
  -- Unidade que deixa de estar num contrato ativo volta ao estoque.
  if v_old_unit is not null and v_old_active
     and (not v_new_active or new.available_aircraft_id is distinct from v_old_unit) then
    perform public._stock_move(
      v_old_unit, 'entrada',
      case when not v_new_active then 'cancelamento_contrato' else 'desvinculo_contrato' end,
      null, new.id, null, 'Disponível');
  end if;

  -- Unidade que passa a estar num contrato ativo sai do estoque.
  if new.available_aircraft_id is not null and v_new_active
     and (tg_op = 'INSERT' or not v_old_active
          or new.available_aircraft_id is distinct from v_old_unit) then
    perform public._stock_move(
      new.available_aircraft_id, 'saida', 'venda_contrato',
      null, new.id, null, 'Vendido');
  end if;
  return new;
end;
$$;

revoke all on function public.tg_contract_stock_before() from public, anon, authenticated;
revoke all on function public.tg_contract_stock_after()  from public, anon, authenticated;

drop trigger if exists trg_contract_stock_before on public.contract;
create trigger trg_contract_stock_before
  before insert or update of available_aircraft_id, cancelled_at on public.contract
  for each row execute function public.tg_contract_stock_before();

drop trigger if exists trg_contract_stock_after on public.contract;
create trigger trg_contract_stock_after
  after insert or update of available_aircraft_id, cancelled_at on public.contract
  for each row execute function public.tg_contract_stock_after();

-- ── 13) Views para o painel (security_invoker: respeitam a RLS das bases) ───
create or replace view public.vw_stock_units
with (security_invoker = on) as
select
  aa.id,
  aa.aircraft_model          as aircraft_id,
  a.aircraft_model           as aircraft_model_name,
  a.aircraft_photo_url,
  a.featured,
  aa.serial_number,
  aa.registration_prefix,
  aa.manufacture_date,
  aa.configuration_deadline,
  aa.delivery_date,
  aa.entry_year,
  aa.status,
  aa.in_stock,
  aa.created_at,
  c.id                       as contract_id,
  c.proposal_id              as contract_proposal_id
from public.available_aircrafts aa
join public.aircrafts a on a.id = aa.aircraft_model
left join public.contract c
  on c.available_aircraft_id = aa.id and c.cancelled_at is null;

create or replace view public.vw_stock_movements
with (security_invoker = on) as
select
  m.id,
  m.available_aircraft_id,
  m.aircraft_model           as aircraft_id,
  a.aircraft_model           as aircraft_model_name,
  aa.serial_number,
  m.movement_type,
  m.reason,
  m.note,
  m.contract_id,
  m.batch_id,
  m.created_by,
  coalesce(nullif(btrim(u.fullname), ''), u.email) as created_by_name,
  m.created_at
from public.stock_movements m
join public.aircrafts a            on a.id = m.aircraft_model
join public.available_aircrafts aa on aa.id = m.available_aircraft_id
left join public.users u           on u.id = m.created_by;

revoke all on public.vw_stock_units     from anon, authenticated;
revoke all on public.vw_stock_movements from anon, authenticated;
grant select on public.vw_stock_units     to authenticated;
grant select on public.vw_stock_movements to authenticated;

-- ── 14) Saldo inicial das unidades que já existem ───────────────────────────
insert into public.stock_movements
  (available_aircraft_id, aircraft_model, movement_type, reason, note,
   created_by, created_at)
select aa.id, aa.aircraft_model, 'entrada', 'saldo_inicial',
       'Saldo inicial na implantação do controle de estoque',
       aa.created_by, aa.created_at
from public.available_aircrafts aa
where not exists (select 1 from public.stock_movements m
                   where m.available_aircraft_id = aa.id);

-- Unidades presas a contrato ativo: saída de venda na data do contrato.
insert into public.stock_movements
  (available_aircraft_id, aircraft_model, movement_type, reason, note,
   contract_id, created_by, created_at)
select aa.id, aa.aircraft_model, 'saida', 'venda_contrato',
       'Saldo inicial: unidade já vinculada a contrato',
       c.id, c.created_by, greatest(c.created_at, aa.created_at)
from public.available_aircrafts aa
join public.contract c
  on c.available_aircraft_id = aa.id and c.cancelled_at is null
where aa.in_stock
  and not exists (select 1 from public.stock_movements m
                   where m.available_aircraft_id = aa.id and m.movement_type = 'saida');

-- Vendido/Entregue sem contrato: saíram por fora do sistema.
insert into public.stock_movements
  (available_aircraft_id, aircraft_model, movement_type, reason, note,
   created_by, created_at)
select aa.id, aa.aircraft_model, 'saida', 'ajuste_inventario',
       'Saldo inicial: unidade já marcada como ' || aa.status,
       aa.update_by, aa.created_at
from public.available_aircrafts aa
where aa.in_stock
  and aa.status in ('Vendido', 'Entregue')
  and not exists (select 1 from public.contract c
                   where c.available_aircraft_id = aa.id and c.cancelled_at is null)
  and not exists (select 1 from public.stock_movements m
                   where m.available_aircraft_id = aa.id and m.movement_type = 'saida');

-- O db push conecta com o login role da CLI, que não está no bypass de
-- auth_is_service_request() — desarma só a guarda de autorização (padrão de
-- 20260817140000); o log de alterações segue ligado e registra a mudança.
alter table public.available_aircrafts disable trigger hardening_available_aircrafts_guard;

update public.available_aircrafts aa
   set in_stock = false
 where aa.in_stock
   and exists (select 1 from public.stock_movements m
                where m.available_aircraft_id = aa.id and m.movement_type = 'saida');

alter table public.available_aircrafts enable trigger hardening_available_aircrafts_guard;
