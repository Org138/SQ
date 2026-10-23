-- check_task_dependency() must stay volatile: under read committed a volatile
-- function takes a new snapshot for each statement, so the cycle check sees
-- links committed while it waited on the advisory lock. A stable function
-- reuses one snapshot and would let concurrent links form a cycle (see
-- supabase/tests/concurrency/dependency_cycle_race.sh). Volatile is already
-- the default; state it so nobody "optimizes" it away.
alter function public.check_task_dependency() volatile;

-- Trigger-only function; keep it out of the RPC API like the others
revoke execute on function public.set_updated_at() from public, anon, authenticated;
