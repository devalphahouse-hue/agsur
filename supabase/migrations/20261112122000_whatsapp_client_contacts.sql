-- Keep the existing recipient IDs and use the linked client account as a
-- fallback when the lead does not have a valid WhatsApp number.
create or replace function public.whatsapp_reminder_recipients(p_lead_id uuid, p_type text)
returns table(id uuid, name text, phone text)
language plpgsql security definer set search_path = '' as $$
begin
  if not public.whatsapp_panel_allowed() then
    raise exception 'Acesso negado' using errcode = '42501';
  end if;
  if not exists(select 1 from public.leads l where l.id = p_lead_id and not l.is_deleted) then
    raise exception 'Cliente indisponível';
  end if;
  if p_type = 'cliente' then
    return query
      select l.id, coalesce(l.fullname, l.name), coalesce(public.phone_to_e164(l.phone), client.phone)
      from public.leads l
      left join lateral (
        select public.phone_to_e164(u.phone) as phone from public.users u
        where u.lead_id = l.id and u.profile_type = 'Cliente'
          and not u.is_deleted and public.phone_to_e164(u.phone) is not null
        order by u.is_active desc nulls last, u.id limit 1
      ) client on true
      where l.id = p_lead_id and not l.wa_opt_out
        and coalesce(public.phone_to_e164(l.phone), client.phone) is not null;
  elsif p_type = 'vendedor' then
    return query select u.id, coalesce(u.fullname, u.name), u.phone from public.users u
      join public.leads l on l.seller_id = u.id
      where l.id = p_lead_id and u.is_active and not u.is_deleted;
  elsif p_type = 'equipe' then
    return query select u.id, coalesce(u.fullname, u.name), u.phone from public.users u
      join public.reminder_team_members t on t.user_id = u.id
      where t.enabled and u.is_active and not u.is_deleted order by u.name;
  else
    raise exception 'Destinatário inválido';
  end if;
end;
$$;

CREATE OR REPLACE FUNCTION public.create_lead_note(p_lead_id uuid,p_note text,p_reminder jsonb DEFAULT NULL,p_request_id uuid DEFAULT NULL)
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
    v.name,substr(ph,2),public.wa_param(concat_ws(' — ',nullif(trim(p_reminder->>'subject'),''),coalesce(nullif(trim(p_reminder->>'message'),''),trim(p_note))),860),
    (p_reminder->>'scheduled_at')::timestamptz,(p_reminder->>'scheduled_at')::timestamptz,r)
  ON CONFLICT(reminder_id,recipient_phone) WHERE NOT legacy_duplicate DO NOTHING;
  total:=total+1;
 END LOOP;
 IF total<>cardinality(ids) THEN RAISE EXCEPTION 'Destinatário indisponível ou não autorizado'; END IF;
 RETURN n;
END; $$;
