-- Sprint 2. Immutable rule versions and per-sale snapshots; no historical recalculation.
create table public.commission_rules (
 id uuid primary key default gen_random_uuid(),
 label text not null check(length(trim(label)) between 1 and 120),
 effective_at timestamptz not null unique,
 currency text not null default 'USD' check(currency = 'USD'),
 company_rate numeric(8,6) not null check(company_rate between 0 and 1),
 seller_fixed numeric(16,2) not null check(seller_fixed >= 0 and seller_fixed <> 'NaN'::numeric),
 seller_rate numeric(8,6) not null default 0 check(seller_rate between 0 and 1),
 referral_fixed numeric(16,2) not null check(referral_fixed >= 0 and referral_fixed <> 'NaN'::numeric),
 -- Highest qualifying tier wins; thresholds are contract price and monthly company sales.
 tiers jsonb not null default '[]' check(jsonb_typeof(tiers) = 'array'),
 created_at timestamptz not null default now(), created_by uuid references public.users(id)
);
insert into public.commission_rules(label,effective_at,company_rate,seller_fixed,referral_fixed)
 values('Regra original AGSur', '2000-01-01Z', .02, 7500, 3000);

create table public.sale_commission_snapshots (
 sale_id uuid primary key references public.sales(id), rule_id uuid references public.commission_rules(id),
 currency text not null default 'USD' check(currency='USD'),
 company_amount numeric(16,2) not null check(company_amount>=0),
 seller_pool numeric(16,2) not null check(seller_pool>=0),
 referral_pool numeric(16,2) not null check(referral_pool>=0),
 calculation jsonb not null, created_at timestamptz not null default now()
);
-- Preserve the actual stored amounts. Unknown historic referral allocation stays zero.
insert into public.sale_commission_snapshots(sale_id,company_amount,seller_pool,referral_pool,calculation)
 select id,round(company_commission::numeric,2),round(seller_commission::numeric,2),0,
 jsonb_build_object('legacy',true,'fullprice',fullprice) from public.sales;

create table public.commission_allocations (
 id uuid primary key, sale_id uuid not null references public.sale_commission_snapshots(sale_id),
 beneficiary_id uuid references public.users(id), external_name text,
 bucket text not null check(bucket in ('seller','referral')),
 gross numeric(16,2) not null check(gross>0 and gross <> 'NaN'::numeric),
 deduction numeric(16,2) not null default 0 check(deduction>=0 and deduction<gross),
 deduction_reason text, net numeric(16,2) generated always as (gross-deduction) stored,
 created_at timestamptz not null default now(), created_by uuid not null references public.users(id),
 check((beneficiary_id is not null and external_name is null) or
       (beneficiary_id is null and external_name is not null and length(trim(external_name)) between 1 and 160)),
 check(deduction=0 or (deduction_reason is not null and length(trim(deduction_reason)) between 1 and 300))
);
create unique index commission_beneficiary_once on public.commission_allocations(sale_id,bucket,beneficiary_id) where beneficiary_id is not null;
create unique index commission_external_once on public.commission_allocations(sale_id,bucket,lower(external_name)) where external_name is not null;
create table public.commission_payments (
 id uuid primary key, allocation_id uuid not null unique references public.commission_allocations(id),
 reference text not null check(length(trim(reference)) between 1 and 160),
 paid_at timestamptz not null default now(), recorded_by uuid not null references public.users(id)
);
create index on public.commission_allocations(beneficiary_id,created_at desc);
create index on public.commission_allocations(sale_id,bucket);

create function public.commission_freeze_sale() returns trigger
language plpgsql security definer set search_path=public as $$
declare r public.commission_rules; lead_referral boolean; pool numeric; referral numeric;
 tier jsonb; chosen jsonb; monthly_count int; sale_price numeric;
begin
 if TG_OP='UPDATE' then
  if new.seller_commission is distinct from old.seller_commission or
     new.company_commission is distinct from old.company_commission then
   raise exception 'Comissão congelada na conversão' using errcode='23514';
  end if;
  return new;
 end if;
 -- Serialize monthly targets so simultaneous conversions cannot use the same count.
 perform pg_advisory_xact_lock(hashtext('commission:'||to_char(now() at time zone 'UTC','YYYY-MM')));
 new.created_at := now();
 sale_price := round(new.fullprice::numeric,2);
 if sale_price is null or sale_price<0 or sale_price='NaN'::numeric then
  raise exception 'Preço inválido' using errcode='23514';
 end if;
 select * into strict r from public.commission_rules where effective_at<=now() order by effective_at desc limit 1;
 select coalesce(l.is_referral,false) into lead_referral from public.proposal p
 join public.leads l on l.id=p.lead_id where p.id=new.proposal_id;
 select count(*)+1 into monthly_count from public.sales where
 created_at >= date_trunc('month',now() at time zone 'UTC') at time zone 'UTC';
 pool := r.seller_fixed + sale_price*r.seller_rate;
 for tier in select value from jsonb_array_elements(r.tiers) order by
 (value->>'min_price')::numeric, (value->>'min_sales')::int loop
  if sale_price >= (tier->>'min_price')::numeric and monthly_count >= (tier->>'min_sales')::int then
   pool := (tier->>'fixed')::numeric+sale_price*(tier->>'rate')::numeric; chosen:=tier;
  end if;
 end loop;
 pool:=round(pool,2);
 referral:=case when coalesce(lead_referral,false) then r.referral_fixed else 0 end;
 if referral>pool then raise exception 'Indicação excede o bolo da comissão'; end if;
 new.seller_commission:=pool-referral; new.company_commission:=round(sale_price*r.company_rate,2);
 return new;
end $$;
create function public.commission_snapshot_sale() returns trigger
language plpgsql security definer set search_path=public as $$
declare r public.commission_rules; referred boolean;
begin
 select * into strict r from public.commission_rules where effective_at<=new.created_at order by effective_at desc limit 1;
 select coalesce(l.is_referral,false) into referred from public.proposal p join public.leads l on l.id=p.lead_id where p.id=new.proposal_id;
 insert into public.sale_commission_snapshots(sale_id,rule_id,company_amount,seller_pool,referral_pool,calculation)
 values(new.id,r.id,new.company_commission,new.seller_commission,
 case when coalesce(referred,false) then r.referral_fixed else 0 end,
 jsonb_build_object('fullprice',new.fullprice,'rule',to_jsonb(r),'is_referral',coalesce(referred,false)));
 return new;
end $$;
create trigger commission_freeze_sale before insert or update on public.sales for each row execute function public.commission_freeze_sale();
create trigger commission_snapshot_sale after insert on public.sales for each row execute function public.commission_snapshot_sale();

create function public.commission_create_rule(p_label text,p_effective_at timestamptz,p_company_rate numeric,
 p_seller_fixed numeric,p_seller_rate numeric,p_referral_fixed numeric,p_tiers jsonb default '[]') returns uuid
language plpgsql security definer set search_path=public as $$
declare result uuid; t jsonb;
begin
 if not public.auth_is_admin_master() then raise exception 'Somente Admin Master' using errcode='42501'; end if;
 if p_effective_at is null or p_effective_at<=now() then raise exception 'A vigência deve ser futura'; end if;
 if p_tiers is null or jsonb_typeof(p_tiers)<>'array' or jsonb_array_length(p_tiers)>50 then raise exception 'Faixas inválidas'; end if;
 for t in select value from jsonb_array_elements(p_tiers) loop
  if not (t ?& array['min_price','min_sales','fixed','rate']) or
   (t->>'min_price')::numeric not between 0 and 999999999999.99 or (t->>'min_sales')::int<1 or
   (t->>'min_price')::numeric='NaN'::numeric or (t->>'fixed')::numeric='NaN'::numeric or (t->>'fixed')::numeric not between 0 and 999999999999.99 or (t->>'rate')::numeric not between 0 and 1 or
   t->>'min_price' is null or t->>'min_sales' is null or t->>'fixed' is null or t->>'rate' is null then
   raise exception 'Faixa inválida';
  end if;
 end loop;
 insert into public.commission_rules(label,effective_at,company_rate,seller_fixed,seller_rate,referral_fixed,tiers,created_by)
 values(p_label,p_effective_at,p_company_rate,p_seller_fixed,p_seller_rate,p_referral_fixed,p_tiers,auth.uid()) returning id into result;
 return result;
end $$;
create function public.commission_allocate(p_id uuid,p_sale_id uuid,p_beneficiary_id uuid,p_external_name text,
 p_bucket text,p_gross numeric,p_deduction numeric default 0,p_reason text default null) returns uuid
language plpgsql security definer set search_path=public as $$
declare s public.sale_commission_snapshots; prior public.commission_allocations; used numeric; budget numeric;
begin
 if not public.auth_is_admin_master() then raise exception 'Somente Admin Master' using errcode='42501'; end if;
 select * into strict s from public.sale_commission_snapshots where sale_id=p_sale_id for update;
 select * into prior from public.commission_allocations where id=p_id;
 if found then
  if prior.sale_id is distinct from p_sale_id or prior.beneficiary_id is distinct from p_beneficiary_id or
   prior.external_name is distinct from nullif(trim(p_external_name),'') or prior.bucket is distinct from p_bucket or
   prior.gross is distinct from round(p_gross,2) or prior.deduction is distinct from round(p_deduction,2) or
   prior.deduction_reason is distinct from nullif(trim(p_reason),'') then raise exception 'Chave de rateio reutilizada com dados diferentes'; end if;
  return p_id;
 end if;
 if p_beneficiary_id is not null and not exists(select 1 from public.users where id=p_beneficiary_id
 and profile_type::text in ('Vendedor','Admin Master') and is_active and not is_deleted) then raise exception 'Beneficiário inválido'; end if;
 budget:=case p_bucket when 'seller' then s.seller_pool when 'referral' then s.referral_pool end;
 select coalesce(sum(gross),0) into used from public.commission_allocations where sale_id=p_sale_id and bucket=p_bucket;
 if budget is null or p_gross is null or round(p_gross,2)+used>budget then raise exception 'Rateio excede o saldo da venda'; end if;
 insert into public.commission_allocations(id,sale_id,beneficiary_id,external_name,bucket,gross,deduction,deduction_reason,created_by)
 values(p_id,p_sale_id,p_beneficiary_id,nullif(trim(p_external_name),''),p_bucket,round(p_gross,2),round(p_deduction,2),nullif(trim(p_reason),''),auth.uid());
 return p_id;
end $$;
create function public.commission_settle(p_id uuid,p_allocation_id uuid,p_reference text) returns uuid
language plpgsql security definer set search_path=public as $$
declare prior public.commission_payments;
begin
 if not public.auth_is_admin_master() then raise exception 'Somente Admin Master' using errcode='42501'; end if;
 perform 1 from public.commission_allocations where id=p_allocation_id for update;
 if not found then raise exception 'Rateio não encontrado'; end if;
 select * into prior from public.commission_payments where allocation_id=p_allocation_id or id=p_id;
 if found then
  if prior.id<>p_id or prior.allocation_id<>p_allocation_id or prior.reference<>trim(p_reference) then raise exception 'Pagamento já registrado ou chave reutilizada'; end if;
  return prior.id;
 end if;
 insert into public.commission_payments(id,allocation_id,reference,recorded_by) values(p_id,p_allocation_id,trim(p_reference),auth.uid());
 return p_id;
end $$;

alter table public.commission_rules enable row level security;
alter table public.sale_commission_snapshots enable row level security;
alter table public.commission_allocations enable row level security;
alter table public.commission_payments enable row level security;
revoke all on public.commission_rules,public.sale_commission_snapshots,public.commission_allocations,public.commission_payments from anon,authenticated;
grant select on public.commission_rules,public.sale_commission_snapshots,public.commission_allocations,public.commission_payments to authenticated;
create policy rules_read on public.commission_rules for select to authenticated using(public.auth_is_admin_master());
create policy snapshots_read on public.sale_commission_snapshots for select to authenticated using(public.auth_is_admin_master());
create policy allocations_read on public.commission_allocations for select to authenticated using(public.auth_is_admin_master() or beneficiary_id=auth.uid());
create policy payments_read on public.commission_payments for select to authenticated using(public.auth_is_admin_master() or exists(select 1 from public.commission_allocations a where a.id=allocation_id and a.beneficiary_id=auth.uid()));
-- Append-only tables: writes are exposed only through checked RPCs, not direct grants.
revoke all on function public.commission_freeze_sale(),public.commission_snapshot_sale() from public,anon,authenticated;
revoke all on function public.commission_create_rule(text,timestamptz,numeric,numeric,numeric,numeric,jsonb),
 public.commission_allocate(uuid,uuid,uuid,text,text,numeric,numeric,text),public.commission_settle(uuid,uuid,text) from public,anon;
grant execute on function public.commission_create_rule(text,timestamptz,numeric,numeric,numeric,numeric,jsonb),
 public.commission_allocate(uuid,uuid,uuid,text,text,numeric,numeric,text),public.commission_settle(uuid,uuid,text) to authenticated;

create function public.commission_statement(p_from timestamptz,p_until timestamptz,
 p_status text default 'all',p_beneficiary uuid default null,p_page int default 0)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare result jsonb;
begin
 if auth.uid() is null or not (public.auth_is_admin_master() or public.auth_is_vendedor()) then raise exception 'Sem acesso ao extrato' using errcode='42501'; end if;
 if not public.auth_is_admin_master() and p_beneficiary is not null and p_beneficiary<>auth.uid() then raise exception 'Extrato de outro vendedor' using errcode='42501'; end if;
 if p_status not in ('all','due','paid') or p_from is null or p_until is null or p_until<=p_from or p_page<0 then raise exception 'Filtro inválido'; end if;
 with filtered as (
 select a.*,coalesce(u.name,a.external_name) beneficiary_name,s.currency,p.id payment_id,p.paid_at,p.reference
 from public.commission_allocations a join public.sale_commission_snapshots s on s.sale_id=a.sale_id
 left join public.users u on u.id=a.beneficiary_id left join public.commission_payments p on p.allocation_id=a.id
 where a.created_at>=p_from and a.created_at<p_until
 and (public.auth_is_admin_master() or a.beneficiary_id=auth.uid())
 and (p_beneficiary is null or a.beneficiary_id=p_beneficiary)
 and (p_status='all' or (p_status='paid' and p.id is not null) or (p_status='due' and p.id is null))
 ), paged as(select * from filtered order by created_at desc,id limit 25 offset least(p_page,100000)*25)
 select jsonb_build_object('rows',coalesce((select jsonb_agg(to_jsonb(paged)) from paged),'[]'),
 'count',count(*),'gross',coalesce(sum(gross),0),'deductions',coalesce(sum(deduction),0),
 'provisioned',coalesce(sum(net),0),'due',coalesce(sum(net) filter(where payment_id is null),0),
 'paid',coalesce(sum(net) filter(where payment_id is not null),0)) into result from filtered;
 return result;
end $$;
create function public.commission_sale_balances(p_page int default 0) returns jsonb
language plpgsql stable security definer set search_path=public as $$
declare result jsonb;
begin
 if not public.auth_is_admin_master() then raise exception 'Somente Admin Master' using errcode='42501'; end if;
 select coalesce(jsonb_agg(to_jsonb(x)),'[]') into result from (
 select s.*,p.id_ref proposal_ref,
 s.seller_pool-coalesce((select sum(a.gross) from public.commission_allocations a where a.sale_id=s.sale_id and bucket='seller'),0) seller_available,
 s.referral_pool-coalesce((select sum(a.gross) from public.commission_allocations a where a.sale_id=s.sale_id and bucket='referral'),0) referral_available
 from public.sale_commission_snapshots s join public.sales sale on sale.id=s.sale_id join public.proposal p on p.id=sale.proposal_id
 order by s.created_at desc,s.sale_id limit 25 offset greatest(0,least(p_page,100000))*25) x;
 return result;
end $$;
create function public.commission_beneficiaries() returns jsonb
language plpgsql stable security definer set search_path=public as $$
begin
 if not public.auth_is_admin_master() then raise exception 'Somente Admin Master' using errcode='42501'; end if;
 return (select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name) order by name),'[]') from public.users
 where profile_type::text in ('Vendedor','Admin Master') and is_active and not is_deleted);
end $$;
revoke all on function public.commission_statement(timestamptz,timestamptz,text,uuid,int),public.commission_sale_balances(int),public.commission_beneficiaries() from public,anon;
grant execute on function public.commission_statement(timestamptz,timestamptz,text,uuid,int),public.commission_sale_balances(int),public.commission_beneficiaries() to authenticated;
create trigger audit_commission_rules after insert on public.commission_rules for each row execute function public.tg_audit_write();
create trigger audit_commission_allocations after insert on public.commission_allocations for each row execute function public.tg_audit_write();
create trigger audit_commission_payments after insert on public.commission_payments for each row execute function public.tg_audit_write();
