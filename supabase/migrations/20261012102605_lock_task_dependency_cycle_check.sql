-- The cycle check only sees committed links, so two links added at the same
-- moment (A blocked by B, and B blocked by A) could each pass it and leave a
-- cycle. Serialize dependency changes per task owner with a transaction-level
-- advisory lock: the second change waits for the first to commit, then its
-- check (a new statement, so a new snapshot under read committed) sees it.

create or replace function public.prevent_task_dependency_cycle()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- Both tasks normally share an owner (RLS requires it). Lock every owner
  -- involved, in a fixed order so two changes can't deadlock on each other.
  perform pg_advisory_xact_lock(hashtextextended('task_dependencies:' || owner_id::text, 0))
  from (
    select distinct t.owner_id
    from public.tasks t
    where t.id in (new.task_id, new.depends_on_task_id)
    order by t.owner_id
  ) owners;

  if exists (
    with recursive chain (id) as (
      select new.depends_on_task_id
      union
      select d.depends_on_task_id
      from public.task_dependencies d
      join chain c on d.task_id = c.id
    )
    select 1 from chain where id = new.task_id
  ) then
    raise exception 'Dependency would create a cycle: task % already depends on task %',
      new.depends_on_task_id, new.task_id;
  end if;
  return new;
end;
$$;
