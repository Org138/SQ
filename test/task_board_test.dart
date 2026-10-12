import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_quickstart/models/task.dart';

Task _task(String id, [TaskStatus status = TaskStatus.todo]) =>
    Task(id: id, title: id, status: status);

void main() {
  group('blocking', () {
    test('task is blocked until every dependency is done', () {
      final board = TaskBoard(
        [_task('a'), _task('b', TaskStatus.done), _task('c')],
        const [TaskDependency('a', 'b'), TaskDependency('a', 'c')],
      );
      final a = board.byId('a')!;
      expect(board.isBlocked(a), isTrue);
      expect(board.blockersOf(a).map((t) => t.id), ['c']);
      expect(board.blocked.map((t) => t.id), ['a']);
      expect(board.ready.map((t) => t.id), ['c']);
    });

    test('blocked task cannot start or finish but can stay todo', () {
      final board = TaskBoard(
          [_task('a'), _task('b')], const [TaskDependency('a', 'b')]);
      final a = board.byId('a')!;
      expect(board.statusChangeBlockedReason(a, TaskStatus.inProgress),
          contains('"b"'));
      expect(board.statusChangeBlockedReason(a, TaskStatus.done), isNotNull);
      expect(board.statusChangeBlockedReason(a, TaskStatus.todo), isNull);
    });

    test('unblocked task can start', () {
      final board = TaskBoard([_task('a'), _task('b', TaskStatus.done)],
          const [TaskDependency('a', 'b')]);
      expect(
          board.statusChangeBlockedReason(
              board.byId('a')!, TaskStatus.inProgress),
          isNull);
    });
  });

  group('reopening', () {
    test('done task cannot reopen once a dependent has started', () {
      final board = TaskBoard(
        [_task('a', TaskStatus.inProgress), _task('b', TaskStatus.done)],
        const [TaskDependency('a', 'b')],
      );
      expect(board.statusChangeBlockedReason(board.byId('b')!, TaskStatus.todo),
          contains('"a"'));
    });

    test('done task can reopen while dependents are still todo', () {
      final board = TaskBoard(
        [_task('a'), _task('b', TaskStatus.done)],
        const [TaskDependency('a', 'b')],
      );
      expect(board.statusChangeBlockedReason(board.byId('b')!, TaskStatus.todo),
          isNull);
    });
  });

  group('dependency editing', () {
    test('candidates exclude self and anything that would form a cycle', () {
      // a -> b -> c, d unrelated
      final board = TaskBoard(
        [_task('a'), _task('b'), _task('c'), _task('d')],
        const [TaskDependency('a', 'b'), TaskDependency('b', 'c')],
      );
      expect(board.dependencyCandidatesFor(board.byId('c')!).map((t) => t.id),
          ['d']);
      expect(board.dependencyCandidatesFor(board.byId('a')!).map((t) => t.id),
          ['b', 'c', 'd']);
    });

    test('started task may only depend on finished tasks', () {
      final board = TaskBoard([
        _task('a', TaskStatus.inProgress),
        _task('b'),
        _task('c', TaskStatus.done),
      ], const []);
      final a = board.byId('a')!;
      expect(board.dependencyChangeBlockedReason(a, {'b'}), contains('"b"'));
      expect(board.dependencyChangeBlockedReason(a, {'c'}), isNull);
    });
  });

  test('links to unknown tasks are ignored', () {
    final board = TaskBoard([_task('a')], const [TaskDependency('a', 'gone')]);
    expect(board.isBlocked(board.byId('a')!), isFalse);
  });

  test('parses database rows', () {
    final task = Task.fromMap({
      'id': '1',
      'title': 'Write spec',
      'description': null,
      'status': 'in_progress',
      'due_date': '2026-10-20',
    });
    expect(task.status, TaskStatus.inProgress);
    expect(task.dueDate, DateTime(2026, 10, 20));
  });
}
