-- No requests are made until both Vault secrets have been configured.
select cron.schedule('agsur-contract-signatures','* * * * *',$job$
 select net.http_post(
  url:=rtrim(u.decrypted_secret,'/')||'/contract-signatures',
  headers:=jsonb_build_object('Content-Type','application/json','x-agsur-signature-secret',s.decrypted_secret),
  body:='{}'::jsonb,timeout_milliseconds:=120000)
 from vault.decrypted_secrets u cross join vault.decrypted_secrets s
 where u.name='signature_functions_url' and s.name='signature_dispatch_secret'
 and length(u.decrypted_secret)>0 and length(s.decrypted_secret)>0;
$job$);
select cron.schedule('agsur-signature-log-retention','25 3 * * *',$job$
 delete from cron.job_run_details where jobid in (
  select jobid from cron.job where jobname in ('agsur-contract-signatures','agsur-signature-log-retention'))
 and end_time<now()-interval '7 days';
$job$);
