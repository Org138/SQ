-- Row level security and dependency gating for tasks (see the create_tasks,
-- enforce_task_dependency_gating and combine_task_dependency_checks
-- migrations). Runs with `supabase test db`.
begin;
create extension if not exists pgtap with schema extensions;
select plan(15);

-- Alice and Bob sign up; the on_auth_user_created trigger gives each a profile.
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'bob@example.com');

select results_eq(
  $$ select count(*) from public.profiles
     where id in ('11111111-1111-1111-1111-111111111111',
                  '22222222-2222-2222-2222-222222222222') $$,
  array[2::bigint],
  'signing up creates a profile'
);

select ok(
  not has_function_privilege('authenticated', 'public.handle_new_user()', 'execute'),
  'handle_new_user can''t be called through the API'
);

select ok(
  not has_function_privilege('authenticated', 'public.check_task_dependency()', 'execute'),
  'check_task_dependency can''t be called through the API'
);

-- Alice: "Build" is blocked by "Design". Bob has one task of his own.
insert into public.tasks (id, owner_id, title) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Design'),
  ('aaaaaaaa-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'Build'),
  ('bbbbbbbb-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'Bob''s task');
insert into public.task_dependencies (task_id, depends_on_task_id) values
  ('aaaaaaaa-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000001');

-- Act as Alice
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select results_eq(
  'select count(*) from public.tasks',
  array[2::bigint],
  'users only see their own tasks'
);

select throws_ok(
  $$ insert into public.tasks (title, owner_id)
     values ('Not mine', '22222222-2222-2222-2222-222222222222') $$,
  '42501', null,
  'users can''t create tasks for someone else'
);

select throws_ok(
  $$ insert into public.task_dependencies (task_id, depends_on_task_id)
     values ('aaaaaaaa-0000-0000-0000-000000000001', 'bbbbbbbb-0000-0000-0000-000000000001') $$,
  '42501', null,
  'users can''t link their task to someone else''s'
);

select throws_ok(
  $$ insert into public.task_dependencies (task_id, depends_on_task_id)
     values ('aaaaaaaa-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001') $$,
  '23514', 'A task can''t depend on itself',
  'a task can''t depend on itself'
);

select throws_ok(
  $$ insert into public.task_dependencies (task_id, depends_on_task_id)
     values ('aaaaaaaa-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000002') $$,
  '23514', 'Dependency would create a cycle: "Build" already depends on "Design"',
  'dependencies can''t form a cycle'
);

select throws_ok(
  $$ update public.tasks set status = 'in_progress'
     where id = 'aaaaaaaa-0000-0000-0000-000000000002' $$,
  '23514', 'Blocked by "Design"',
  'a blocked task can''t be started'
);

select lives_ok(
  $$ update public.tasks set status = 'done'
     where id = 'aaaaaaaa-0000-0000-0000-000000000001' $$,
  'a task with no dependencies can be finished'
);

select lives_ok(
  $$ update public.tasks set status = 'in_progress'
     where id = 'aaaaaaaa-0000-0000-0000-000000000002' $$,
  'a task can be started once its dependencies are done'
);

select throws_ok(
  $$ update public.tasks set status = 'todo'
     where id = 'aaaaaaaa-0000-0000-0000-000000000001' $$,
  '23514', 'Can''t reopen: "Build" already started',
  'a done task can''t be reopened while a dependent has started'
);

insert into public.tasks (id, title) values
  ('aaaaaaaa-0000-0000-0000-000000000003', 'Write docs');
insert into public.tasks (id, title, status) values
  ('aaaaaaaa-0000-0000-0000-000000000004', 'Pick a name', 'done');

select throws_ok(
  $$ insert into public.task_dependencies (task_id, depends_on_task_id)
     values ('aaaaaaaa-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000003') $$,
  '23514',
  '"Build" has already started, so it can only depend on finished tasks. Not finished: "Write docs"',
  'a started task can''t gain an unfinished dependency'
);

select lives_ok(
  $$ insert into public.task_dependencies (task_id, depends_on_task_id)
     values ('aaaaaaaa-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000004') $$,
  'a started task can gain a finished dependency'
);

-- Act as Bob
select set_config('request.jwt.claims',
  '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}', true);

select results_eq(
  'select count(*) from public.task_dependencies',
  array[0::bigint],
  'users can''t see other users'' dependencies'
);

select * from finish();
rollback;
