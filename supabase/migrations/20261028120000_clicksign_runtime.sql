-- Durable provider IDs and a signed-webhook inbox. No provider credentials in SQL.
alter table public.contract_signature_envelopes
 add column provider_environment text check(provider_environment in ('sandbox','production')),
 add column provider_document_id text,
 add column worker_claim uuid,
 add column provider_closed boolean not null default false;
create unique index signature_clicksign_document on public.contract_signature_envelopes(provider_environment,provider_document_id)
 where provider='clicksign' and provider_document_id is not null;

create table public.signature_webhook_inbox (
 id text primary key check(length(id)=64), envelope_id uuid not null references public.contract_signature_envelopes(id),
 event_name text not null check(event_name in ('sign','signature_started','refusal','auto_close','close','document_closed','cancel','deadline')),
 occurred_at timestamptz not null, signer_email text,
 received_at timestamptz not null default now(), next_attempt_at timestamptz not null default now(),
 attempts int not null default 0, claimed_at timestamptz, claim_token uuid, completed_at timestamptz, error_code text
);
alter table public.signature_webhook_inbox enable row level security;
revoke all on public.signature_webhook_inbox from public,anon,authenticated;
grant all on public.signature_webhook_inbox to service_role;
create index signature_inbox_due on public.signature_webhook_inbox(next_attempt_at) where completed_at is null;

create function public.signature_claim_clicksign(p_environment text)
returns setof public.contract_signature_envelopes language plpgsql security definer set search_path=public as $$
declare e public.contract_signature_envelopes;
begin
 if p_environment is null or p_environment not in ('sandbox','production') then raise exception 'Ambiente inválido'; end if;
 update public.contract_signature_envelopes set status='uncertain',error_code='worker_timeout',updated_at=now()
 where provider='clicksign' and status='processing' and updated_at<now()-interval '10 minutes';
 select x.* into e from public.contract_signature_envelopes x where x.provider='clicksign' and x.status='queued'
 and (x.provider_environment is null or x.provider_environment=p_environment)
 order by x.created_at for update skip locked limit 1;
 if not found then return; end if;
 if exists(select 1 from public.contract where id=e.contract_id and cancelled_at is not null) then
  update public.contract_signature_envelopes set status='failed',error_code='contract_cancelled',updated_at=now() where id=e.id;
  return;
 end if;
 return query update public.contract_signature_envelopes set status='processing',provider_environment=p_environment,
 worker_claim=gen_random_uuid(),updated_at=now() where id=e.id returning *;
end $$;

create function public.signature_checkpoint_clicksign(p_id uuid,p_claim uuid,p_remote text,p_document text default null)
returns void language plpgsql security definer set search_path=public as $$
begin
 if nullif(p_remote,'') is null then raise exception 'Identificador remoto necessário'; end if;
 update public.contract_signature_envelopes set provider_id=p_remote,
 provider_document_id=coalesce(p_document,provider_document_id),updated_at=now()
 where id=p_id and provider='clicksign' and status='processing' and worker_claim=p_claim
 and (provider_id is null or provider_id=p_remote) and
 (provider_document_id is null or p_document is null or provider_document_id=p_document);
 if not found then raise exception 'Processamento não pertence a esta execução'; end if;
end $$;

create function public.signature_finish_clicksign(p_id uuid,p_claim uuid,p_error text default null,p_uncertain boolean default false)
returns void language plpgsql security definer set search_path=public as $$
begin
 if exists(select 1 from public.contract_signature_envelopes where id=p_id and worker_claim=p_claim
  and status in ('signed','declined','failed','viewed')) then return; end if;
 update public.contract_signature_envelopes set
 status=case when p_uncertain then 'uncertain' when p_error is not null then 'failed' else 'sent' end,
 error_code=p_error,updated_at=now()
 where id=p_id and provider='clicksign' and status='processing' and worker_claim=p_claim
 and (p_error is not null or (provider_id is not null and provider_document_id is not null));
 if not found then raise exception 'Processamento não confirmado'; end if;
end $$;

create function public.signature_ingest_clicksign(p_id text,p_document text,p_environment text,p_name text,p_at timestamptz,p_email text default null)
returns boolean language plpgsql security definer set search_path=public as $$
declare e public.contract_signature_envelopes;
begin
 select * into e from public.contract_signature_envelopes where provider='clicksign'
 and provider_environment=p_environment and provider_document_id=p_document;
 if not found then
  -- An upload callback can arrive before the upload response is checkpointed.
  if exists(select 1 from public.contract_signature_envelopes where provider='clicksign'
    and provider_environment=p_environment and status='processing' and provider_document_id is null) then
   raise exception 'Aguardando vínculo do documento';
  end if;
  return false;
 end if;
 if p_name in ('sign','signature_started','refusal') and (p_email is null or not exists(
  select 1 from jsonb_array_elements(e.signers) s where lower(s->>'email')=lower(p_email))) then
  raise exception 'Signatário não pertence ao contrato';
 end if;
 insert into public.signature_webhook_inbox(id,envelope_id,event_name,occurred_at,signer_email)
 values(p_id,e.id,p_name,p_at,lower(p_email)) on conflict do nothing;
 return true;
end $$;

create function public.signature_claim_events(p_environment text)
returns setof public.signature_webhook_inbox language plpgsql security definer set search_path=public as $$
begin
 return query with due as (
  select i.id from public.signature_webhook_inbox i join public.contract_signature_envelopes e on e.id=i.envelope_id
  where e.provider_environment=p_environment and i.completed_at is null and i.next_attempt_at<=now()
  and (i.claimed_at is null or i.claimed_at<now()-interval '5 minutes')
  order by i.received_at for update of i skip locked limit 10
 ) update public.signature_webhook_inbox i set attempts=attempts+1,claimed_at=now(),claim_token=gen_random_uuid()
 from due where due.id=i.id returning i.*;
end $$;

create function public.signature_apply_clicksign(p_event text,p_claim uuid,p_signed_path text default null)
returns jsonb language plpgsql security definer set search_path=public as $$
declare i public.signature_webhook_inbox; e public.contract_signature_envelopes; kind text; all_signed boolean;
begin
 select * into strict i from public.signature_webhook_inbox where id=p_event for update;
 if i.claim_token is distinct from p_claim then raise exception 'Evento pertence a outra execução'; end if;
 select * into strict e from public.contract_signature_envelopes where id=i.envelope_id for update;
 kind:=case i.event_name when 'sign' then 'signer_signed' when 'signature_started' then 'viewed'
 when 'refusal' then 'declined' when 'cancel' then 'provider_cancelled' when 'deadline' then 'expired' else 'closed' end;
 insert into public.contract_signature_events(provider,event_id,envelope_id,event_type,occurred_at,signer_email)
 values('clicksign',i.id,e.id,kind,i.occurred_at,i.signer_email) on conflict do nothing;
 if kind='closed' then
  update public.contract_signature_envelopes set provider_closed=true where id=e.id;
  e.provider_closed:=true;
 end if;
 select not exists(select 1 from jsonb_array_elements(e.signers) s where not exists(
  select 1 from public.contract_signature_events v where v.envelope_id=e.id and v.event_type='signer_signed'
  and lower(v.signer_email)=lower(s->>'email'))) into all_signed;
 if e.status not in ('signed','declined','cancelled','failed') then
  if kind='declined' then
   update public.contract_signature_envelopes set status='declined',updated_at=now() where id=e.id;
  elsif kind in ('provider_cancelled','expired') then
   update public.contract_signature_envelopes set status='failed',error_code=kind,updated_at=now() where id=e.id;
  elsif e.provider_closed and all_signed and p_signed_path is not null then
   if p_signed_path<>e.id::text||'/signed.pdf' or not exists(select 1 from storage.objects
    where bucket_id='contract-signatures' and name=p_signed_path) then raise exception 'PDF assinado não arquivado'; end if;
   update public.contract_signature_envelopes set status='signed',signed_path=p_signed_path,error_code=null,updated_at=now() where id=e.id;
  elsif kind in ('viewed','signer_signed') and e.status in ('sent','uncertain') then
   update public.contract_signature_envelopes set status='viewed',error_code=null,updated_at=now() where id=e.id;
  end if;
 end if;
 return jsonb_build_object('archive_required',kind not in ('declined','provider_cancelled','expired') and e.provider_closed and all_signed and
   e.status not in ('signed','declined','cancelled','failed') and p_signed_path is null);
end $$;

create function public.signature_complete_event(p_id text,p_claim uuid,p_error text default null)
returns void language plpgsql security definer set search_path=public as $$
begin
 update public.signature_webhook_inbox set completed_at=case when p_error is null then now() else null end,
 error_code=p_error,next_attempt_at=now()+make_interval(secs=>least(900,30*power(2,least(attempts,5))::int)),
 claimed_at=null,claim_token=null where id=p_id and claim_token=p_claim;
 if not found then raise exception 'Evento não pertence a esta execução'; end if;
end $$;

revoke all on function public.signature_claim_clicksign(text),public.signature_checkpoint_clicksign(uuid,uuid,text,text),
 public.signature_finish_clicksign(uuid,uuid,text,boolean),public.signature_ingest_clicksign(text,text,text,text,timestamptz,text),
 public.signature_claim_events(text),public.signature_apply_clicksign(text,uuid,text),public.signature_complete_event(text,uuid,text)
 from public,anon,authenticated;
grant execute on function public.signature_claim_clicksign(text),public.signature_checkpoint_clicksign(uuid,uuid,text,text),
 public.signature_finish_clicksign(uuid,uuid,text,boolean),public.signature_ingest_clicksign(text,text,text,text,timestamptz,text),
 public.signature_claim_events(text),public.signature_apply_clicksign(text,uuid,text),public.signature_complete_event(text,uuid,text)
 to service_role;
