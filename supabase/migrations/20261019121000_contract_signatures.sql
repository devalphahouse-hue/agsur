-- Provider-neutral approval/queue. Provider credentials exist only in Edge secrets.
create table public.contract_signature_envelopes (
 id uuid primary key, contract_id uuid not null references public.contract(id),
 provider text not null check(provider in ('clicksign','zapsign','docusign')),
 status text not null default 'draft' check(status in ('draft','queued','processing','sent','viewed','signed','declined','failed','uncertain','cancelled')),
 source_path text not null unique, source_sha256 text not null check(source_sha256 ~ '^[a-f0-9]{64}$'),
 snapshot jsonb not null, signers jsonb not null,
 provider_id text, signed_path text unique, error_code text,
 created_at timestamptz not null default now(), created_by uuid not null references public.users(id),
 approved_at timestamptz, approved_by uuid references public.users(id), updated_at timestamptz not null default now(),
 unique(provider,provider_id), check(status<>'signed' or signed_path is not null)
);
-- No duplicate live envelopes for the same commercial contract.
create unique index contract_signature_active on public.contract_signature_envelopes(contract_id)
 where status not in ('failed','declined','cancelled');
create table public.contract_signature_events (
 provider text not null, event_id text not null, envelope_id uuid not null references public.contract_signature_envelopes(id),
 event_type text not null, occurred_at timestamptz not null, received_at timestamptz not null default now(),
 signer_email text, primary key(provider,event_id)
);
create index on public.contract_signature_envelopes(status,created_at);
create function public.signature_can_read(p_contract uuid) returns boolean
language sql stable security definer set search_path=public as $$
 select auth.uid() is not null and (public.auth_is_admin_documentacao() or public.auth_owns_contract(p_contract) or
 (public.auth_is_vendedor() and exists(select 1 from public.contract c join public.proposal p on p.id=c.proposal_id
 where c.id=p_contract and p.created_by=auth.uid())))
$$;
create function public.signature_prepare(p_id uuid,p_contract uuid,p_provider text,p_source_path text,p_sha256 text,p_signers jsonb) returns uuid
language plpgsql security definer set search_path=public as $$
declare c public.contract; p public.proposal; s jsonb; prior public.contract_signature_envelopes;
begin
 if not public.auth_is_admin_documentacao() then raise exception 'Requer documentação ou Master' using errcode='42501'; end if;
 select * into strict c from public.contract where id=p_contract for update;
 if c.cancelled_at is not null then raise exception 'Contrato cancelado'; end if;
 select * into prior from public.contract_signature_envelopes where id=p_id;
 if found then
  if prior.contract_id<>p_contract or prior.provider<>p_provider or prior.source_path<>p_source_path or
   prior.source_sha256<>p_sha256 or prior.signers<>p_signers then raise exception 'Chave reutilizada com dados diferentes'; end if;
  return p_id;
 end if;
 if p_source_path<>auth.uid()::text||'/'||p_id::text||'/source.pdf' or not exists(
 select 1 from storage.objects where bucket_id='contract-signatures' and name=p_source_path) then raise exception 'PDF privado não encontrado'; end if;
 if p_signers is null or jsonb_typeof(p_signers)<>'array' or jsonb_array_length(p_signers) not between 1 and 10 then raise exception 'Defina de 1 a 10 signatários'; end if;
 for s in select value from jsonb_array_elements(p_signers) loop
  if coalesce(length(trim(s->>'name')),0) not between 1 and 160 or
   coalesce(s->>'email','') !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' or length(s->>'email')>254 then raise exception 'Signatário inválido'; end if;
 end loop;
 if (select count(distinct lower(value->>'email')) from jsonb_array_elements(p_signers))<>jsonb_array_length(p_signers) then raise exception 'Signatários duplicados'; end if;
 select * into strict p from public.proposal where id=c.proposal_id;
 insert into public.contract_signature_envelopes(id,contract_id,provider,source_path,source_sha256,snapshot,signers,created_by)
 values(p_id,p_contract,p_provider,p_source_path,p_sha256,
 jsonb_build_object('contract',jsonb_build_object('id',c.id,'proposal_id',c.proposal_id,'fullprice',c.fullprice,'client_id',c."user_Id"),
 'proposal',jsonb_build_object('id',p.id,'reference',p.id_ref),
 'aircraft',(select jsonb_build_object('id',a.id,'model',a.aircraft_model) from public.aircrafts a where a.id=p.aircraft_id),
 'unit',(select jsonb_build_object('id',u.id,'serial_number',u.serial_number,'registration_prefix',u.registration_prefix,
 'manufacture_date',u.manufacture_date,'delivery_date',u.delivery_date) from public.available_aircrafts u
 where u.id=(to_jsonb(c)->>'available_aircraft_id')::uuid)),p_signers,auth.uid());
 return p_id;
end $$;
create function public.signature_approve(p_id uuid) returns void
language plpgsql security definer set search_path=public as $$
declare e public.contract_signature_envelopes;
begin
 if not public.auth_is_admin_documentacao() then raise exception 'Requer documentação ou Master' using errcode='42501'; end if;
 select * into strict e from public.contract_signature_envelopes where id=p_id for update;
 if e.status='queued' then return; end if;
 if e.status<>'draft' then raise exception 'Envelope não está em aprovação'; end if;
 if exists(select 1 from public.contract where id=e.contract_id and cancelled_at is not null) then raise exception 'Contrato cancelado'; end if;
 update public.contract_signature_envelopes set status='queued',approved_at=now(),approved_by=auth.uid(),updated_at=now() where id=p_id;
end $$;
create function public.signature_claim() returns setof public.contract_signature_envelopes
language plpgsql security definer set search_path=public as $$
declare job public.contract_signature_envelopes;
begin
 -- Expired processing is uncertain, never automatically re-created at the provider.
 update public.contract_signature_envelopes set status='uncertain',error_code='worker_timeout',updated_at=now()
 where status='processing' and updated_at<now()-interval '10 minutes';
 select e.* into job from public.contract_signature_envelopes e where e.status='queued'
 order by e.created_at for update skip locked limit 1;
 if not found then return; end if;
 if exists(select 1 from public.contract where id=job.contract_id and cancelled_at is not null) then
  update public.contract_signature_envelopes set status='failed',error_code='contract_cancelled',updated_at=now() where id=job.id;
  return;
 end if;
 return query update public.contract_signature_envelopes set status='processing',updated_at=now() where id=job.id returning *;
end $$;
create function public.signature_dispatched(p_id uuid,p_provider_id text,p_error text default null,p_uncertain boolean default false) returns void
language plpgsql security definer set search_path=public as $$
begin
 update public.contract_signature_envelopes set
 status=case when p_uncertain then 'uncertain' when p_error is not null then 'failed' else 'sent' end,
 provider_id=nullif(p_provider_id,''),error_code=p_error,updated_at=now()
 where id=p_id and status='processing';
 if not found then raise exception 'Envelope não está em processamento'; end if;
 if p_error is null and nullif(p_provider_id,'') is null then raise exception 'Provedor não retornou identificador'; end if;
end $$;
create function public.signature_receive_event(p_provider text,p_provider_id text,p_event_id text,p_status text,
 p_occurred_at timestamptz,p_signer_email text default null,p_signed_path text default null) returns void
language plpgsql security definer set search_path=public as $$
declare e public.contract_signature_envelopes;
begin
 if p_status not in ('sent','viewed','signed','declined') or nullif(p_event_id,'') is null or p_occurred_at is null then raise exception 'Evento inválido'; end if;
 select * into strict e from public.contract_signature_envelopes where provider=p_provider and provider_id=p_provider_id for update;
 -- An event with a signature is recorded only after the private archive exists.
 if p_status='signed' and (p_signed_path is distinct from e.id::text||'/signed.pdf' or not exists(
 select 1 from storage.objects where bucket_id='contract-signatures' and name=p_signed_path)) then raise exception 'PDF assinado ainda não arquivado'; end if;
 insert into public.contract_signature_events(provider,event_id,envelope_id,event_type,occurred_at,signer_email)
 values(p_provider,p_event_id,e.id,p_status,p_occurred_at,p_signer_email) on conflict do nothing;
 if not found then return; end if;
 if e.status in ('signed','declined') then return; end if;
 if p_status='sent' and e.status='viewed' then return; end if;
 update public.contract_signature_envelopes set status=p_status,signed_path=case when p_status='signed' then p_signed_path else signed_path end,updated_at=now() where id=e.id;
end $$;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
 values('contract-signatures','contract-signatures',false,15728640,array['application/pdf']);
create policy signature_source_upload on storage.objects for insert to authenticated with check(
 bucket_id='contract-signatures' and public.auth_is_admin_documentacao() and
 name ~ ('^'||auth.uid()::text||'/[a-f0-9-]{36}/source\.pdf$'));
create policy signature_pdf_read on storage.objects for select to authenticated using(bucket_id='contract-signatures' and exists(
 select 1 from public.contract_signature_envelopes e where (e.source_path=name or e.signed_path=name) and public.signature_can_read(e.contract_id)));
alter table public.contract_signature_envelopes enable row level security;
alter table public.contract_signature_events enable row level security;
revoke all on public.contract_signature_envelopes,public.contract_signature_events from anon,authenticated;
grant select on public.contract_signature_envelopes,public.contract_signature_events to authenticated;
grant all on public.contract_signature_envelopes,public.contract_signature_events to service_role;
create policy signature_envelopes_read on public.contract_signature_envelopes for select to authenticated using(public.signature_can_read(contract_id));
create policy signature_events_read on public.contract_signature_events for select to authenticated using(exists(select 1 from public.contract_signature_envelopes e where e.id=envelope_id and public.signature_can_read(e.contract_id)));
revoke all on function public.signature_can_read(uuid),public.signature_prepare(uuid,uuid,text,text,text,jsonb),public.signature_approve(uuid),
 public.signature_claim(),public.signature_dispatched(uuid,text,text,boolean),public.signature_receive_event(text,text,text,text,timestamptz,text,text) from public,anon,authenticated;
grant execute on function public.signature_can_read(uuid),public.signature_prepare(uuid,uuid,text,text,text,jsonb),public.signature_approve(uuid) to authenticated;
grant execute on function public.signature_claim(),public.signature_dispatched(uuid,text,text,boolean),public.signature_receive_event(text,text,text,text,timestamptz,text,text) to service_role;
create trigger audit_signature_envelopes after insert or update on public.contract_signature_envelopes for each row execute function public.tg_audit_write();

create function public.signature_contract_choices(p_query text default '',p_page int default 0) returns jsonb
language plpgsql stable security definer set search_path=public as $$
begin
 if not public.auth_is_admin_documentacao() then raise exception 'Requer documentação ou Master' using errcode='42501'; end if;
 return (select coalesce(jsonb_agg(to_jsonb(x)),'[]') from (
 select c.id,p.id_ref proposal_ref,c.fullprice,u.name client_name,a.aircraft_model
 from public.contract c join public.proposal p on p.id=c.proposal_id
 left join public.users u on u.id=c."user_Id" left join public.aircrafts a on a.id=p.aircraft_id
 where c.cancelled_at is null and (p_query='' or position(lower(p_query) in lower(coalesce(p.id_ref::text,'')||' '||coalesce(u.name,'')))>0)
 order by c.created_at desc,c.id limit 25 offset greatest(0,least(p_page,100000))*25) x);
end $$;
create function public.signature_list(p_status text default 'all',p_page int default 0) returns jsonb
language plpgsql stable security definer set search_path=public as $$
begin
 if auth.uid() is null then raise exception 'Sessão necessária' using errcode='42501'; end if;
 return (with filtered as (
 select e.id,e.contract_id,e.provider,e.status,e.source_path,e.signed_path,e.created_at,e.approved_at,e.error_code,
 p.id_ref proposal_ref,u.name client_name,a.aircraft_model
 from public.contract_signature_envelopes e join public.contract c on c.id=e.contract_id
 join public.proposal p on p.id=c.proposal_id left join public.users u on u.id=c."user_Id"
 left join public.aircrafts a on a.id=p.aircraft_id
 where public.signature_can_read(e.contract_id) and (p_status='all' or e.status=p_status)),
 paged as(select * from filtered order by created_at desc,id limit 25 offset greatest(0,least(p_page,100000))*25)
 select jsonb_build_object('rows',coalesce((select jsonb_agg(to_jsonb(paged)) from paged),'[]'),'count',count(*)) from filtered);
end $$;
revoke all on function public.signature_contract_choices(text,int),public.signature_list(text,int) from public,anon;
grant execute on function public.signature_contract_choices(text,int),public.signature_list(text,int) to authenticated;

-- Corrections before dispatch keep the original PDF and audit trail intact.
create function public.signature_withdraw(p_id uuid) returns void
language plpgsql security definer set search_path=public as $$
declare e public.contract_signature_envelopes;
begin
 if not public.auth_is_admin_documentacao() then raise exception 'Requer documentação ou Master' using errcode='42501'; end if;
 select * into strict e from public.contract_signature_envelopes where id=p_id for update;
 if e.status='cancelled' then return; end if;
 if e.status not in ('draft','queued') then raise exception 'Envio iniciado: confira o contrato no serviço de assinatura'; end if;
 update public.contract_signature_envelopes set status='cancelled',updated_at=now() where id=p_id;
end $$;
revoke all on function public.signature_withdraw(uuid) from public,anon;
grant execute on function public.signature_withdraw(uuid) to authenticated;
