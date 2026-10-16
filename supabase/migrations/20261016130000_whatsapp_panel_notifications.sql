-- Panel inbox: scheduled reminders become visible when due, even if Meta fails.
-- One receipt per user/intention, independent of the WhatsApp recipient fan-out.
CREATE TABLE public.reminder_notification_reads (
 reminder_id uuid NOT NULL REFERENCES public.note_reminders(id) ON DELETE CASCADE,
 user_id uuid NOT NULL REFERENCES public.users(id),
 read_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(reminder_id,user_id)
);
ALTER TABLE public.reminder_notification_reads ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.reminder_notification_reads FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.reminder_notification_reads TO authenticated;
GRANT ALL ON public.reminder_notification_reads TO service_role;
CREATE POLICY own_reminder_receipts ON public.reminder_notification_reads FOR SELECT TO authenticated
 USING(user_id=auth.uid() AND public.whatsapp_panel_allowed());

CREATE FUNCTION public.my_reminder_notifications(p_limit integer DEFAULT 50)
RETURNS TABLE(id uuid,lead_name text,subject text,message text,scheduled_at timestamptz,
 status text,read_at timestamptz,unread_count bigint)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public AS $$
 SELECT r.id,l.name::text,r.subject,n.note::text,r.scheduled_at,
   CASE WHEN r.status='Enviado'
    AND EXISTS(SELECT 1 FROM public.whatsapp_reminders d WHERE d.reminder_id=r.id AND d.provider='dryrun')
    AND NOT EXISTS(SELECT 1 FROM public.whatsapp_reminders d WHERE d.reminder_id=r.id AND d.provider='meta')
    THEN 'Simulação (não enviado)' ELSE r.status END,receipt.read_at,
   count(*) FILTER(WHERE receipt.read_at IS NULL) OVER()
 FROM public.note_reminders r
 JOIN public.notes n ON n.id=r.note_id
 JOIN public.leads l ON l.id=r.lead_id
 LEFT JOIN public.reminder_notification_reads receipt ON receipt.reminder_id=r.id AND receipt.user_id=auth.uid()
 WHERE public.whatsapp_panel_allowed() AND NOT l.is_deleted
 AND r.scheduled_at<=now() AND r.status<>'Cancelado'
 AND (r.created_by=auth.uid() OR EXISTS(
   SELECT 1 FROM public.whatsapp_reminders d WHERE d.reminder_id=r.id
    AND d.recipient_user_id=auth.uid() AND d.status<>'Cancelado'))
 ORDER BY (receipt.read_at IS NULL) DESC,r.scheduled_at DESC,r.id
 LIMIT greatest(1,least(coalesce(p_limit,50),100));
$$;

CREATE FUNCTION public.mark_reminder_notification_read(p_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
BEGIN
 IF NOT public.whatsapp_panel_allowed() OR NOT EXISTS(
  SELECT 1 FROM public.note_reminders r JOIN public.leads l ON l.id=r.lead_id
  WHERE r.id=p_id AND NOT l.is_deleted AND r.scheduled_at<=now() AND r.status<>'Cancelado'
  AND (r.created_by=auth.uid() OR EXISTS(SELECT 1 FROM public.whatsapp_reminders d
   WHERE d.reminder_id=r.id AND d.recipient_user_id=auth.uid() AND d.status<>'Cancelado'))
 ) THEN RAISE EXCEPTION 'Notificação indisponível' USING ERRCODE='42501'; END IF;
 INSERT INTO public.reminder_notification_reads(reminder_id,user_id) VALUES(p_id,auth.uid())
 ON CONFLICT(reminder_id,user_id) DO NOTHING;
END;
$$;
REVOKE ALL ON FUNCTION public.my_reminder_notifications(integer),public.mark_reminder_notification_read(uuid)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.my_reminder_notifications(integer),public.mark_reminder_notification_read(uuid)
 TO authenticated,service_role;
