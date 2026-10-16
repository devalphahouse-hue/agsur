-- Complete Sprint 1 on top of the existing official Meta outbox. Keep all existing data/API names.
CREATE OR REPLACE FUNCTION public.phone_to_e164(p_phone text) RETURNS text
LANGUAGE plpgsql IMMUTABLE SET search_path = public AS $$
DECLARE v text := regexp_replace(coalesce(p_phone,''), '[^0-9]', '', 'g');
BEGIN
  IF left(v,2) = '00' THEN v := substr(v,3); END IF;
  IF left(v,1) = '0' AND length(v) IN (13,14) THEN v := substr(v,4); END IF;
  IF v ~ '^([0-9])\1+$' THEN RETURN NULL; END IF;
  IF length(v) IN (10,11) THEN v := '55' || v; END IF;
  IF length(v) NOT IN (12,13) OR left(v,2) <> '55' THEN RETURN NULL; END IF;
  IF substring(v,3,2)::integer < 11 OR substring(v,3,2)::integer > 99

    OR (length(v)=13 AND substring(v,5,1)<>'9')
    OR (length(v)=12 AND substring(v,5,1) NOT IN ('2','3','4','5')) THEN RETURN NULL; END IF;
  RETURN '+' || v;
END; $$;
CREATE OR REPLACE FUNCTION public.wa_param(p_text text, p_max integer DEFAULT 860) RETURNS text
LANGUAGE sql IMMUTABLE SET search_path = public AS $$
 SELECT CASE WHEN length(v) > greatest(p_max,1) THEN left(v,greatest(p_max,1)-1)||'…' ELSE v END
 FROM (SELECT trim(regexp_replace(coalesce(p_text,''),'[[:space:]]+',' ','g')) v) s;
$$;
CREATE FUNCTION public.whatsapp_panel_allowed() RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public AS $$
 SELECT coalesce(public.auth_is_seller_or_admin(),false) AND EXISTS(
 SELECT 1 FROM public.users WHERE id=auth.uid() AND is_active AND NOT is_deleted);
$$;
ALTER TABLE public.leads ADD COLUMN IF NOT EXISTS wa_opt_out boolean NOT NULL DEFAULT false;
CREATE TABLE public.reminder_team_members (
 user_id uuid PRIMARY KEY REFERENCES public.users(id), enabled boolean NOT NULL DEFAULT true,
 consent_confirmed_at timestamptz NOT NULL DEFAULT now(), updated_by uuid NOT NULL REFERENCES public.users(id)
);
CREATE TABLE public.note_reminders (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), note_id uuid NOT NULL REFERENCES public.notes(id),
 lead_id uuid NOT NULL REFERENCES public.leads(id), created_by uuid NOT NULL REFERENCES public.users(id),
 subject text NOT NULL DEFAULT '', scheduled_at timestamptz NOT NULL,
 recipient_kind text NOT NULL CHECK(recipient_kind IN ('cliente','vendedor','equipe')),
 status text NOT NULL DEFAULT 'Agendado' CHECK(status IN ('Agendado','Processando','Enviado','Falha','Cancelado')),
 request_id uuid, request_fingerprint text, created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(created_by,request_id)
);
ALTER TABLE public.whatsapp_reminders DROP CONSTRAINT whatsapp_reminders_status_check;
ALTER TABLE public.whatsapp_reminders ADD CONSTRAINT whatsapp_reminders_status_check
 CHECK(status IN ('Agendado','Processando','Enviado','Falha','Cancelado'));
ALTER TABLE public.whatsapp_reminders
 ADD COLUMN reminder_id uuid REFERENCES public.note_reminders(id),
 ADD COLUMN legacy_duplicate boolean NOT NULL DEFAULT false,
 ADD COLUMN attempt_count integer NOT NULL DEFAULT 0,
 ADD COLUMN next_attempt_at timestamptz,
 ADD COLUMN claim_token uuid,
 ADD COLUMN claimed_by uuid,
 ADD COLUMN provider text,
 ADD COLUMN template_name text NOT NULL DEFAULT 'agsur_lembrete_atendimento',
 ADD COLUMN template_language text NOT NULL DEFAULT 'pt_BR';
INSERT INTO public.note_reminders(id,note_id,lead_id,created_by,scheduled_at,recipient_kind,created_at)
 SELECT DISTINCT ON(note_id) note_id,note_id,lead_id,created_by,scheduled_at,recipient_type,created_at
 FROM public.whatsapp_reminders ORDER BY note_id,created_at;
UPDATE public.whatsapp_reminders SET reminder_id=note_id,next_attempt_at=scheduled_at;
ALTER TABLE public.whatsapp_reminders ALTER COLUMN reminder_id SET NOT NULL;
ALTER TABLE public.whatsapp_reminders ALTER COLUMN next_attempt_at SET NOT NULL;
-- Preserve previously recorded duplicate recipients without losing their audit trail.
WITH ranked AS (SELECT id,row_number() OVER(PARTITION BY reminder_id,recipient_phone ORDER BY created_at,id) AS n FROM public.whatsapp_reminders)
UPDATE public.whatsapp_reminders w SET legacy_duplicate=true FROM ranked r WHERE r.id=w.id AND r.n>1;
UPDATE public.whatsapp_reminders SET status='Cancelado',error_code='legacy_duplicate_recipient' WHERE legacy_duplicate AND status='Agendado';
CREATE UNIQUE INDEX whatsapp_reminder_phone ON public.whatsapp_reminders(reminder_id,recipient_phone) WHERE NOT legacy_duplicate;
CREATE INDEX whatsapp_reminder_retry_due ON public.whatsapp_reminders(next_attempt_at) WHERE status IN ('Agendado','Processando');
CREATE INDEX note_reminders_lead ON public.note_reminders(lead_id,created_at DESC);
CREATE TABLE public.whatsapp_dispatch_attempts (
 id uuid PRIMARY KEY, dispatch_id uuid NOT NULL REFERENCES public.whatsapp_reminders(id), attempt_number integer NOT NULL,
 provider text, provider_message_id text UNIQUE, started_at timestamptz NOT NULL DEFAULT now(), finished_at timestamptz,
 outcome text NOT NULL DEFAULT 'Processando', error_code text, delivery_status text, delivery_updated_at timestamptz,
 UNIQUE(dispatch_id,attempt_number)
);
ALTER TABLE public.note_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminder_team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.whatsapp_dispatch_attempts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.note_reminders, public.reminder_team_members, public.whatsapp_dispatch_attempts FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.note_reminders, public.reminder_team_members, public.whatsapp_dispatch_attempts TO authenticated;
GRANT ALL ON public.note_reminders, public.reminder_team_members, public.whatsapp_dispatch_attempts TO service_role;
CREATE POLICY reminder_intents_read ON public.note_reminders FOR SELECT TO authenticated USING(public.whatsapp_panel_allowed());
CREATE POLICY reminder_team_read ON public.reminder_team_members FOR SELECT TO authenticated USING(public.whatsapp_panel_allowed());
CREATE POLICY reminder_attempts_read ON public.whatsapp_dispatch_attempts FOR SELECT TO authenticated USING(public.whatsapp_panel_allowed());
CREATE VIEW public.vw_reminder_dispatches WITH(security_invoker=on) AS
 SELECT d.*, r.subject, l.name AS lead_name,
 (d.status='Agendado' AND d.next_attempt_at < now()-interval '10 minutes') AS overdue
 FROM public.whatsapp_reminders d JOIN public.note_reminders r ON r.id=d.reminder_id JOIN public.leads l ON l.id=d.lead_id;
REVOKE ALL ON public.vw_reminder_dispatches FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.vw_reminder_dispatches TO authenticated,service_role;

CREATE OR REPLACE FUNCTION public.whatsapp_reminder_recipients(p_lead_id uuid,p_type text)
RETURNS TABLE(id uuid,name text,phone text) LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
BEGIN
 IF NOT public.whatsapp_panel_allowed() THEN RAISE EXCEPTION 'Acesso negado' USING ERRCODE='42501'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.leads l WHERE l.id=p_lead_id AND NOT l.is_deleted)
 THEN RAISE EXCEPTION 'Cliente indisponível'; END IF;
 IF p_type='cliente' THEN
 RETURN QUERY SELECT l.id,coalesce(l.fullname,l.name),l.phone FROM public.leads l WHERE l.id=p_lead_id AND NOT l.wa_opt_out;
 ELSIF p_type='vendedor' THEN
 RETURN QUERY SELECT u.id,coalesce(u.fullname,u.name),u.phone FROM public.users u JOIN public.leads l ON l.seller_id=u.id
 WHERE l.id=p_lead_id AND u.is_active AND NOT u.is_deleted;
 ELSIF p_type='equipe' THEN
 RETURN QUERY SELECT u.id,coalesce(u.fullname,u.name),u.phone FROM public.users u JOIN public.reminder_team_members t ON t.user_id=u.id
 WHERE t.enabled AND u.is_active AND NOT u.is_deleted ORDER BY u.name;
 ELSE RAISE EXCEPTION 'Destinatário inválido'; END IF;
END; $$;
CREATE FUNCTION public.create_lead_note(p_lead_id uuid,p_note text,p_reminder jsonb DEFAULT NULL,p_request_id uuid DEFAULT NULL)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE n uuid; r uuid; v record; ph text; total integer:=0; fingerprint text; existing public.note_reminders; ids uuid[];
BEGIN
 IF NOT public.whatsapp_panel_allowed() THEN RAISE EXCEPTION 'Acesso negado' USING ERRCODE='42501'; END IF;
 IF p_note IS NULL OR length(trim(p_note))=0 THEN RAISE EXCEPTION 'Informe a nota'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.leads WHERE id=p_lead_id AND NOT is_deleted) THEN RAISE EXCEPTION 'Cliente indisponível'; END IF;
 IF p_reminder IS NOT NULL THEN
  IF length(coalesce(p_reminder->>'subject',''))>100 THEN RAISE EXCEPTION 'Assunto deve ter até 100 caracteres'; END IF;
  fingerprint:=md5(p_lead_id::text||p_note||p_reminder::text);
  IF p_request_id IS NOT NULL THEN
   PERFORM pg_advisory_xact_lock(hashtextextended(auth.uid()::text||p_request_id::text,0));
   SELECT * INTO existing FROM public.note_reminders WHERE created_by=auth.uid() AND request_id=p_request_id;
   IF FOUND THEN
    IF existing.request_fingerprint<>fingerprint THEN RAISE EXCEPTION 'Requisição já utilizada'; END IF;
    RETURN existing.note_id;
   END IF;
  END IF;
  IF NOT coalesce((p_reminder->>'consent')::boolean,false) OR (p_reminder->>'scheduled_at') IS NULL
   OR (p_reminder->>'scheduled_at')::timestamptz<=now() THEN RAISE EXCEPTION 'Informe data futura e autorização para WhatsApp'; END IF;
  SELECT array_agg(DISTINCT x::uuid) INTO ids FROM jsonb_array_elements_text(p_reminder->'recipient_ids') x;
  IF coalesce(cardinality(ids),0) NOT BETWEEN 1 AND 50 THEN RAISE EXCEPTION 'Selecione de 1 a 50 destinatários'; END IF;
 END IF;
 INSERT INTO public.notes(lead_id,note,created_by) VALUES(p_lead_id,trim(p_note),auth.uid()) RETURNING id INTO n;
 IF p_reminder IS NULL THEN RETURN n; END IF;
 INSERT INTO public.note_reminders(note_id,lead_id,created_by,subject,scheduled_at,recipient_kind,request_id,request_fingerprint)
 VALUES(n,p_lead_id,auth.uid(),left(coalesce(p_reminder->>'subject',''),100),
 (p_reminder->>'scheduled_at')::timestamptz,p_reminder->>'recipient_type',p_request_id,fingerprint) RETURNING id INTO r;
 FOR v IN SELECT * FROM public.whatsapp_reminder_recipients(p_lead_id,p_reminder->>'recipient_type') WHERE id=ANY(ids) LOOP
  ph:=public.phone_to_e164(v.phone);
  IF ph IS NULL THEN RAISE EXCEPTION 'Corrija o telefone de % antes de agendar',v.name; END IF;
  INSERT INTO public.whatsapp_reminders(note_id,lead_id,created_by,recipient_type,recipient_user_id,recipient_name,
    recipient_phone,message,scheduled_at,next_attempt_at,reminder_id)
  VALUES(n,p_lead_id,auth.uid(),p_reminder->>'recipient_type',CASE WHEN p_reminder->>'recipient_type'<>'cliente' THEN v.id END,
    v.name,substr(ph,2),public.wa_param(concat_ws(' — ',nullif(trim(p_reminder->>'subject'),''),trim(p_note)),860),
    (p_reminder->>'scheduled_at')::timestamptz,(p_reminder->>'scheduled_at')::timestamptz,r)
  ON CONFLICT(reminder_id,recipient_phone) WHERE NOT legacy_duplicate DO NOTHING;
  total:=total+1;
 END LOOP;
 IF total<>cardinality(ids) THEN RAISE EXCEPTION 'Destinatário indisponível ou não autorizado'; END IF;
 RETURN n;
END; $$;
CREATE OR REPLACE FUNCTION public.create_note_with_whatsapp_reminder(p_lead_id uuid,p_note text,p_recipient_type text DEFAULT NULL,
 p_recipient_ids uuid[] DEFAULT '{}',p_scheduled_at timestamptz DEFAULT NULL,p_consent boolean DEFAULT false)
RETURNS uuid LANGUAGE sql SECURITY DEFINER SET search_path=public AS $$
 SELECT public.create_lead_note(p_lead_id,p_note,CASE WHEN p_recipient_type IS NOT NULL THEN
 jsonb_build_object('recipient_type',p_recipient_type,'recipient_ids',p_recipient_ids,'scheduled_at',p_scheduled_at,'consent',p_consent) END);
$$;
CREATE FUNCTION public.refresh_whatsapp_reminder(p_id uuid) RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path=public AS $$
 UPDATE public.note_reminders SET status=(SELECT CASE
 WHEN bool_or(status='Processando') THEN 'Processando' WHEN bool_or(status='Agendado') THEN 'Agendado'
 WHEN bool_or(status='Falha') THEN 'Falha' WHEN bool_or(status='Enviado') THEN 'Enviado' ELSE 'Cancelado' END
 FROM public.whatsapp_reminders WHERE reminder_id=p_id) WHERE id=p_id;
$$;
CREATE FUNCTION public.tg_whatsapp_rollup() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
BEGIN PERFORM public.refresh_whatsapp_reminder(NEW.reminder_id); RETURN NEW; END; $$;
CREATE TRIGGER whatsapp_rollup AFTER INSERT OR UPDATE OF status ON public.whatsapp_reminders
 FOR EACH ROW EXECUTE FUNCTION public.tg_whatsapp_rollup();
SELECT public.refresh_whatsapp_reminder(id) FROM public.note_reminders;

CREATE FUNCTION public.claim_whatsapp_dispatches(p_limit integer DEFAULT 20,p_run_id uuid DEFAULT NULL)
RETURNS SETOF public.whatsapp_reminders LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE d public.whatsapp_reminders;
BEGIN
 -- Never retry an abandoned send automatically; Meta may already have accepted it.
 UPDATE public.whatsapp_dispatch_attempts a SET outcome='Falha',error_code='dispatch_outcome_unknown',finished_at=now()
 FROM public.whatsapp_reminders w WHERE a.id=w.claim_token AND w.status='Processando' AND w.claimed_at<now()-interval '10 minutes';
 UPDATE public.whatsapp_reminders SET status='Falha',error_code='dispatch_outcome_unknown',claim_token=NULL
 WHERE status='Processando' AND claimed_at<now()-interval '10 minutes';
 -- Respect opt-out/deactivation even if it happened after scheduling.
 UPDATE public.whatsapp_reminders w SET status='Cancelado',error_code='recipient_unavailable'
 WHERE w.status='Agendado' AND (
  NOT EXISTS(SELECT 1 FROM public.leads l WHERE l.id=w.lead_id AND NOT l.is_deleted)
  OR (w.recipient_type='cliente' AND EXISTS(SELECT 1 FROM public.leads l WHERE l.id=w.lead_id AND l.wa_opt_out))
  OR (w.recipient_user_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.users u WHERE u.id=w.recipient_user_id AND u.is_active AND NOT u.is_deleted))
  OR (w.recipient_type='equipe' AND NOT EXISTS(SELECT 1 FROM public.reminder_team_members t WHERE t.user_id=w.recipient_user_id AND t.enabled)));
 FOR d IN WITH due AS (SELECT w.id FROM public.whatsapp_reminders w WHERE status='Agendado' AND next_attempt_at<=now()
 ORDER BY next_attempt_at LIMIT greatest(1,least(coalesce(p_limit,20),50)) FOR UPDATE SKIP LOCKED)
 UPDATE public.whatsapp_reminders w SET status='Processando',claimed_at=now(),claimed_by=p_run_id,
 claim_token=gen_random_uuid(),attempt_count=attempt_count+1 FROM due WHERE w.id=due.id RETURNING w.* LOOP
  INSERT INTO public.whatsapp_dispatch_attempts(id,dispatch_id,attempt_number) VALUES(d.claim_token,d.id,d.attempt_count);
  RETURN NEXT d;
 END LOOP;
END; $$;
CREATE FUNCTION public.complete_whatsapp_dispatch(p_id uuid,p_claim_token uuid,p_provider text,p_message_id text DEFAULT NULL,
 p_error text DEFAULT NULL,p_retriable boolean DEFAULT false) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE d public.whatsapp_reminders; retry boolean;
BEGIN
 SELECT * INTO d FROM public.whatsapp_reminders WHERE id=p_id FOR UPDATE;
 IF NOT FOUND OR d.claim_token IS DISTINCT FROM p_claim_token OR d.status<>'Processando' THEN RETURN false; END IF;
 IF p_provider NOT IN ('meta','dryrun') THEN RAISE EXCEPTION 'Provedor inválido'; END IF;
 retry:=p_message_id IS NULL AND coalesce(p_retriable,false) AND d.attempt_count<4 AND p_error<>'dispatch_outcome_unknown';
 UPDATE public.whatsapp_dispatch_attempts SET provider=p_provider,provider_message_id=p_message_id,finished_at=now(),
 outcome=CASE WHEN p_message_id IS NOT NULL THEN 'Enviado' ELSE 'Falha' END,error_code=left(p_error,100) WHERE id=p_claim_token;
 UPDATE public.whatsapp_reminders SET provider=p_provider,meta_message_id=p_message_id,
 status=CASE WHEN p_message_id IS NOT NULL THEN 'Enviado' WHEN retry THEN 'Agendado' ELSE 'Falha' END,
 sent_at=CASE WHEN p_message_id IS NOT NULL THEN now() END,
 delivery_status=CASE WHEN p_message_id IS NOT NULL AND p_provider='meta' THEN 'accepted' END,
 error_code=left(p_error,100),claim_token=NULL,
 next_attempt_at=CASE WHEN retry THEN now()+CASE d.attempt_count WHEN 1 THEN interval '2 minutes' WHEN 2 THEN interval '10 minutes' ELSE interval '60 minutes' END ELSE next_attempt_at END
 WHERE id=p_id;
 RETURN true;
END; $$;
-- Retire the previous claim endpoint so an old worker cannot ignore retry scheduling.
CREATE OR REPLACE FUNCTION public.claim_whatsapp_reminders() RETURNS SETOF public.whatsapp_reminders
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
BEGIN RAISE EXCEPTION 'Atualize a função whatsapp-reminders antes de ativar o Cron'; END; $$;
CREATE FUNCTION public.cancel_note_reminder(p_id uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
BEGIN
 IF NOT public.whatsapp_panel_allowed() THEN RAISE EXCEPTION 'Acesso negado' USING ERRCODE='42501'; END IF;
 PERFORM 1 FROM public.whatsapp_reminders WHERE reminder_id=p_id ORDER BY id FOR UPDATE;
 IF EXISTS(SELECT 1 FROM public.whatsapp_reminders WHERE reminder_id=p_id AND status='Processando')
 THEN RAISE EXCEPTION 'Envio em andamento; aguarde o resultado antes de cancelar'; END IF;
 UPDATE public.whatsapp_reminders SET status='Cancelado' WHERE reminder_id=p_id AND status IN ('Agendado','Falha');
END; $$;
CREATE FUNCTION public.retry_whatsapp_dispatch(p_id uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE d public.whatsapp_reminders;
BEGIN
 IF NOT public.whatsapp_panel_allowed() THEN RAISE EXCEPTION 'Acesso negado' USING ERRCODE='42501'; END IF;
 SELECT * INTO d FROM public.whatsapp_reminders WHERE id=p_id FOR UPDATE;
 IF NOT FOUND OR d.status<>'Falha' THEN RAISE EXCEPTION 'Somente disparos com falha podem ser reenviados'; END IF;
 IF d.error_code='dispatch_outcome_unknown' THEN RAISE EXCEPTION 'Resultado incerto: confirme na Meta antes de criar um novo lembrete'; END IF;
 IF d.provider='dryrun' THEN RAISE EXCEPTION 'Crie um novo lembrete para testar o envio real'; END IF;
 UPDATE public.whatsapp_reminders SET status='Agendado',next_attempt_at=now(),error_code=NULL,
 delivery_status=NULL,delivery_updated_at=NULL,meta_message_id=NULL,sent_at=NULL WHERE id=p_id;
END; $$;
CREATE FUNCTION public.list_whatsapp_team_members() RETURNS TABLE(id uuid,name text,phone text,enabled boolean)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
BEGIN
 IF NOT public.whatsapp_panel_allowed() THEN RAISE EXCEPTION 'Acesso negado' USING ERRCODE='42501'; END IF;
 RETURN QUERY SELECT u.id,coalesce(u.fullname,u.name),u.phone,coalesce(t.enabled,false) FROM public.users u
 LEFT JOIN public.reminder_team_members t ON t.user_id=u.id
 WHERE u.is_active AND NOT u.is_deleted AND u.profile_type::text IN ('Admin Master','Admin','Vendedor','Colaborador','Admin2') ORDER BY u.name;
END; $$;
CREATE FUNCTION public.set_whatsapp_team_member(p_user_id uuid,p_enabled boolean) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
BEGIN
 IF NOT public.whatsapp_panel_allowed() OR NOT public.auth_is_admin_master() THEN RAISE EXCEPTION 'Somente Admin Master pode gerenciar a equipe' USING ERRCODE='42501'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.users WHERE id=p_user_id AND is_active AND NOT is_deleted AND profile_type::text IN ('Admin Master','Admin','Vendedor','Colaborador','Admin2'))
 THEN RAISE EXCEPTION 'Membro indisponível'; END IF;
 IF p_enabled AND public.phone_to_e164((SELECT phone FROM public.users WHERE id=p_user_id)) IS NULL THEN RAISE EXCEPTION 'Corrija o telefone antes de habilitar o membro'; END IF;
 INSERT INTO public.reminder_team_members(user_id,enabled,updated_by) VALUES(p_user_id,coalesce(p_enabled,false),auth.uid())
 ON CONFLICT(user_id) DO UPDATE SET enabled=excluded.enabled,updated_by=auth.uid(),consent_confirmed_at=now();
END; $$;
CREATE FUNCTION public.set_whatsapp_opt_out(p_lead_id uuid,p_opt_out boolean) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
BEGIN
 IF NOT public.whatsapp_panel_allowed() THEN RAISE EXCEPTION 'Acesso negado' USING ERRCODE='42501'; END IF;
 UPDATE public.leads SET wa_opt_out=coalesce(p_opt_out,false) WHERE id=p_lead_id AND NOT is_deleted;
END; $$;
-- Webhooks reconcile an early callback and keep previous attempts as evidence.
CREATE OR REPLACE FUNCTION public.record_whatsapp_status(p_message_id text,p_status text,p_at timestamptz,p_error text DEFAULT NULL,p_reminder_id uuid DEFAULT NULL)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE d public.whatsapp_reminders; old_attempt uuid;
BEGIN
 IF p_status NOT IN ('sent','delivered','read','failed') THEN RETURN; END IF;
 SELECT id INTO old_attempt FROM public.whatsapp_dispatch_attempts WHERE provider_message_id=p_message_id;
 IF old_attempt IS NOT NULL THEN
  UPDATE public.whatsapp_dispatch_attempts SET delivery_status=p_status,delivery_updated_at=p_at,
  outcome=CASE WHEN p_status='failed' THEN 'Falha' ELSE 'Enviado' END,
  error_code=CASE WHEN p_status='failed' THEN left(p_error,100) END
  WHERE id=old_attempt AND (delivery_updated_at IS NULL OR p_at>=delivery_updated_at)
  AND (delivery_status IS NULL OR delivery_status='accepted' OR
  (delivery_status='sent' AND p_status IN ('delivered','read','failed')) OR (delivery_status='delivered' AND p_status='read'));
 END IF;
 SELECT * INTO d FROM public.whatsapp_reminders WHERE meta_message_id=p_message_id
 OR (id=p_reminder_id AND meta_message_id IS NULL
 AND (status='Processando' OR (status='Falha' AND error_code='dispatch_outcome_unknown'))
 AND (old_attempt IS NULL OR old_attempt=claim_token)) FOR UPDATE;
 IF NOT FOUND OR d.provider='dryrun' THEN RETURN; END IF;
 IF d.delivery_updated_at IS NOT NULL AND p_at<d.delivery_updated_at THEN RETURN; END IF;
 IF d.delivery_status='read' OR (d.delivery_status='delivered' AND p_status<>'read') OR d.delivery_status='failed' THEN RETURN; END IF;
 IF d.attempt_count>0 THEN
  UPDATE public.whatsapp_dispatch_attempts SET provider='meta',provider_message_id=p_message_id,outcome=CASE WHEN p_status='failed' THEN 'Falha' ELSE 'Enviado' END,
  error_code=CASE WHEN p_status='failed' THEN left(p_error,100) END,finished_at=now(),delivery_status=p_status,delivery_updated_at=p_at WHERE dispatch_id=d.id AND attempt_number=d.attempt_count;
 END IF;
 UPDATE public.whatsapp_reminders SET meta_message_id=p_message_id,provider='meta',claim_token=NULL,
 delivery_status=p_status,delivery_updated_at=p_at,status=CASE WHEN p_status='failed' THEN 'Falha' ELSE 'Enviado' END,
 sent_at=CASE WHEN p_status<>'failed' THEN coalesce(sent_at,p_at) ELSE sent_at END,
 error_code=CASE WHEN p_status='failed' THEN left(p_error,100) END WHERE id=d.id;
END; $$;
-- Explicit ACL on every RPC, including helpers (Supabase may grant default EXECUTE to authenticated).
DO $$ DECLARE f record; BEGIN
 FOR f IN SELECT p.oid::regprocedure signature,p.proname FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='public' AND p.proname IN ('phone_to_e164','wa_param','whatsapp_panel_allowed','whatsapp_reminder_recipients',
 'create_lead_note','create_note_with_whatsapp_reminder','refresh_whatsapp_reminder','tg_whatsapp_rollup','claim_whatsapp_dispatches',
 'complete_whatsapp_dispatch','claim_whatsapp_reminders','cancel_note_reminder','retry_whatsapp_dispatch','list_whatsapp_team_members',
 'set_whatsapp_team_member','set_whatsapp_opt_out','record_whatsapp_status') LOOP
  EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC,anon,authenticated',f.signature);
  EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO service_role',f.signature);
  IF f.proname IN ('phone_to_e164','wa_param','whatsapp_panel_allowed','whatsapp_reminder_recipients','create_lead_note',
  'create_note_with_whatsapp_reminder','cancel_note_reminder','retry_whatsapp_dispatch','list_whatsapp_team_members','set_whatsapp_team_member','set_whatsapp_opt_out')
  THEN EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated',f.signature); END IF;
 END LOOP;
END $$;
