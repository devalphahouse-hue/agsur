-- Keep the same named job; schedule() updates it instead of creating a second dispatcher.
SELECT cron.schedule('agsur-whatsapp-reminders', '* * * * *', $job$
 SELECT net.http_post(
  url:=rtrim(u.decrypted_secret,'/')||'/whatsapp-reminders',
  headers:=jsonb_build_object('Content-Type','application/json','x-agsur-cron-secret',s.decrypted_secret),
  body:='{}'::jsonb,timeout_milliseconds:=60000)
 FROM vault.decrypted_secrets u CROSS JOIN vault.decrypted_secrets s
 WHERE u.name='whatsapp_functions_url' AND s.name='whatsapp_dispatch_secret'
 AND length(u.decrypted_secret)>0 AND length(s.decrypted_secret)>0;
$job$);
-- Only our jobs' logs are pruned. pg_net has its own response TTL; do not delete other integrations' responses.
SELECT cron.schedule('agsur-whatsapp-log-retention','15 3 * * *',$job$
 DELETE FROM cron.job_run_details WHERE jobid IN (
 SELECT jobid FROM cron.job WHERE jobname IN ('agsur-whatsapp-reminders','agsur-whatsapp-log-retention'))
 AND end_time < now()-interval '7 days';
$job$);
