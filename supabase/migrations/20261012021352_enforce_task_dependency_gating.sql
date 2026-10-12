-- Enforce dependency gating in the database, mirroring lib/models/task.dart,
-- so direct API calls can't bypass it:
--   1. A task can't move to in_progress or done while a dependency isn't done.
--   2. A done task can't be reopened while a dependent has started.
--   3. A started task can only gain dependencies that are already done.
-- Checked rows are locked FOR SHARE so concurrent changes can't both pass.

create function public.enforce_task_status_gating()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  blocker_titles text;
  started_titles text;
begin
  if new.status is not distinct from old.status then
    return new;
  end if;

  -- 1. Starting or finishing requires every dependency to be done
  if new.status <> 'todo' then
    select string_agg(format('"%s"', b.title), ', ' order by b.title)
      into blocker_titles
    from (
      select t.title, t.status
      from public.task_dependencies d
      join public.tasks t on t.id = d.depends_on_task_id
      where d.task_id = new.id
      for share of t
    ) b
    where b.status <> 'done';

    if blocker_titles is not null then
      raise exception 'Blocked by %', blocker_titles
        using errcode = 'check_violation',
              hint = 'Finish those tasks first.';
    end if;
  end if;

  -- 2. Reopening a done task requires no dependent to have started
  if old.status = 'done' then
    select string_agg(format('"%s"', s.title), ', ' order by s.title)
      into started_titles
    from (
      select t.title, t.status
      from public.task_dependencies d
      join public.tasks t on t.id = d.task_id
      where d.depends_on_task_id = new.id
      for share of t
    ) s
    where s.status <> 'todo';

    if started_titles is not null then
      raise exception 'Can''t reopen: % already started', started_titles
        using errcode = 'check_violation',
              hint = 'Move those tasks back to To do first.';
    end if;
  end if;

  return new;
end;
$$;

create trigger tasks_enforce_status_gating
  before update of status on public.tasks
  for each row execute function public.enforce_task_status_gating();

create function public.enforce_task_dependency_gating()
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
  select status, title into task_status, task_title
  from public.tasks where id = new.task_id
  for share;

  -- 3. A started task may only depend on finished tasks
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

  return new;
end;
$$;

create trigger task_dependencies_enforce_gating
  before insert or update on public.task_dependencies
  for each row execute function public.enforce_task_dependency_gating();

-- Trigger-only functions; keep them out of the RPC API
revoke execute on function public.enforce_task_status_gating() from public, anon, authenticated;
revoke execute on function public.enforce_task_dependency_gating() from public, anon, authenticated;
