// Generates supabase/tests/database/dependency_rules.test.sql from the shared
// cases in supabase/tests/fixtures/dependency_rules.json, so pgTAP checks the
// same cases as test/dependency_rules_test.dart. pgTAP runs inside the
// database container and can't read the fixture itself.
//
//   dart run tool/generate_dependency_rules.dart          rewrites the file
//   dart run tool/generate_dependency_rules.dart --check  fails if it's stale
import 'dart:convert';
import 'dart:io';

const _fixture = 'supabase/tests/fixtures/dependency_rules.json';
const _output = 'supabase/tests/database/dependency_rules.test.sql';
const _owner = '33333333-3333-3333-3333-333333333333';

void main(List<String> args) {
  final fixture =
      jsonDecode(File(_fixture).readAsStringSync()) as Map<String, dynamic>;
  final sql =
      _generate((fixture['cases'] as List).cast<Map<String, dynamic>>());
  final file = File(_output);

  if (args.contains('--check')) {
    final current = file.existsSync()
        ? file.readAsStringSync().replaceAll('\r\n', '\n')
        : '';
    if (current != sql) {
      stderr.writeln('$_output is out of date. '
          'Run: dart run tool/generate_dependency_rules.dart');
      exitCode = 1;
    }
    return;
  }
  file.writeAsStringSync(sql);
}

String _generate(List<Map<String, dynamic>> cases) {
  final setup = StringBuffer();
  final checks = StringBuffer();
  var plan = 0;

  for (final (i, c) in cases.indexed) {
    final name = c['name'] as String;
    final names = (c['tasks'] as Map<String, dynamic>).keys.toList();
    // One set of tasks per case, so cases can't see each other's links
    String id(String task) => 'dddddddd-0000-0000-'
        '${'${i + 1}'.padLeft(4, '0')}-'
        '${'${names.indexOf(task) + 1}'.padLeft(12, '0')}';

    setup.writeln('-- ${i + 1}. $name');
    setup.writeln('insert into public.tasks (id, owner_id, title, status) values');
    final tasks = [
      for (final MapEntry(:key, :value)
          in (c['tasks'] as Map<String, dynamic>).entries)
        "  ('${id(key)}', '$_owner', ${_literal(key)}, ${_literal(value as String)})",
    ];
    setup.writeln('${tasks.join(',\n')};');
    final links = [
      for (final link in (c['links'] as List).cast<List>())
        "  ('${id(link[0] as String)}', '${id(link[1] as String)}')",
    ];
    if (links.isNotEmpty) {
      setup.writeln(
          'insert into public.task_dependencies (task_id, depends_on_task_id) values');
      setup.writeln('${links.join(',\n')};');
    }
    setup.writeln();

    final steps = (c['steps'] as List).cast<Map<String, dynamic>>();
    for (final (s, step) in steps.indexed) {
      final last = s == steps.length - 1;
      final description = _literal(
          last ? '${i + 1}. $name' : '${i + 1}. $name (step ${s + 1})');
      final statement = r'$$ ' + _statement(step, id) + r' $$';
      checks.writeln(last && c['expect'] == 'deny'
          ? "select throws_ok($statement, '23514', null, $description);"
          : 'select lives_ok($statement, $description);');
      plan++;
    }
  }

  return '''
-- GENERATED from $_fixture by tool/generate_dependency_rules.dart.
-- Don't edit by hand; change the fixture and run
--   dart run tool/generate_dependency_rules.dart
-- Each case is checked as allow (lives_ok) or deny (throws_ok with
-- check_violation). The app runs the same cases in
-- test/dependency_rules_test.dart.
begin;
create extension if not exists pgtap with schema extensions;
select plan($plan);

insert into auth.users (id, email) values
  ('$_owner', 'rules@example.com');

$setup-- Act as the owner, through RLS like the app
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "$_owner", "role": "authenticated"}', true);

$checks
select * from finish();
rollback;
''';
}

String _statement(Map<String, dynamic> step, String Function(String) id) {
  final task = id(step['task'] as String);
  return switch (step['action']) {
    'set_status' => 'update public.tasks set status = '
        "${_literal(step['to'] as String)} where id = '$task'",
    'add_link' => 'insert into public.task_dependencies '
        "(task_id, depends_on_task_id) values ('$task', "
        "'${id(step['depends_on'] as String)}')",
    'remove_link' => "delete from public.task_dependencies where task_id = '$task' "
        "and depends_on_task_id = '${id(step['depends_on'] as String)}'",
    'delete_task' => "delete from public.tasks where id = '$task'",
    _ => throw ArgumentError('unknown action: $step'),
  };
}

String _literal(String value) => "'${value.replaceAll("'", "''")}'";
