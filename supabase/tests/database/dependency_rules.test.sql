-- GENERATED from supabase/tests/fixtures/dependency_rules.json by tool/generate_dependency_rules.dart.
-- Don't edit by hand; change the fixture and run
--   dart run tool/generate_dependency_rules.dart
-- Each case is checked as allow (lives_ok) or deny (throws_ok with
-- check_violation). The app runs the same cases in
-- test/dependency_rules_test.dart.
begin;
create extension if not exists pgtap with schema extensions;
select plan(26);

insert into auth.users (id, email) values
  ('33333333-3333-3333-3333-333333333333', 'rules@example.com');

-- 1. a task can't start while a dependency isn't done
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0001-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'todo'),
  ('dddddddd-0000-0000-0001-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'todo');
insert into public.task_dependencies (task_id, depends_on_task_id) values
  ('dddddddd-0000-0000-0001-000000000001', 'dddddddd-0000-0000-0001-000000000002');

-- 2. a task can't be finished while a dependency isn't done
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0002-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'todo'),
  ('dddddddd-0000-0000-0002-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'in_progress');
insert into public.task_dependencies (task_id, depends_on_task_id) values
  ('dddddddd-0000-0000-0002-000000000001', 'dddddddd-0000-0000-0002-000000000002');

-- 3. a task can't start while any one dependency isn't done
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0003-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'todo'),
  ('dddddddd-0000-0000-0003-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'done'),
  ('dddddddd-0000-0000-0003-000000000003', '33333333-3333-3333-3333-333333333333', 'C', 'todo');
insert into public.task_dependencies (task_id, depends_on_task_id) values
  ('dddddddd-0000-0000-0003-000000000001', 'dddddddd-0000-0000-0003-000000000002'),
  ('dddddddd-0000-0000-0003-000000000001', 'dddddddd-0000-0000-0003-000000000003');

-- 4. a task can start once every dependency is done
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0004-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'todo'),
  ('dddddddd-0000-0000-0004-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'done'),
  ('dddddddd-0000-0000-0004-000000000003', '33333333-3333-3333-3333-333333333333', 'C', 'done');
insert into public.task_dependencies (task_id, depends_on_task_id) values
  ('dddddddd-0000-0000-0004-000000000001', 'dddddddd-0000-0000-0004-000000000002'),
  ('dddddddd-0000-0000-0004-000000000001', 'dddddddd-0000-0000-0004-000000000003');

-- 5. a task with no dependencies can be finished
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0005-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'todo');

-- 6. a blocked task can stay todo
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0006-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'todo'),
  ('dddddddd-0000-0000-0006-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'todo');
insert into public.task_dependencies (task_id, depends_on_task_id) values
  ('dddddddd-0000-0000-0006-000000000001', 'dddddddd-0000-0000-0006-000000000002');

-- 7. a started task can move back to todo
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0007-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'in_progress'),
  ('dddddddd-0000-0000-0007-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'done');
insert into public.task_dependencies (task_id, depends_on_task_id) values
  ('dddddddd-0000-0000-0007-000000000001', 'dddddddd-0000-0000-0007-000000000002');

-- 8. a done task can't be reopened while a dependent has started
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0008-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'in_progress'),
  ('dddddddd-0000-0000-0008-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'done');
insert into public.task_dependencies (task_id, depends_on_task_id) values
  ('dddddddd-0000-0000-0008-000000000001', 'dddddddd-0000-0000-0008-000000000002');

-- 9. a done task can't move back to in progress while a dependent is done
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0009-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'done'),
  ('dddddddd-0000-0000-0009-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'done');
insert into public.task_dependencies (task_id, depends_on_task_id) values
  ('dddddddd-0000-0000-0009-000000000001', 'dddddddd-0000-0000-0009-000000000002');

-- 10. a done task can be reopened while its dependents are todo
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0010-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'todo'),
  ('dddddddd-0000-0000-0010-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'done');
insert into public.task_dependencies (task_id, depends_on_task_id) values
  ('dddddddd-0000-0000-0010-000000000001', 'dddddddd-0000-0000-0010-000000000002');

-- 11. a task can't depend on itself
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0011-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'todo');

-- 12. two tasks can't depend on each other
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0012-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'todo'),
  ('dddddddd-0000-0000-0012-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'todo');
insert into public.task_dependencies (task_id, depends_on_task_id) values
  ('dddddddd-0000-0000-0012-000000000001', 'dddddddd-0000-0000-0012-000000000002');

-- 13. a longer chain can't loop back
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0013-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'todo'),
  ('dddddddd-0000-0000-0013-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'todo'),
  ('dddddddd-0000-0000-0013-000000000003', '33333333-3333-3333-3333-333333333333', 'C', 'todo');
insert into public.task_dependencies (task_id, depends_on_task_id) values
  ('dddddddd-0000-0000-0013-000000000001', 'dddddddd-0000-0000-0013-000000000002'),
  ('dddddddd-0000-0000-0013-000000000002', 'dddddddd-0000-0000-0013-000000000003');

-- 14. a shortcut along a chain is not a cycle
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0014-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'todo'),
  ('dddddddd-0000-0000-0014-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'todo'),
  ('dddddddd-0000-0000-0014-000000000003', '33333333-3333-3333-3333-333333333333', 'C', 'todo');
insert into public.task_dependencies (task_id, depends_on_task_id) values
  ('dddddddd-0000-0000-0014-000000000001', 'dddddddd-0000-0000-0014-000000000002'),
  ('dddddddd-0000-0000-0014-000000000002', 'dddddddd-0000-0000-0014-000000000003');

-- 15. a todo task can gain an unfinished dependency
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0015-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'todo'),
  ('dddddddd-0000-0000-0015-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'in_progress');

-- 16. a started task can't gain an unfinished dependency
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0016-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'in_progress'),
  ('dddddddd-0000-0000-0016-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'todo');

-- 17. a done task can't gain an unfinished dependency
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0017-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'done'),
  ('dddddddd-0000-0000-0017-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'in_progress');

-- 18. a started task can gain a finished dependency
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0018-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'in_progress'),
  ('dddddddd-0000-0000-0018-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'done');

-- 19. deleting an unfinished blocker lets its dependents start
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0019-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'todo'),
  ('dddddddd-0000-0000-0019-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'todo');
insert into public.task_dependencies (task_id, depends_on_task_id) values
  ('dddddddd-0000-0000-0019-000000000001', 'dddddddd-0000-0000-0019-000000000002');

-- 20. removing a dependency link unblocks the task
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0020-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'todo'),
  ('dddddddd-0000-0000-0020-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'todo');
insert into public.task_dependencies (task_id, depends_on_task_id) values
  ('dddddddd-0000-0000-0020-000000000001', 'dddddddd-0000-0000-0020-000000000002');

-- 21. finishing the blocker unblocks the task
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0021-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'todo'),
  ('dddddddd-0000-0000-0021-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'in_progress');
insert into public.task_dependencies (task_id, depends_on_task_id) values
  ('dddddddd-0000-0000-0021-000000000001', 'dddddddd-0000-0000-0021-000000000002');

-- 22. a link added after starting still blocks reopening the dependency
insert into public.tasks (id, owner_id, title, status) values
  ('dddddddd-0000-0000-0022-000000000001', '33333333-3333-3333-3333-333333333333', 'A', 'in_progress'),
  ('dddddddd-0000-0000-0022-000000000002', '33333333-3333-3333-3333-333333333333', 'B', 'done');

-- Act as the owner, through RLS like the app
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}', true);

select throws_ok($$ update public.tasks set status = 'in_progress' where id = 'dddddddd-0000-0000-0001-000000000001' $$, '23514', null, '1. a task can''t start while a dependency isn''t done');
select throws_ok($$ update public.tasks set status = 'done' where id = 'dddddddd-0000-0000-0002-000000000001' $$, '23514', null, '2. a task can''t be finished while a dependency isn''t done');
select throws_ok($$ update public.tasks set status = 'in_progress' where id = 'dddddddd-0000-0000-0003-000000000001' $$, '23514', null, '3. a task can''t start while any one dependency isn''t done');
select lives_ok($$ update public.tasks set status = 'in_progress' where id = 'dddddddd-0000-0000-0004-000000000001' $$, '4. a task can start once every dependency is done');
select lives_ok($$ update public.tasks set status = 'done' where id = 'dddddddd-0000-0000-0005-000000000001' $$, '5. a task with no dependencies can be finished');
select lives_ok($$ update public.tasks set status = 'todo' where id = 'dddddddd-0000-0000-0006-000000000001' $$, '6. a blocked task can stay todo');
select lives_ok($$ update public.tasks set status = 'todo' where id = 'dddddddd-0000-0000-0007-000000000001' $$, '7. a started task can move back to todo');
select throws_ok($$ update public.tasks set status = 'todo' where id = 'dddddddd-0000-0000-0008-000000000002' $$, '23514', null, '8. a done task can''t be reopened while a dependent has started');
select throws_ok($$ update public.tasks set status = 'in_progress' where id = 'dddddddd-0000-0000-0009-000000000002' $$, '23514', null, '9. a done task can''t move back to in progress while a dependent is done');
select lives_ok($$ update public.tasks set status = 'todo' where id = 'dddddddd-0000-0000-0010-000000000002' $$, '10. a done task can be reopened while its dependents are todo');
select throws_ok($$ insert into public.task_dependencies (task_id, depends_on_task_id) values ('dddddddd-0000-0000-0011-000000000001', 'dddddddd-0000-0000-0011-000000000001') $$, '23514', null, '11. a task can''t depend on itself');
select throws_ok($$ insert into public.task_dependencies (task_id, depends_on_task_id) values ('dddddddd-0000-0000-0012-000000000002', 'dddddddd-0000-0000-0012-000000000001') $$, '23514', null, '12. two tasks can''t depend on each other');
select throws_ok($$ insert into public.task_dependencies (task_id, depends_on_task_id) values ('dddddddd-0000-0000-0013-000000000003', 'dddddddd-0000-0000-0013-000000000001') $$, '23514', null, '13. a longer chain can''t loop back');
select lives_ok($$ insert into public.task_dependencies (task_id, depends_on_task_id) values ('dddddddd-0000-0000-0014-000000000001', 'dddddddd-0000-0000-0014-000000000003') $$, '14. a shortcut along a chain is not a cycle');
select lives_ok($$ insert into public.task_dependencies (task_id, depends_on_task_id) values ('dddddddd-0000-0000-0015-000000000001', 'dddddddd-0000-0000-0015-000000000002') $$, '15. a todo task can gain an unfinished dependency');
select throws_ok($$ insert into public.task_dependencies (task_id, depends_on_task_id) values ('dddddddd-0000-0000-0016-000000000001', 'dddddddd-0000-0000-0016-000000000002') $$, '23514', null, '16. a started task can''t gain an unfinished dependency');
select throws_ok($$ insert into public.task_dependencies (task_id, depends_on_task_id) values ('dddddddd-0000-0000-0017-000000000001', 'dddddddd-0000-0000-0017-000000000002') $$, '23514', null, '17. a done task can''t gain an unfinished dependency');
select lives_ok($$ insert into public.task_dependencies (task_id, depends_on_task_id) values ('dddddddd-0000-0000-0018-000000000001', 'dddddddd-0000-0000-0018-000000000002') $$, '18. a started task can gain a finished dependency');
select lives_ok($$ delete from public.tasks where id = 'dddddddd-0000-0000-0019-000000000002' $$, '19. deleting an unfinished blocker lets its dependents start (step 1)');
select lives_ok($$ update public.tasks set status = 'in_progress' where id = 'dddddddd-0000-0000-0019-000000000001' $$, '19. deleting an unfinished blocker lets its dependents start');
select lives_ok($$ delete from public.task_dependencies where task_id = 'dddddddd-0000-0000-0020-000000000001' and depends_on_task_id = 'dddddddd-0000-0000-0020-000000000002' $$, '20. removing a dependency link unblocks the task (step 1)');
select lives_ok($$ update public.tasks set status = 'in_progress' where id = 'dddddddd-0000-0000-0020-000000000001' $$, '20. removing a dependency link unblocks the task');
select lives_ok($$ update public.tasks set status = 'done' where id = 'dddddddd-0000-0000-0021-000000000002' $$, '21. finishing the blocker unblocks the task (step 1)');
select lives_ok($$ update public.tasks set status = 'in_progress' where id = 'dddddddd-0000-0000-0021-000000000001' $$, '21. finishing the blocker unblocks the task');
select lives_ok($$ insert into public.task_dependencies (task_id, depends_on_task_id) values ('dddddddd-0000-0000-0022-000000000001', 'dddddddd-0000-0000-0022-000000000002') $$, '22. a link added after starting still blocks reopening the dependency (step 1)');
select throws_ok($$ update public.tasks set status = 'todo' where id = 'dddddddd-0000-0000-0022-000000000002' $$, '23514', null, '22. a link added after starting still blocks reopening the dependency');

select * from finish();
rollback;
