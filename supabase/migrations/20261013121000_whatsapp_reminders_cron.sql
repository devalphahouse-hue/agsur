-- Supabase Cron dispatches the official API worker once per minute.
-- Configure whatsapp_functions_url and whatsapp_dispatch_secret in Vault before activation.
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
SELECT cron.schedule('agsur-whatsapp-reminders', '* * * * *', $job$
  SELECT net.http_post(
    url := rtrim(u.decrypted_secret, '/') || '/whatsapp-reminders',
    headers := jsonb_build_object('Content-Type', 'application/json', 'Authorization', 'Bearer ' || s.decrypted_secret),
    body := '{}'::jsonb,
    timeout_milliseconds := 60000
  )
  FROM vault.decrypted_secrets u CROSS JOIN vault.decrypted_secrets s
  WHERE u.name = 'whatsapp_functions_url' AND s.name = 'whatsapp_dispatch_secret'
    AND length(u.decrypted_secret) > 0 AND length(s.decrypted_secret) > 0;
$job$);
