// Runs the shared dependency gating cases against TaskBoard. The database
// runs the same cases (supabase/tests/database/dependency_rules.test.sql), so
// a rule that drifts on either side fails one of the two suites. Messages are
// checked in task_board_test.dart and tasks.test.sql; here only allow/deny.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqproject/models/task.dart';

typedef _Step = Map<String, dynamic>;

void main() {
  final fixture = jsonDecode(
    File('supabase/tests/fixtures/dependency_rules.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  for (final c in (fixture['cases'] as List).cast<Map<String, dynamic>>()) {
    test(c['name'] as String, () {
      var board = TaskBoard(
        [
          for (final MapEntry(:key, :value)
              in (c['tasks'] as Map<String, dynamic>).entries)
            Task(id: key, title: key, status: TaskStatus.fromDb(value as String)),
        ],
        [
          for (final link in (c['links'] as List).cast<List>())
            TaskDependency(link[0] as String, link[1] as String),
        ],
      );
      final steps = (c['steps'] as List).cast<_Step>();
      for (final (i, step) in steps.indexed) {
        final last = i == steps.length - 1;
        expect(_allowed(board, step), last ? c['expect'] == 'allow' : isTrue,
            reason: 'step ${i + 1}: $step');
        board = _apply(board, step);
      }
    });
  }
}

/// Whether the app would let [step] through, the way the tasks page asks.
bool _allowed(TaskBoard board, _Step step) {
  final task = board.byId(step['task'] as String)!;
  switch (step['action']) {
    case 'set_status':
      final to = TaskStatus.fromDb(step['to'] as String);
      return board.statusChangeBlockedReason(task, to) == null;
    case 'add_link':
      final dep = step['depends_on'] as String;
      final ids = {...board.dependenciesOf(task).map((t) => t.id), dep};
      return board.dependencyCandidatesFor(task).any((t) => t.id == dep) &&
          board.dependencyChangeBlockedReason(task, ids) == null;
    case 'remove_link' || 'delete_task':
      return true;
  }
  throw ArgumentError('unknown action: $step');
}

TaskBoard _apply(TaskBoard board, _Step step) {
  final id = step['task'] as String;
  return switch (step['action']) {
    'set_status' => board.withTask(Task(
        id: id, title: id, status: TaskStatus.fromDb(step['to'] as String))),
    'add_link' => board.withDependencies(
        added: [TaskDependency(id, step['depends_on'] as String)]),
    'remove_link' => board.withDependencies(
        removed: [TaskDependency(id, step['depends_on'] as String)]),
    'delete_task' => board.withoutTask(id),
    _ => throw ArgumentError('unknown action: $step'),
  };
}
