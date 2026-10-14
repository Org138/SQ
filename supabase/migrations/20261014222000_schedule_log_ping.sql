-- Calls the log-ping Edge Function at 00:00 UTC on days 1, 6, 11, 16, 21,
-- 26 and 31 of each month (cron can't count days across months, so the gap
-- at a month boundary is 1-5 days instead of exactly 5).
--
-- The project URL and publishable key come from Vault secrets named
-- 'project_url' and 'publishable_key', which are set per environment and
-- not stored here. Where they're missing (e.g. the local stack) the job
-- selects no rows and makes no request.
create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

select cron.schedule(
  'log-ping',
  '0 0 */5 * *',
  $$
  select net.http_post(
    url := url.decrypted_secret || '/functions/v1/log-ping',
    headers := jsonb_build_object('apikey', key.decrypted_secret)
  )
  from vault.decrypted_secrets url, vault.decrypted_secrets key
  where url.name = 'project_url' and key.name = 'publishable_key';
  $$
);
