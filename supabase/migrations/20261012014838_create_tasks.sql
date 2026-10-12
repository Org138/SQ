-- Tasks owned by a profile, with "blocked by" dependencies between tasks

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid()
    references public.profiles (id) on delete cascade,
  title text not null check (char_length(trim(title)) > 0),
  description text,
  status text not null default 'todo'
    check (status in ('todo', 'in_progress', 'done')),
  due_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index tasks_owner_id_idx on public.tasks (owner_id);

create trigger tasks_set_updated_at
  before update on public.tasks
  for each row execute function public.set_updated_at();

-- task_id is blocked by depends_on_task_id
create table public.task_dependencies (
  task_id uuid not null references public.tasks (id) on delete cascade,
  depends_on_task_id uuid not null references public.tasks (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (task_id, depends_on_task_id),
  check (task_id <> depends_on_task_id)
);

create index task_dependencies_depends_on_idx
  on public.task_dependencies (depends_on_task_id);

-- Reject links that would create a cycle (A blocked by B blocked by ... A)
create function public.prevent_task_dependency_cycle()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
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

create trigger task_dependencies_prevent_cycle
  before insert or update on public.task_dependencies
  for each row execute function public.prevent_task_dependency_cycle();

-- Row level security: users only see and change their own tasks
alter table public.tasks enable row level security;

create policy "Users can view their own tasks"
  on public.tasks for select
  to authenticated
  using ((select auth.uid()) = owner_id);

create policy "Users can create their own tasks"
  on public.tasks for insert
  to authenticated
  with check ((select auth.uid()) = owner_id);

create policy "Users can update their own tasks"
  on public.tasks for update
  to authenticated
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy "Users can delete their own tasks"
  on public.tasks for delete
  to authenticated
  using ((select auth.uid()) = owner_id);

-- Dependencies are allowed only between two tasks the user owns
alter table public.task_dependencies enable row level security;

create policy "Users can view dependencies of their own tasks"
  on public.task_dependencies for select
  to authenticated
  using (
    exists (select 1 from public.tasks t
            where t.id = task_id and t.owner_id = (select auth.uid()))
  );

create policy "Users can link their own tasks"
  on public.task_dependencies for insert
  to authenticated
  with check (
    exists (select 1 from public.tasks t
            where t.id = task_id and t.owner_id = (select auth.uid()))
    and exists (select 1 from public.tasks t
                where t.id = depends_on_task_id and t.owner_id = (select auth.uid()))
  );

create policy "Users can unlink their own tasks"
  on public.task_dependencies for delete
  to authenticated
  using (
    exists (select 1 from public.tasks t
            where t.id = task_id and t.owner_id = (select auth.uid()))
  );
