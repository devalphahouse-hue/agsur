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
    p.aircraft_id         as proposal_aircraft_id,
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
    left join public.aircrafts a      on a.id = p.aircraft_id
    left join public.users u          on u.id = p.created_by
    left join public.company c        on c.lead_id = p.lead_id
  where ua.deleted is not true;

alter view public.vw_all_tracking set (security_invoker = on);
