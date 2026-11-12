alter table public.contract
  add column cancellation_follow_up_at timestamptz,
  add column cancellation_follow_up_done_at timestamptz;

alter table public.tracking add column due_on date;
alter table public.leads add column waiting_until date, add column waiting_reason text;

create function public.set_lead_waiting(
  p_lead_id uuid, p_due_on date default null, p_reason text default null
) returns boolean language plpgsql security invoker set search_path = '' as $$
begin
  if p_due_on is not null and (nullif(btrim(p_reason), '') is null
      or char_length(p_reason) > 500) then
    raise exception 'Informe o motivo da pendência em até 500 caracteres.';
  end if;
  update public.leads set waiting_until = p_due_on,
    waiting_reason = case when p_due_on is not null then btrim(p_reason) end
  where id = p_lead_id and active and not is_deleted
    and (public.auth_is_admin_documentacao()
      or (public.auth_is_vendedor() and coalesce(seller_id, created_by) = auth.uid()));
  return found;
end;
$$;
revoke all on function public.set_lead_waiting(uuid,date,text) from public, anon;
grant execute on function public.set_lead_waiting(uuid,date,text) to authenticated;

create or replace view public.vw_contract_data as
  SELECT p.id,
      p.id_ref,
      p.lead_id,
      coalesce(unit.aircraft_model, p.aircraft_id) as aircraft_id,
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
      cu.name                AS cancelled_by_name,
      ct.cancellation_follow_up_at,
      ct.cancellation_follow_up_done_at
     FROM proposal p
       LEFT JOIN company c ON c.lead_id = p.lead_id
       LEFT JOIN users u ON u.id = p.created_by
       LEFT JOIN contract ct ON ct.proposal_id = p.id
       LEFT JOIN available_aircrafts unit ON unit.id = ct.available_aircraft_id
       JOIN aircrafts a ON a.id = coalesce(unit.aircraft_model, p.aircraft_id)
       LEFT JOIN users cu ON cu.id = ct.cancelled_by
    WHERE p.active = true AND p.is_deleted = false AND p.is_contract = true
    ORDER BY p.created_at DESC;
grant select on public.vw_contract_data to authenticated;


create function public.cancel_contract_with_follow_up(
  p_contract_id uuid, p_reason text, p_note text,
  p_follow_up_at timestamptz default null, p_whatsapp_consent boolean default false
) returns void language plpgsql security invoker set search_path = '' as $$
declare
  agreement public.contract;
  related public.proposal;
  seller uuid;
begin
  if not public.auth_is_admin_documentacao() then
    raise exception 'Somente administradores podem cancelar contratos.' using errcode = '42501';
  end if;
  select * into agreement from public.contract where id = p_contract_id for update;
  if not found then raise exception 'Contrato indisponível.'; end if;
  if agreement.cancelled_at is not null then return; end if;
  if nullif(btrim(p_reason), '') is null or
      (p_reason = 'outro' and nullif(btrim(p_note), '') is null) then
    raise exception 'Informe o motivo e descreva o cancelamento quando necessário.';
  end if;
  if p_follow_up_at <= now() or (p_whatsapp_consent and p_follow_up_at is null) then
    raise exception 'Escolha uma data e horário futuros para o contato.';
  end if;
  select * into strict related from public.proposal where id = agreement.proposal_id;

  if p_whatsapp_consent then
    select r.id into seller
    from public.whatsapp_reminder_recipients(related.lead_id, 'vendedor') r
    where public.phone_to_e164(r.phone) is not null;
    if seller is null then
      raise exception 'O vendedor responsável precisa ter telefone válido para receber o WhatsApp.';
    end if;
    perform public.create_lead_note(
      related.lead_id,
      format('Retomar contato com o cliente referente ao contrato %s.', coalesce(related.id_ref::text, related.id::text)),
      jsonb_build_object(
        'subject', 'Retomada de contato',
        'recipient_type', 'vendedor',
        'recipient_ids', jsonb_build_array(seller),
        'scheduled_at', p_follow_up_at,
        'consent', true
      )
    );
  end if;

  update public.contract set
    cancelled_at = now(),
    cancelled_by = auth.uid(),
    cancellation_reason = p_reason,
    cancellation_note = nullif(btrim(p_note), ''),
    cancellation_follow_up_at = p_follow_up_at
  where id = p_contract_id;
  if not found then
    raise exception 'Sem permissão para cancelar este contrato.' using errcode = '42501';
  end if;
end;
$$;

create function public.complete_contract_follow_up(p_contract_id uuid)
returns boolean language plpgsql security definer set search_path = '' as $$
begin
  update public.contract c set cancellation_follow_up_done_at = now()
    from public.proposal p left join public.leads l on l.id = p.lead_id
  where c.id = p_contract_id and c.proposal_id = p.id
    and c.cancelled_at is not null and c.cancellation_follow_up_at <= now()
    and c.cancellation_follow_up_done_at is null
    and (public.auth_is_admin_documentacao() or
      (public.auth_is_vendedor() and coalesce(l.seller_id, p.created_by) = auth.uid()));
  return found;
end;
$$;

-- Completing the callback is the only seller-side change to a canceled contract.
-- This guard runs before the operational contract guard and uses the same scope.
drop trigger contract_admin_changes on public.contract;
create function public.guard_contract_changes()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if public.auth_is_service_request() or public.auth_is_admin_documentacao() then
    return coalesce(new, old);
  end if;
  if tg_op = 'UPDATE'
     and old.cancelled_at is not null
     and old.cancellation_follow_up_at <= now()
     and old.cancellation_follow_up_done_at is null
     and new.cancellation_follow_up_done_at is not null
     and (to_jsonb(new) - 'cancellation_follow_up_done_at') =
         (to_jsonb(old) - 'cancellation_follow_up_done_at')
     and public.auth_is_vendedor()
     and exists (
       select 1 from public.proposal p left join public.leads l on l.id = p.lead_id
       where p.id = old.proposal_id and coalesce(l.seller_id, p.created_by) = auth.uid()
     ) then
    return new;
  end if;
  raise exception 'Solicite a alteração do contrato a um administrador.' using errcode = '42501';
end;
$$;
create trigger contract_admin_changes before insert or update or delete on public.contract
  for each row execute function public.guard_contract_changes();

create table public.contract_change_requests (
  id uuid primary key default gen_random_uuid(),
  contract_id uuid not null references public.contract(id),
  requested_by uuid not null references public.users(id),
  description text not null check (char_length(btrim(description)) between 1 and 1000),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid references public.users(id)
);
create index contract_change_requests_open on public.contract_change_requests(created_at)
  where resolved_at is null;
alter table public.contract_change_requests enable row level security;
revoke all on public.contract_change_requests from public, anon, authenticated;
grant select on public.contract_change_requests to authenticated;
create policy contract_change_requests_read on public.contract_change_requests
  for select to authenticated using (
    public.auth_is_admin_documentacao() or requested_by = auth.uid()
  );

create function public.request_contract_change(p_contract_id uuid, p_description text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  request_id uuid;
begin
  if not public.auth_is_vendedor() or not exists (
    select 1 from public.contract c
    join public.proposal p on p.id = c.proposal_id
    left join public.leads l on l.id = p.lead_id
    where c.id = p_contract_id and c.cancelled_at is null
      and (p.created_by = auth.uid() or l.seller_id = auth.uid())
  ) then
    raise exception 'Contrato indisponível para solicitação.' using errcode = '42501';
  end if;
  insert into public.contract_change_requests(contract_id, requested_by, description)
    values (p_contract_id, auth.uid(), btrim(p_description)) returning id into request_id;
  return request_id;
end;
$$;

create function public.resolve_contract_change(p_request_id uuid)
returns boolean language plpgsql security definer set search_path = '' as $$
begin
  if not public.auth_is_admin_documentacao() then
    raise exception 'A resolução exige perfil administrativo.' using errcode = '42501';
  end if;
  update public.contract_change_requests
  set resolved_at = now(), resolved_by = auth.uid()
  where id = p_request_id and resolved_at is null;
  return found;
end;
$$;
revoke all on function public.request_contract_change(uuid, text),
  public.resolve_contract_change(uuid) from public, anon;
grant execute on function public.request_contract_change(uuid, text),
  public.resolve_contract_change(uuid) to authenticated;

-- Choose the current stage from the actual sequence, respecting cash sales.
-- The same feed drives the bell and the notification panel.
create function public.operational_notifications(p_limit integer default 100)
returns table(
  kind text, record_id uuid, proposal_id uuid, title text, subtitle text,
  detail text, due_at timestamptz, due_on date, total_count bigint
)
language sql stable security invoker set search_path = '' as $$
  with deals as (
    select p.id, p.aircraft_id, p.id_ref, p.lead_id, p.created_by,
           coalesce(nullif(l.fullname, ''), nullif(l.name, ''), 'Cliente') as client,
           coalesce(l.seller_id, p.created_by) as seller
    from public.proposal p left join public.leads l on l.id = p.lead_id
    where p.active and not p.is_deleted
      and (public.auth_is_admin_documentacao() or
        (public.auth_is_vendedor() and coalesce(l.seller_id, p.created_by) = auth.uid()))
  ), alerts as (
    select 'tracking'::text as kind, ua.id as record_id, p.id as proposal_id,
      coalesce(a.aircraft_model::text, 'Aeronave') as title, p.client::text as subtitle,
      case when current_stage."order" in (16, 18)
        then 'Documentação pendente: ' || current_stage.tracking_description
        else 'Em andamento: ' || current_stage.tracking_description end as detail,
      (current_stage.due_on + 1)::timestamp at time zone 'America/Sao_Paulo' as due_at,
      current_stage.due_on
    from deals p
    join public.user_aircraft ua on ua.proposal_id = p.id and not coalesce(ua.deleted, false)
    left join lateral (
      select c.cancelled_at, c.available_aircraft_id
      from public.contract c where c.id = ua.contract_id
        or (ua.contract_id is null and c.proposal_id = p.id)
      order by (c.cancelled_at is null) desc, c.created_at desc limit 1
    ) agreement on true
    left join public.available_aircrafts unit on unit.id = agreement.available_aircraft_id
    left join public.aircrafts a on a.id = coalesce(unit.aircraft_model, p.aircraft_id)
    left join lateral (
      select btrim(d.payment_method::text) as method
      from public.tracking t join public.tracking_details d on d.tracking_id = t.id
      where t.user_aircraft = ua.id and t."order" = 9 limit 1
    ) payment on true
    join lateral (
      select t."order", t.tracking_description, t.due_on
      from public.tracking t where t.user_aircraft = ua.id and not coalesce(t."isCheck", false)
        and (payment.method is distinct from 'vista' or t."order" not in (10, 11, 17))
      order by t."order", t.id limit 1
    ) current_stage on true
    where agreement.cancelled_at is null
    union all
    select 'follow_up', c.id, p.id,
      ('Retomar contato · #' || coalesce(p.id_ref::text, p.id::text)), p.client,
      'Contato programado após cancelamento.', c.cancellation_follow_up_at, null::date
    from deals p join public.contract c on c.proposal_id = p.id
    where c.cancelled_at is not null and c.cancellation_follow_up_at <= now()
      and c.cancellation_follow_up_done_at is null and p.seller = auth.uid()
    union all
    select 'contract_change', r.id, p.id,
      ('Alteração de contrato · #' || coalesce(p.id_ref::text, p.id::text)), p.client,
      r.description, null::timestamptz, null::date
    from deals p join public.contract c on c.proposal_id = p.id
    join public.contract_change_requests r on r.contract_id = c.id
    where public.auth_is_admin_documentacao() and r.resolved_at is null
    union all
    select 'client_waiting', l.id, null::uuid, 'Cliente aguardando',
      coalesce(nullif(l.fullname, ''), nullif(l.name, ''), 'Cliente')::text,
      coalesce(l.waiting_reason, 'Aguardando retorno.'),
      (l.waiting_until + 1)::timestamp at time zone 'America/Sao_Paulo', l.waiting_until
    from public.leads l
    where l.waiting_until is not null and l.active and not l.is_deleted
      and (public.auth_is_admin_documentacao() or
        (public.auth_is_vendedor() and coalesce(l.seller_id, l.created_by) = auth.uid()))
  )
  select alerts.*, count(*) over () from alerts
  order by (due_at <= now()) desc nulls last, due_at asc nulls last, title, record_id
  limit least(greatest(coalesce(p_limit, 100), 1), 500);
$$;

revoke all on function public.cancel_contract_with_follow_up(uuid,text,text,timestamptz,boolean),
  public.complete_contract_follow_up(uuid), public.operational_notifications(integer) from public, anon;
grant execute on function public.cancel_contract_with_follow_up(uuid,text,text,timestamptz,boolean),
  public.complete_contract_follow_up(uuid), public.operational_notifications(integer) to authenticated;

create or replace view public.vw_all_tracking as
  select
    t.id,
    t.user_aircraft,
    t.tracking_description,
    t."isCheck",
    t.created_at,
    t."order",
    t.link,
    ua.id                 as user_aircraft_id,
    ua.proposal_id        as user_aircraft_proposal_id,
    ua.aircraft_status    as user_aircraft_status,
    ua.created_at         as user_aircraft_created_at,
    p.id                  as proposal_id,
    p.lead_id             as proposal_lead_id,
    coalesce(unit.aircraft_model, p.aircraft_id) as proposal_aircraft_id,
    p.id_ref              as proposal_id_ref,
    p.created_by          as proposal_created_by,
    a.aircraft_model,
    a.aircraft_year,
    u.fullname            as created_by_fullname,
    c.company_name,
    (select count(*) from public.tracking tk
       where tk.user_aircraft = ua.id and tk."isCheck" = true)  as completed_steps,
    (select count(*) from public.tracking tk
       where tk.user_aircraft = ua.id)                          as total_steps,
    (select tk.tracking_description from public.tracking tk
       where tk.user_aircraft = ua.id and tk."isCheck" = false
       order by tk."order"
       limit 1)                                                 as next_step
  from (
        select distinct on (tracking.user_aircraft)
            tracking.id,
            tracking.user_aircraft,
            tracking.tracking_description,
            tracking."isCheck",
            tracking.created_at,
            tracking."order",
            tracking.link
          from public.tracking
         order by tracking.user_aircraft, tracking.created_at
       ) t
    left join public.user_aircraft ua on ua.id = t.user_aircraft
    left join public.proposal p       on p.id = ua.proposal_id
    left join public.contract ct      on ct.id = ua.contract_id
    left join public.available_aircrafts unit on unit.id = ct.available_aircraft_id
    left join public.aircrafts a      on a.id = coalesce(unit.aircraft_model, p.aircraft_id)
    left join public.users u          on u.id = p.created_by
    left join public.company c        on c.lead_id = p.lead_id
  where ua.deleted is not true;

alter view public.vw_all_tracking set (security_invoker = on);

create or replace view public.vw_my_aircraft_details as  SELECT a.id AS aircraft_id,
    a.aircraft_photo_url,
    a.aircraft_model AS name,
    a.aircraft_description,
    a.hopper,
    a.price,
    COALESCE(json_agg(DISTINCT jsonb_build_object('id', da.id, 'documention_name', 'Manual de voo', 'documention_url', COALESCE(da.documention_url, 'Não cadastrado'::text))) FILTER (WHERE da.type = 'Manual de voo'::text AND da.deleted = false AND da.id IS NOT NULL), '[]'::json) AS flight_manuals,
    COALESCE(json_agg(DISTINCT jsonb_build_object('id', da.id, 'documention_name', 'Manual do proprietário', 'documention_url', COALESCE(da.documention_url, 'Não cadastrado'::text))) FILTER (WHERE da.type = 'Manual do proprietário'::text AND da.deleted = false AND da.id IS NOT NULL), '[]'::json) AS owner_manuals,
    COALESCE(json_agg(DISTINCT jsonb_build_object('id', da.id, 'documention_name', 'Manual de peças', 'documention_url', COALESCE(da.documention_url, 'Não cadastrado'::text))) FILTER (WHERE da.type = 'Manual de peças'::text AND da.deleted = false AND da.id IS NOT NULL), '[]'::json) AS parts_manuals,
    COALESCE(json_agg(DISTINCT jsonb_build_object('id', ai.id, 'item_name', COALESCE(ai.item_name, 'Não cadastrado'::text), 'qty', COALESCE(ai.qty::text, 'Não cadastrado'::text), 'price', COALESCE(ai.price::text, 'Não cadastrado'::text))) FILTER (WHERE ai.item_type::text = 'series' AND ai.deleted = false AND ai.active = true AND ai.id IS NOT NULL), '[]'::json) AS items_series,
    ua.id AS user_aircraft_id
   FROM user_aircraft ua
     JOIN contract c ON ua.contract_id = c.id
     JOIN proposal p ON c.proposal_id = p.id
     LEFT JOIN available_aircrafts unit ON unit.id = c.available_aircraft_id
     JOIN aircrafts a ON coalesce(unit.aircraft_model, p.aircraft_id) = a.id
     LEFT JOIN aircraft_manuals da ON da.aircraft_id = a.id
     LEFT JOIN aircraft_item_links model_item ON model_item.aircraft_id = a.id
     LEFT JOIN aircraft_items ai ON ai.id = model_item.aircraft_item_id AND ai.item_type::text = 'series' AND ai.active = true AND ai.deleted = false
  WHERE ua.deleted = false AND (auth_is_seller_or_admin() OR auth_owns_user_aircraft(ua.id) OR auth_is_linked_to_user_aircraft(ua.id))
  GROUP BY ua.id, a.id, a.aircraft_photo_url, a.aircraft_model, a.aircraft_description, a.hopper, a.price;
create or replace view public.vw_my_aircrafts_home as  SELECT ua.id AS user_aircraft_id,
    c."user_Id" AS user_id,
    a.aircraft_photo_url,
    a.aircraft_model AS name,
    a.hopper,
    a.price
   FROM user_aircraft ua
     JOIN contract c ON ua.contract_id = c.id
     JOIN proposal p ON c.proposal_id = p.id
     LEFT JOIN available_aircrafts unit ON unit.id = c.available_aircraft_id
     JOIN aircrafts a ON coalesce(unit.aircraft_model, p.aircraft_id) = a.id
  WHERE ua.deleted = false AND (auth_is_seller_or_admin() OR auth_owns_user_aircraft(ua.id) OR auth_is_linked_to_user_aircraft(ua.id));
