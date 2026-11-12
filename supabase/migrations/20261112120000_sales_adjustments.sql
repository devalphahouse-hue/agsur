-- Vendedor Admin keeps the seller identity and receives the operational permissions
-- of documentation administrators. Financial visibility is enforced separately.
create or replace function public.auth_is_seller_manager()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.users
    where id = auth.uid() and profile_type = 'Vendedor'
      and access_level = 'vendedor_admin' and not coalesce(is_deleted, false)
  );
$$;
revoke all on function public.auth_is_seller_manager() from public, anon;
grant execute on function public.auth_is_seller_manager() to authenticated, service_role;

create or replace function public.auth_is_admin_documentacao()
returns boolean language sql stable security definer set search_path = '' as $$
  select public.auth_is_seller_manager() or exists (
    select 1 from public.users
    where id = auth.uid() and not coalesce(is_deleted, false)
      and (profile_type = 'Admin Master'
        or (profile_type = 'Admin' and access_level = 'documentacao'))
  );
$$;

create policy hide_receivables_from_seller_manager on public.financial
  as restrictive for select to authenticated using (not public.auth_is_seller_manager());
create policy hide_receivables_from_seller_manager on public.sales
  as restrictive for select to authenticated using (not public.auth_is_seller_manager());
create policy seller_manager_financing_rates on public.financing_rates
  for all to authenticated using (public.auth_is_seller_manager())
  with check (public.auth_is_seller_manager());

create trigger contract_admin_changes before insert or update or delete on public.contract
  for each row execute function public.tg_require_documentacao();
create trigger contract_terms_admin_changes before insert or update or delete on public.contract_terms
  for each row execute function public.tg_require_documentacao();
drop trigger if exists hardening_require_seller_or_admin on public.aircraft_item_links;
create trigger hardening_require_documentacao before insert or update or delete on public.aircraft_item_links
  for each row execute function public.tg_require_documentacao();

alter table public.proposal_item
  alter column aircraft_item_id drop not null,
  add column manual_name text,
  add column unit_price numeric(16, 2),
  add column quantity integer,
  add column discount_percent numeric(5, 2) not null default 0,
  add constraint proposal_item_discount_valid check (discount_percent between 0 and 100),
  add constraint proposal_item_price_valid check (unit_price >= 0 and unit_price < 'Infinity'::numeric),
  add constraint proposal_item_quantity_valid check (quantity between 1 and 100000),
  add constraint proposal_item_kind_valid check (
    (aircraft_item_id is not null and manual_name is null)
    or (aircraft_item_id is null and nullif(btrim(manual_name), '') is not null
      and char_length(manual_name) <= 240 and unit_price is not null and quantity is not null)
  );

-- Legacy catalog items without model mappings are available as general items.
-- Explicit model mappings continue to restrict applicability.
create or replace view public.vw_aircraft_items_by_aircraft
with (security_invoker = on) as
select i.id, i.category_id, i.item_name, i.qty, i.price, i.active, i.deleted,
       i.created_at, i.item_type, models.aircraft_id
from public.aircraft_items i
join lateral (
  select l.aircraft_id from public.aircraft_item_links l where l.aircraft_item_id = i.id
  union all
  select a.id from public.aircrafts a
  where i.item_type = 'optional' and i.active and not coalesce(i.deleted, false)
    and not coalesce(a.deleted, false)
    and not exists (select 1 from public.aircraft_item_links l where l.aircraft_item_id = i.id)
) models on true;

create function public.guard_proposal_item()
returns trigger language plpgsql set search_path = '' as $$
declare
  parent public.proposal;
  item public.vw_aircraft_items_by_aircraft;
begin
  select * into parent from public.proposal
  where id = case when tg_op = 'DELETE' then old.proposal_id else new.proposal_id end
  for update;
  if not found or parent.is_contract or parent.is_deleted or not parent.active then
    raise exception 'Somente propostas abertas podem ter itens alterados.' using errcode = '42501';
  end if;
  if tg_op = 'DELETE' then return old; end if;
  if tg_op = 'UPDATE' and (new.proposal_id is distinct from old.proposal_id
      or new.aircraft_item_id is distinct from old.aircraft_item_id) then
    raise exception 'Remova o item e adicione-o novamente para alterar o vínculo.';
  end if;
  if (case when tg_op = 'INSERT' then new.discount_percent <> 0
           else new.discount_percent is distinct from old.discount_percent end)
      and not (public.auth_is_admin_documentacao() or public.auth_is_service_request()) then
    raise exception 'Somente Admin ou Vendedor Admin pode alterar descontos.' using errcode = '42501';
  end if;
  if new.aircraft_item_id is not null then
    if tg_op = 'INSERT' then
      select * into item from public.vw_aircraft_items_by_aircraft
      where id = new.aircraft_item_id and aircraft_id = parent.aircraft_id
        and active and not coalesce(deleted, false) and item_type = 'optional';
      if not found then raise exception 'Opcional indisponível para esta aeronave.'; end if;
      if exists (select 1 from public.proposal_item
                 where proposal_id = parent.id and aircraft_item_id = new.aircraft_item_id) then
        return null;
      end if;
      new.unit_price := item.price;
      new.quantity := item.qty;
    elsif new.unit_price is distinct from old.unit_price or new.quantity is distinct from old.quantity then
      raise exception 'O preço e a quantidade deste item vêm do catálogo.';
    end if;
  end if;
  return new;
end;
$$;

create function public.refresh_proposal_total()
returns trigger language plpgsql set search_path = '' as $$
declare
  proposal_uuid uuid := case when tg_op = 'DELETE' then old.proposal_id else new.proposal_id end;
begin
  update public.proposal p set fullprice = p.fullprice where p.id = proposal_uuid;
  return null;
end;
$$;

create function public.guard_proposal_total()
returns trigger language plpgsql set search_path = '' as $$
declare
  expected numeric;
begin
  select a.price + coalesce((
    select sum(round(coalesce(pi.unit_price, i.price)::numeric
        * (1 - pi.discount_percent / 100), 2) * coalesce(pi.quantity, i.qty))
    from public.proposal_item pi left join public.aircraft_items i on i.id = pi.aircraft_item_id
    where pi.proposal_id = new.id
  ), 0) into expected
  from public.aircrafts a where a.id = new.aircraft_id;
  if found then new.fullprice := expected; end if;
  return new;
end;
$$;
create trigger proposal_total_is_derived before insert or update of fullprice, aircraft_id on public.proposal
  for each row execute function public.guard_proposal_total();

create trigger proposal_item_validate before insert or update or delete on public.proposal_item
  for each row execute function public.guard_proposal_item();
create trigger proposal_item_total after insert or update or delete on public.proposal_item
  for each row execute function public.refresh_proposal_total();

create function public.guard_converted_proposal()
returns trigger language plpgsql set search_path = '' as $$
declare
  previous_row jsonb := to_jsonb(old);
  current_row jsonb := to_jsonb(new);
begin
  if not public.auth_is_vendedor() or public.auth_is_seller_manager() then
    return coalesce(new, old);
  end if;

  if tg_table_name = 'proposal' then
    if coalesce((previous_row->>'is_contract')::boolean, false)
       or coalesce((current_row->>'is_contract')::boolean, false) then
      raise exception 'Solicite a alteração do contrato a um administrador.' using errcode = '42501';
    end if;
  elsif exists (
    select 1 from public.proposal p
    where p.id in ((previous_row->>'proposal_id')::uuid, (current_row->>'proposal_id')::uuid)
      and p.is_contract
  ) then
    raise exception 'Solicite a alteração do contrato a um administrador.' using errcode = '42501';
  end if;
  return coalesce(new, old);
end;
$$;
create trigger proposal_after_conversion before insert or update or delete on public.proposal
  for each row execute function public.guard_converted_proposal();
create trigger financing_after_conversion before insert or update or delete on public.proposal_financing
  for each row execute function public.guard_converted_proposal();

create function public.guard_proposal_entry()
returns trigger language plpgsql set search_path = '' as $$
begin
  if tg_op = 'UPDATE' and new.down_payment is not distinct from old.down_payment
       and new.initial_deposit is not distinct from old.initial_deposit
       and new.total_deposit is not distinct from old.total_deposit then
    return new;
  end if;
  if round(new.down_payment::numeric, 8) is distinct from 0.05 or new.initial_deposit is null
      or new.initial_deposit not between 0 and 0.95 then
    raise exception 'A entrada total deve incluir o sinal de 5%% e ficar entre 5%% e 100%%.';
  end if;
  new.total_deposit := new.down_payment + new.initial_deposit;
  return new;
end;
$$;
create trigger proposal_entry_total before insert or update of down_payment, initial_deposit, total_deposit
  on public.proposal_financing for each row execute function public.guard_proposal_entry();


create or replace function public.create_proposal_with_items(
  p_id uuid, p_lead_id uuid, p_aircraft_id uuid, p_stock_unit_id uuid,
  p_reference text, p_financing jsonb, p_items jsonb
) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare
  v_existing public.proposal;
  v_rates public.financing_rates;
  v_price numeric;
  v_term integer := (p_financing->>'term_length')::integer;
  v_down numeric := (p_financing->>'down_payment')::numeric;
  v_initial numeric := (p_financing->>'initial_deposit')::numeric;
begin
  if auth.uid() is null or not public.auth_is_seller_or_admin() then
    raise exception 'Sem permissão para criar propostas.' using errcode='42501';
  end if;
  -- The client keeps this UUID across retries, even after a lost response.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_id::text, 0));
  select * into v_existing from public.proposal where id=p_id;
  if found then
    if v_existing.created_by is distinct from auth.uid()
       or v_existing.lead_id is distinct from p_lead_id
       or v_existing.aircraft_id is distinct from p_aircraft_id
       or v_existing.is_deleted
       or not exists(select 1 from public.proposal_financing where proposal_id=p_id) then
      raise exception 'Esta tentativa não corresponde a uma proposta completa. Atualize a página.';
    end if;
    return p_id;
  end if;
  if not exists(select 1 from public.leads where id=p_lead_id and active and not is_deleted) then
    raise exception 'Selecione um lead ativo antes de continuar.';
  end if;
  if v_term is null or v_term not in (5,7)
     or nullif(p_financing->>'credit_date','') is null
     or v_down is null or v_initial is null
     or v_down <> 0.05 or v_initial < 0 or v_down+v_initial > 1 then
    raise exception 'Confira o prazo, a data e os percentuais do financiamento.';
  end if;
  select * into v_rates from public.financing_rates
    where id='ce659e4b-caee-4b88-8d99-46f15c7e9b69';
  if not found or v_rates.sofr_rate+v_rates.interest_rate <= 0 then
    raise exception 'Confira as taxas de financiamento antes de criar a proposta.';
  end if;
  select price into v_price from public.aircrafts
    where id=p_aircraft_id and not deleted;
  if not found then raise exception 'Selecione um modelo de aeronave disponível.'; end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) > 500 then
    raise exception 'Confira os itens da proposta.';
  end if;
  insert into public.proposal(id,lead_id,aircraft_id,fullprice,created_by,available_aircraft_id,id_ref)
    values(p_id,p_lead_id,p_aircraft_id,v_price,auth.uid(),p_stock_unit_id,p_reference);
  insert into public.proposal_financing(proposal_id,created_by,term_length,credit_date,
    down_payment,initial_deposit,total_deposit,premium_rate,sofr_rate,interest_rate)
    values(p_id,auth.uid(),v_term,(p_financing->>'credit_date')::date,
      v_down,v_initial,v_down+v_initial,
      case when v_term=5 then v_rates.premium_rate_five else v_rates.premium_rate_seven end,
      v_rates.sofr_rate,v_rates.interest_rate);
  insert into public.proposal_item(proposal_id, aircraft_item_id, manual_name, quantity, unit_price, discount_percent)
    select p_id, aircraft_item_id, nullif(btrim(manual_name), ''), quantity, unit_price, coalesce(discount_percent, 0)
    from jsonb_to_recordset(p_items) as items(
      aircraft_item_id uuid, manual_name text, quantity integer, unit_price numeric, discount_percent numeric);
  return p_id;
end;
$$;

create or replace function public.create_proposal_atomic(
  p_id uuid, p_lead_id uuid, p_aircraft_id uuid, p_stock_unit_id uuid,
  p_reference text, p_financing jsonb, p_optional_ids uuid[]
) returns uuid language sql security invoker set search_path = '' as $$
  select public.create_proposal_with_items(
    p_id, p_lead_id, p_aircraft_id, p_stock_unit_id, p_reference,
    p_financing || jsonb_build_object(
      'down_payment', 0.05,
      'initial_deposit', (p_financing->>'initial_deposit')::numeric
                         + (p_financing->>'down_payment')::numeric - 0.05
    ),
    coalesce((select jsonb_agg(jsonb_build_object('aircraft_item_id', id))
      from (select distinct unnest(p_optional_ids) as id) as items), '[]'::jsonb));
$$;

revoke all on function public.create_proposal_with_items(uuid,uuid,uuid,uuid,text,jsonb,jsonb) from public, anon;
grant execute on function public.create_proposal_with_items(uuid,uuid,uuid,uuid,text,jsonb,jsonb) to authenticated;

create or replace function public.convert_proposal_atomic(
  p_proposal_id uuid, p_email text, p_new_client_id uuid default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_proposal public.proposal;
  v_lead public.leads;
  v_user public.users;
  v_contract uuid;
  v_aircraft uuid;
  v_sale uuid := gen_random_uuid();
  v_created boolean := false;
  v_email text := lower(btrim(p_email));
begin
  if auth.uid() is null or not public.auth_is_admin_documentacao() then
    raise exception 'Sem permissão para converter propostas.' using errcode='42501';
  end if;
  select * into v_proposal from public.proposal where id=p_proposal_id for update;
  if not found or v_proposal.is_deleted or not v_proposal.active then
    raise exception 'Proposta não encontrada ou inativa.';
  end if;
  -- Serialize conversions of the same proposal. A retry returns the original.
  select id into v_contract from public.contract where proposal_id=p_proposal_id and cancelled_at is null;
  if found then
    if not v_proposal.is_contract then
      raise exception 'Existe um contrato anterior incompleto. Peça uma revisão ao administrador.';
    end if;
    return jsonb_build_object('contract_id',v_contract,'client_created',false);
  end if;
  if v_proposal.is_contract then raise exception 'Esta proposta já foi convertida.'; end if;
  if not exists(select 1 from public.proposal_financing where proposal_id=p_proposal_id) then
    raise exception 'A proposta está sem financiamento. Complete o cadastro antes de converter.';
  end if;
  select * into v_lead from public.leads where id=v_proposal.lead_id for update;
  if not found or v_lead.is_deleted then raise exception 'Lead não encontrado ou excluído.'; end if;
  if v_email is null or v_email='' or v_email is distinct from lower(btrim(v_lead.email)) then
    raise exception 'O e-mail do lead mudou. Confira o e-mail antes de converter.';
  end if;
  -- Different proposals can reuse the same client without racing its creation.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_email, 1));
  select * into v_user from public.users where lower(email)=v_email and not is_deleted for update;
  if found then
    if v_user.profile_type::text <> 'Cliente' then
      raise exception 'Este e-mail pertence a um usuário que não é cliente. Corrija o e-mail.';
    end if;
    if v_user.lead_id is not null and v_user.lead_id <> v_lead.id then
      raise exception 'Este e-mail pertence a um cliente vinculado a outro lead. Corrija o e-mail.';
    end if;
    if v_user.lead_id is null then
      update public.users set lead_id=v_lead.id where id=v_user.id;
      if not found then raise exception 'Sem permissão para vincular o cliente ao lead.' using errcode='42501'; end if;
    end if;
  else
    if p_new_client_id is null then raise exception 'Não foi possível criar o acesso do cliente. Tente novamente.'; end if;
    insert into public.users(id,name,lastname,fullname,email,phone,cpf,profile_type,is_admin,status,lead_id,profile_photo_url)
      values(p_new_client_id,v_lead.name,v_lead.last_name,v_lead.fullname,v_email,v_lead.phone,
        v_lead.cpf,'Cliente',false,'approved',v_lead.id,
        'https://bkzybtmxxzpxtztesdye.supabase.co/storage/v1/object/public/AGSur//user_icon%20(1).png')
      returning * into v_user;
    v_created := true;
  end if;
  insert into public.contract("user_Id",proposal_id,fullprice,created_by)
    values(v_user.id,p_proposal_id,v_proposal.fullprice,auth.uid()) returning id into v_contract;
  insert into public.user_aircraft(created_by,aircraft_status,proposal_id,contract_id)
    values(auth.uid(),'processing',p_proposal_id,v_contract) returning id into v_aircraft;
  insert into public.sales(id,seller_id,proposal_id,fullprice,seller_commission,company_commission,created_by)
    values(v_sale,v_proposal.created_by,p_proposal_id,v_proposal.fullprice,
      case when coalesce(v_lead.is_referral,false) then 4500 else 7500 end,
      greatest(v_proposal.fullprice,0)*0.02,auth.uid());
  insert into public.financial(financial_type,sale_id,description,financial_status,created_by)
    values('income',v_sale,'Venda de aeronave','pending',auth.uid());
  insert into public.tracking(user_aircraft,tracking_description,"isCheck","order")
    select v_aircraft,description,false,(ordinality-1)::smallint from unnest(array[
      'Cadastro Inicial','Personalização da Aeronave','Solicitar Proforma Invoice',
      'Reservar Equipamento Agrícola Inox','Pagar Reserva','Pagamento 5%','Status Fiscal',
      'Contratação de Despachante Aduaneiro','Reserva de Marcas (RAB)','Formalização de Pagamento',
      'Aprovação de Crédito','Pré-contrato (Novo)','Contratação de Seguro','Apólices (Casco, LUC, RETA)',
      'Saldo de Entrada','Links de Acompanhamento','Documentação para Oficina',
      'Assinatura de Contrato Final','Documentação do Despachante','Desembaraço Aduaneiro','Liberação para Voo'
    ]) with ordinality as stages(description,ordinality);
  update public.proposal set is_contract=true where id=p_proposal_id;
  if not found then raise exception 'Sem permissão para concluir a conversão.' using errcode='42501'; end if;
  return jsonb_build_object('contract_id',v_contract,'client_created',v_created);
end;
$$;

CREATE OR REPLACE FUNCTION public.get_proposal_details(p_proposal_id uuid)
 RETURNS TABLE(proposal json, proposal_lead json, proposal_company json, proposal_address json, proposal_aircraft json, proposal_series_items json, proposal_optional_items json)
 LANGUAGE plpgsql
AS $function$BEGIN
    RETURN QUERY
    WITH ordered_optional_items AS (
        SELECT
            pi.id,
            pi.proposal_id,
            pi.aircraft_item_id,
            pi.created_at,
            coalesce(ai2.id, pi.id) AS item_id,
            coalesce(pi.quantity, ai2.qty) as qty,
            round(coalesce(pi.unit_price, ai2.price)::numeric * (1 - pi.discount_percent / 100), 2) as price,
            coalesce(pi.unit_price, ai2.price) as unit_price,
            pi.discount_percent,
            ai2.category_id,
            coalesce(pi.manual_name, ai2.item_name) as item_name,
            coalesce(cat2.category_name, 'Itens personalizados') as category_name
        FROM
            public.proposal_item pi
        LEFT JOIN
            public.aircraft_items ai2 ON ai2.id = pi.aircraft_item_id
        LEFT JOIN
            public.category cat2 ON cat2.id = ai2.category_id
        WHERE
            pi.proposal_id = p_proposal_id
            AND (pi.aircraft_item_id is null OR ai2.item_type = 'optional')
        ORDER BY
            cat2.category_name
    )
    SELECT
        -- Proposal
        json_build_object(
            'id', p.id,
            'lead_id', p.lead_id,
            'aircraft_id', p."aircraft_id",
            'fullprice', p.fullprice,
            'created_at', p.created_at,
            'created_by', p.created_by,
            'id_ref', p.id_ref,
            'is_contract', p.is_contract,
            'delivery_date', (select unit.delivery_date from public.available_aircrafts unit
                where unit.id = p.available_aircraft_id)
        ) AS proposal,
        -- Lead
        json_build_object(
            'id', l.id,
            'fullname', COALESCE(l.name || ' ' || COALESCE(l.last_name, ''), 'Não cadastrado'),
            'email', COALESCE(l.email, 'Não cadastrado'),
            'phone', COALESCE(l.phone, 'Não cadastrado')
        ) AS proposal_lead,
        -- Company
        json_build_object(
            'id', COALESCE(c.id::text, 'Não cadastrado'),
            'company_name', COALESCE(c.company_name, 'Não cadastrado'),
            'cnpj', COALESCE(c.cnpj, 'Não cadastrado'),
            'phone', COALESCE(c.phone, 'Não cadastrado'),
            'cpf', COALESCE(c.cpf, 'Não cadastrado'),
            'type_doc', COALESCE(c.type_doc, '0')
        ) AS proposal_company,
        -- Address
        json_build_object(
            'id', COALESCE(a.id::text, 'Não cadastrado'),
            'zipcode', COALESCE(a.zipcode, 'Não cadastrado'),
            'street', COALESCE(a.street, 'Não cadastrado'),
            'number', COALESCE(a.number, 'Não cadastrado'),
            'neighborhood', COALESCE(a.neighborhood, 'Não cadastrado'),
            'city', COALESCE(a.city, 'Não cadastrado'),
            'state', COALESCE(a.state, 'Não cadastrado'),
            'complement', COALESCE(NULLIF(a.complement, ''), 'Não cadastrado')
        ) AS proposal_address,
        -- Aircraft
        json_build_object(
            'aircraft_photo_url', COALESCE(air.aircraft_photo_url, 'Não cadastrado'),
            'aircraft_model', COALESCE(air.aircraft_model, 'Não cadastrado'),
            'aircraft_year', COALESCE(air.aircraft_year, 'Não cadastrado'),
            'aircraft_description', COALESCE(air.aircraft_description, 'Não cadastrado'),
            'hopper', COALESCE(air.hopper, 0)
        ) AS proposal_aircraft,
        -- Series Items: SÓ os itens vinculados ao avião da proposta
        COALESCE(
            json_agg(
                json_build_object(
                    'item_name', ai.item_name,
                    'item_type', ai.item_type,
                    'qty', ai.qty,
                    'price', ai.price,
                    'category_id', ai.category_id,
                    'category_name', (SELECT cat.category_name FROM public.category cat WHERE cat.id = ai.category_id)
                )
            ) FILTER (WHERE ai.item_type = 'series' AND ai.active = true AND ai.deleted = false),
            '[]'
        ) AS proposal_series_items,
        -- Optional Items (ordenados por category_name)
        COALESCE(
            (SELECT json_agg(
                json_build_object(
                    'id', oi.id,
                    'proposal_id', oi.proposal_id,
                    'aircraft_item_id', oi.aircraft_item_id,
                    'unit_price', oi.unit_price,
                    'discount_percent', oi.discount_percent,
                    'created_at', oi.created_at,
                    'item', json_build_object(
                        'id', oi.item_id,
                        'qty', oi.qty,
                        'price', oi.price,
                        'category_id', oi.category_id,
                        'item_name', oi.item_name,
                        'category_name', oi.category_name
                    )
                )
            ) FROM ordered_optional_items oi),
            '[]'
        ) AS proposal_optional_items
    FROM
        public.proposal p
    LEFT JOIN
        public.leads l ON l.id = p.lead_id
    LEFT JOIN
        public.company c ON c.lead_id = p.lead_id
    LEFT JOIN
        public.address a ON a.company_id = c.id
    LEFT JOIN
        public.users u ON u.id = p.created_by
    LEFT JOIN
        public.aircrafts air ON air.id = p."aircraft_id"
    LEFT JOIN
        public.aircraft_item_links ail ON ail.aircraft_id = p."aircraft_id"
    LEFT JOIN
        public.aircraft_items ai ON ai.id = ail.aircraft_item_id AND ai.item_type = 'series'
    WHERE
        p.id = p_proposal_id
    GROUP BY
        p.id, p.lead_id, p."aircraft_id", p.fullprice, p.created_at, p.created_by, p.id_ref, l.id,
        l.name, l.last_name, l.email, l.phone,
        c.id, c.company_name, c.cnpj, c.phone,
        a.id, a.zipcode, a.street, a.number, a.neighborhood, a.city, a.state, a.complement,
        u.fullname,
        air.aircraft_photo_url, air.aircraft_model, air.aircraft_year, air.aircraft_description, air.hopper;

    IF NOT FOUND THEN
        RETURN QUERY
        SELECT
            '{"id": "Não cadastrado", "lead_id": "Não cadastrado", "aircraft_id": "Não cadastrado", "fullprice": 0, "created_at": "Não cadastrado", "created_by": "Não cadastrado", "id_ref": "Não cadastrado"}'::json AS proposal,
            '{"fullname": "Não cadastrado", "email": "Não cadastrado", "phone": "Não cadastrado"}'::json AS proposal_lead,
            '{"id": "Não cadastrado", "company_name": "Não cadastrado", "cnpj": "Não cadastrado", "phone": "Não cadastrado"}'::json AS proposal_company,
            '{"id": "Não cadastrado", "zipcode": "Não cadastrado", "street": "Não cadastrado", "number": "Não cadastrado", "neighborhood": "Não cadastrado", "city": "Não cadastrado", "state": "Não cadastrado", "complement": "Não cadastrado"}'::json AS proposal_address,
            '{"aircraft_photo_url": "Não cadastrado", "aircraft_model": "Não cadastrado", "aircraft_year": "Não cadastrado", "aircraft_description": "Não cadastrado", "hopper": 0}'::json AS aircraft,
            '[]'::json AS proposal_series_items,
            '[]'::json AS proposal_optional_items;
    END IF;
END;$function$;


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

  if tg_op = 'UPDATE' and old.cancelled_at is not null
     and new.available_aircraft_id is distinct from old.available_aircraft_id then
    raise exception 'O contrato está cancelado.';
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
   where id = new.available_aircraft_id for update;
  if not found then
    raise exception 'Unidade do estoque não encontrada.' using errcode = 'P0002';
  end if;
  select p.aircraft_id into v_model from public.proposal p where p.id = new.proposal_id;
  if tg_op = 'INSERT' and v_unit.aircraft_model is distinct from v_model then
    raise exception 'A aeronave do estoque é de outro modelo que o da proposta.'
      using errcode = 'P0001';
  end if;
  if tg_op = 'UPDATE' and old.cancelled_at is not null then
    raise exception 'O contrato está cancelado.';
  end if;
  if not coalesce(v_unit.in_stock, false)
     or coalesce(lower(btrim(v_unit.status::text)), '') not in ('disponível', 'disponivel', 'em negociação', 'em negociacao')
     or not exists (select 1 from public.aircrafts a where a.id = v_unit.aircraft_model
                    and not coalesce(a.deleted, false)) then
    raise exception 'A aeronave S/N % não está disponível no estoque.', v_unit.serial_number
      using errcode = 'P0001';
  end if;
  return new;
end;
$$;

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
  c.proposal_id              as contract_proposal_id,
  array(select coalesce(nullif(p.id_ref::text, ''), p.id::text) from public.proposal p
    where p.available_aircraft_id = aa.id and p.active and not p.is_deleted and not p.is_contract
      and c.id is null
    order by p.created_at, p.id) as open_proposal_refs
from public.available_aircrafts aa
join public.aircrafts a on a.id = aa.aircraft_model
left join public.contract c
  on c.available_aircraft_id = aa.id and c.cancelled_at is null;


grant select on public.vw_stock_units to authenticated;
