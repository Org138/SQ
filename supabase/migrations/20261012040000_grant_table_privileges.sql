-- Grant the API roles access to the app's tables explicitly. Newer Supabase
-- versions no longer grant this automatically to tables created in public,
-- so on a fresh database the app got "permission denied" instead of reaching
-- the row level security policies. RLS still decides which rows each user
-- can see and change; these grants only let the policies run.

-- "Profiles are viewable by everyone"
grant select on public.profiles to anon, authenticated;
grant insert, update on public.profiles to authenticated;

grant select, insert, update, delete on public.tasks to authenticated;

-- No update policy: links are added and removed, never edited
grant select, insert, delete on public.task_dependencies to authenticated;
