-- Combine the checks on new dependency links into one trigger, so the order
-- they run in (and the order they take locks in) is written down here rather
-- than following from trigger names, and give every refusal a readable
-- message with errcode check_violation, like the status gating errors.
--
-- Lock order: the per-owner advisory lock comes first, before any row lock.
-- Keep it that way when adding checks, so two link changes can't deadlock.

drop trigger task_dependencies_prevent_cycle on public.task_dependencies;
drop trigger task_dependencies_enforce_gating on public.task_dependencies;
drop function public.prevent_task_dependency_cycle();
drop function public.enforce_task_dependency_gating();

create function public.check_task_dependency()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  task_status text;
  task_title text;
  dependency_status text;
  dependency_title text;
begin
  -- 1. No self links (the check constraint is a backstop)
  if new.task_id = new.depends_on_task_id then
    raise exception 'A task can''t depend on itself'
      using errcode = 'check_violation';
  end if;

  -- 2. Serialize dependency changes per task owner, so the cycle check below
  -- sees links added at the same moment. Both tasks normally share an owner
  -- (RLS requires it); lock every owner involved, in a fixed order.
  perform pg_advisory_xact_lock(hashtextextended('task_dependencies:' || owner_id::text, 0))
  from (
    select distinct t.owner_id
    from public.tasks t
    where t.id in (new.task_id, new.depends_on_task_id)
    order by t.owner_id
  ) owners;

  -- 3. A started task may only depend on finished tasks
  select status, title into task_status, task_title
  from public.tasks where id = new.task_id
  for share;

  if task_status is distinct from 'todo' then
    select status, title into dependency_status, dependency_title
    from public.tasks where id = new.depends_on_task_id
    for share;

    if dependency_status is distinct from 'done' then
      raise exception '"%" has already started, so it can only depend on finished tasks. Not finished: "%"',
        task_title, dependency_title
        using errcode = 'check_violation';
    end if;
  end if;

  -- 4. No cycles (A blocked by B blocked by ... A)
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
    select title into dependency_title
    from public.tasks where id = new.depends_on_task_id;

    raise exception 'Dependency would create a cycle: "%" already depends on "%"',
      dependency_title, task_title
      using errcode = 'check_violation',
            hint = 'Remove one of the links first.';
  end if;

  return new;
end;
$$;

create trigger task_dependencies_check
  before insert or update on public.task_dependencies
  for each row execute function public.check_task_dependency();

-- Trigger-only function; keep it out of the RPC API
revoke execute on function public.check_task_dependency() from public, anon, authenticated;
