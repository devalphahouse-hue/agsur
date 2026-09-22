-- Entrega estimada = fabricação + 60 dias, e prazo de configuração opcional
-- (reunião com o cliente, 2026-09-22)
--
-- Pedido: "Delivery Estimate: the system will auto-calculate Fabrication Date
-- + 60 days to account for configuration and documentation" e popular o
-- estoque a partir de uma planilha que só traz Modelo, Nº de série e Data de
-- fabricação.
--
-- Consequências:
--   * `configuration_deadline` deixa de ser NOT NULL — a planilha não tem esse
--     dado e ele não entra em nenhum cálculo. Quem tiver, preenche na edição.
--   * `stock_entry` passa a derivar o que falta: entrega = fabricação + 60
--     dias, ano base = ano da fabricação. Quem informar, manda como antes.
--     A conta fica no BANCO (e não só na tela) para a importação em massa e
--     qualquer chamada futura caírem na mesma regra.
--
-- A função antiga `public.fn_available_aircrafts` não é afetada (TO_CHAR de
-- coluna nula devolve null).

alter table public.available_aircrafts
  alter column configuration_deadline drop not null;

comment on column public.available_aircrafts.configuration_deadline is
  'Prazo de configuração (opcional). Não entra no cálculo da entrega.';
comment on column public.available_aircrafts.delivery_date is
  'Entrega estimada. Padrão: manufacture_date + 60 dias (regra do cliente, '
  '2026-09-22); editável.';

-- Dias entre fabricação e entrega estimada. Num lugar só: a tela mostra o
-- mesmo número que o banco aplica.
create or replace function public.stock_delivery_offset_days()
returns integer
language sql
immutable
as $$ select 60 $$;

comment on function public.stock_delivery_offset_days() is
  'Dias somados à data de fabricação para a entrega estimada (60).';

revoke all on function public.stock_delivery_offset_days() from public, anon;
grant execute on function public.stock_delivery_offset_days() to authenticated, service_role;

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
  v_manuf date;
  v_deliv date;
  v_conf  date;
  v_year  text;
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

    v_manuf := nullif(v_unit ->> 'manufacture_date', '')::date;
    if v_manuf is null then
      raise exception 'Data de fabricação é obrigatória (S/N %).', v_sn
        using errcode = '22023';
    end if;

    -- Derivados: entrega = fabricação + 60 dias; ano base = ano da fabricação.
    v_deliv := coalesce(nullif(v_unit ->> 'delivery_date', '')::date,
                        v_manuf + public.stock_delivery_offset_days());
    v_conf  := nullif(v_unit ->> 'configuration_deadline', '')::date;
    v_year  := coalesce(nullif(v_unit ->> 'entry_year', ''),
                        extract(year from v_manuf)::text);

    perform set_config('agsur.stock_sync', 'on', true);
    insert into public.available_aircrafts
      (aircraft_model, serial_number, registration_prefix, manufacture_date,
       configuration_deadline, delivery_date, entry_year, status, in_stock,
       created_by, update_by)
    values
      (p_aircraft_model, v_sn,
       nullif(btrim(v_unit ->> 'registration_prefix'), ''),
       v_manuf, v_conf, v_deliv, v_year,
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

revoke all on function public.stock_entry(uuid, text, text, jsonb) from public, anon;
grant execute on function public.stock_entry(uuid, text, text, jsonb) to authenticated;
