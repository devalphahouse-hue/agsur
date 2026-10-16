-- Official Meta Cloud API outbox. All writes are through RPCs.
CREATE TABLE public.whatsapp_reminders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  note_id uuid NOT NULL REFERENCES public.notes(id) ON DELETE RESTRICT,
  lead_id uuid NOT NULL REFERENCES public.leads(id) ON DELETE RESTRICT,
  created_by uuid NOT NULL REFERENCES public.users(id),
  recipient_type text NOT NULL CHECK (recipient_type IN ('cliente', 'vendedor', 'equipe')),
  recipient_user_id uuid REFERENCES public.users(id),
  recipient_name text NOT NULL,
  recipient_phone text NOT NULL CHECK (recipient_phone ~ '^[1-9][0-9]{7,14}$'),
  message text NOT NULL CHECK (length(message) BETWEEN 1 AND 900),
  scheduled_at timestamptz NOT NULL,
  consent_confirmed_at timestamptz NOT NULL DEFAULT now(),
  status text NOT NULL DEFAULT 'Agendado' CHECK (status IN ('Agendado', 'Processando', 'Enviado', 'Falha')),
  claimed_at timestamptz,
  sent_at timestamptz,
  meta_message_id text UNIQUE,
  delivery_status text CHECK (delivery_status IN ('accepted', 'sent', 'delivered', 'read', 'failed')),
  delivery_updated_at timestamptz,
  error_code text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX whatsapp_reminders_due ON public.whatsapp_reminders(scheduled_at) WHERE status = 'Agendado';
CREATE INDEX whatsapp_reminders_lead ON public.whatsapp_reminders(lead_id, created_at DESC);
ALTER TABLE public.whatsapp_reminders ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.whatsapp_reminders FROM anon, authenticated;
GRANT SELECT ON public.whatsapp_reminders TO authenticated;
GRANT ALL ON public.whatsapp_reminders TO service_role;
CREATE POLICY reminders_panel_read ON public.whatsapp_reminders FOR SELECT TO authenticated
  USING (public.auth_is_seller_or_admin() AND EXISTS (
    SELECT 1 FROM public.users WHERE id = auth.uid() AND is_active AND NOT is_deleted
  ));

-- Resolve recipients server-side; never accept an arbitrary phone from the app.
CREATE FUNCTION public.whatsapp_reminder_recipients(p_lead_id uuid, p_type text)
RETURNS TABLE(id uuid, name text, phone text)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.auth_is_seller_or_admin() OR NOT EXISTS (
    SELECT 1 FROM public.users WHERE users.id = auth.uid() AND is_active AND NOT is_deleted
  ) THEN RAISE EXCEPTION 'Acesso negado' USING ERRCODE = '42501'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.leads WHERE leads.id = p_lead_id AND NOT is_deleted)
    THEN RAISE EXCEPTION 'Cliente indisponível'; END IF;
  IF p_type = 'cliente' THEN
    RETURN QUERY SELECT l.id, coalesce(l.fullname, l.name), l.phone FROM public.leads l WHERE l.id = p_lead_id;
  ELSIF p_type = 'vendedor' THEN
    RETURN QUERY SELECT u.id, coalesce(u.fullname, u.name), u.phone FROM public.users u
      JOIN public.leads l ON l.seller_id = u.id WHERE l.id = p_lead_id AND u.is_active AND NOT u.is_deleted;
  ELSIF p_type = 'equipe' THEN
    RETURN QUERY SELECT u.id, coalesce(u.fullname, u.name), u.phone FROM public.users u
      WHERE u.profile_type::text IN ('Admin Master', 'Admin', 'Vendedor', 'Colaborador', 'Admin2')
        AND u.is_active AND NOT u.is_deleted ORDER BY u.name;
  ELSE RAISE EXCEPTION 'Destinatário inválido'; END IF;
END;
$$;

-- The note and all recipients are committed in a single transaction.
CREATE FUNCTION public.create_note_with_whatsapp_reminder(
  p_lead_id uuid, p_note text, p_recipient_type text DEFAULT NULL,
  p_recipient_ids uuid[] DEFAULT '{}', p_scheduled_at timestamptz DEFAULT NULL,
  p_consent boolean DEFAULT false
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_note_id uuid; v_rec record; v_phone text; v_count integer := 0;
BEGIN
  IF NOT public.auth_is_seller_or_admin() OR NOT EXISTS (
    SELECT 1 FROM public.users WHERE id = auth.uid() AND is_active AND NOT is_deleted
  ) THEN RAISE EXCEPTION 'Acesso negado' USING ERRCODE = '42501'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.leads WHERE id = p_lead_id AND NOT is_deleted)
    THEN RAISE EXCEPTION 'Cliente indisponível'; END IF;
  IF p_note IS NULL OR length(trim(p_note)) = 0 THEN RAISE EXCEPTION 'Informe a nota'; END IF;
  IF p_recipient_type IS NOT NULL THEN
    IF p_scheduled_at IS NULL OR p_scheduled_at <= now() OR NOT coalesce(p_consent, false)
      OR length(trim(p_note)) > 900 OR coalesce(cardinality(p_recipient_ids), 0) NOT BETWEEN 1 AND 50
      THEN RAISE EXCEPTION 'Informe data futura, destinatários e autorização para WhatsApp (nota até 900 caracteres)'; END IF;
  ELSIF p_scheduled_at IS NOT NULL OR coalesce(cardinality(p_recipient_ids), 0) <> 0 THEN
    RAISE EXCEPTION 'Informe o tipo de destinatário';
  END IF;
  INSERT INTO public.notes(lead_id, note, created_by) VALUES (p_lead_id, trim(p_note), auth.uid()) RETURNING id INTO v_note_id;
  IF p_recipient_type IS NOT NULL THEN
    FOR v_rec IN SELECT * FROM public.whatsapp_reminder_recipients(p_lead_id, p_recipient_type)
      WHERE id = ANY(p_recipient_ids) LOOP
      v_phone := regexp_replace(v_rec.phone, '[^0-9]', '', 'g');
      -- Local Brazilian numbers get the country prefix. International numbers must include DDI.
      IF length(v_phone) IN (10, 11) THEN v_phone := '55' || v_phone; END IF;
      IF v_phone IS NULL OR v_phone !~ '^[1-9][0-9]{7,14}$' THEN RAISE EXCEPTION 'Telefone inválido para %', v_rec.name; END IF;
      INSERT INTO public.whatsapp_reminders(note_id, lead_id, created_by, recipient_type,
        recipient_user_id, recipient_name, recipient_phone, message, scheduled_at)
      VALUES (v_note_id, p_lead_id, auth.uid(), p_recipient_type,
        CASE WHEN p_recipient_type <> 'cliente' THEN v_rec.id END, v_rec.name, v_phone, trim(p_note), p_scheduled_at);
      v_count := v_count + 1;
    END LOOP;
    IF v_count <> (SELECT count(DISTINCT x) FROM unnest(p_recipient_ids) x) THEN
      RAISE EXCEPTION 'Destinatário indisponível'; END IF;
  END IF;
  RETURN v_note_id;
END;
$$;

-- Stale claims are failed, never automatically resent: the provider may have accepted a timed-out request.
CREATE FUNCTION public.claim_whatsapp_reminders()
RETURNS SETOF public.whatsapp_reminders LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  UPDATE public.whatsapp_reminders SET status = 'Falha', error_code = 'dispatch_outcome_unknown'
    WHERE status = 'Processando' AND claimed_at < now() - interval '10 minutes';
  RETURN QUERY WITH due AS (
    SELECT r.id FROM public.whatsapp_reminders r WHERE status = 'Agendado' AND scheduled_at <= now()
      ORDER BY scheduled_at LIMIT 20 FOR UPDATE SKIP LOCKED
  ) UPDATE public.whatsapp_reminders r SET status = 'Processando', claimed_at = now()
    FROM due WHERE r.id = due.id RETURNING r.*;
END;
$$;

-- Monotonic delivery updates tolerate duplicate and out-of-order webhooks.
CREATE FUNCTION public.record_whatsapp_status(p_message_id text, p_status text, p_at timestamptz, p_error text DEFAULT NULL, p_reminder_id uuid DEFAULT NULL)
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  UPDATE public.whatsapp_reminders SET
    meta_message_id = coalesce(meta_message_id, p_message_id),
    delivery_status = p_status, delivery_updated_at = p_at,
    status = CASE WHEN p_status = 'failed' THEN 'Falha' ELSE 'Enviado' END,
    sent_at = CASE WHEN p_status <> 'failed' THEN coalesce(sent_at, p_at) ELSE sent_at END,
    error_code = CASE WHEN p_status = 'failed' THEN left(p_error, 100) ELSE NULL END
  WHERE (meta_message_id = p_message_id OR (id = p_reminder_id AND meta_message_id IS NULL)) AND p_status IN ('sent', 'delivered', 'read', 'failed')
    AND (delivery_updated_at IS NULL OR p_at >= delivery_updated_at)
    AND (delivery_status IS NULL OR delivery_status = 'accepted'
      OR (delivery_status = 'sent' AND p_status IN ('delivered', 'read', 'failed'))
      OR (delivery_status = 'delivered' AND p_status = 'read'));
$$;
REVOKE ALL ON FUNCTION public.whatsapp_reminder_recipients(uuid, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.create_note_with_whatsapp_reminder(uuid, text, text, uuid[], timestamptz, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.whatsapp_reminder_recipients(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_note_with_whatsapp_reminder(uuid, text, text, uuid[], timestamptz, boolean) TO authenticated;
REVOKE ALL ON FUNCTION public.claim_whatsapp_reminders() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.record_whatsapp_status(text, text, timestamptz, text, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.claim_whatsapp_reminders() TO service_role;
GRANT EXECUTE ON FUNCTION public.record_whatsapp_status(text, text, timestamptz, text, uuid) TO service_role;
