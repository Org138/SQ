/// Task model and dependency-gating rules for the `tasks` and
/// `task_dependencies` tables (see supabase/migrations).
///
/// A task is blocked while any task it depends on is not done. These rules
/// let the UI explain and disable blocked actions up front; the database
/// enforces the same rules with triggers (see the
/// enforce_task_dependency_gating migration), so direct API calls can't
/// bypass them.
library;

enum TaskStatus {
  todo('todo', 'To do'),
  inProgress('in_progress', 'In progress'),
  done('done', 'Done');

  const TaskStatus(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static TaskStatus fromDb(String value) =>
      TaskStatus.values.firstWhere((s) => s.dbValue == value);
}

class Task {
  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.dueDate,
  });

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        status: TaskStatus.fromDb(map['status'] as String),
        dueDate: map['due_date'] == null
            ? null
            : DateTime.parse(map['due_date'] as String),
      );

  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final DateTime? dueDate;
}

/// "[taskId] is blocked by [dependsOnTaskId]"
class TaskDependency {
  const TaskDependency(this.taskId, this.dependsOnTaskId);

  factory TaskDependency.fromMap(Map<String, dynamic> map) => TaskDependency(
      map['task_id'] as String, map['depends_on_task_id'] as String);

  final String taskId;
  final String dependsOnTaskId;
}

/// All of a user's tasks plus the links between them.
class TaskBoard {
  TaskBoard(List<Task> tasks, List<TaskDependency> dependencies)
      : tasks = List.unmodifiable(tasks) {
    for (final task in tasks) {
      _byId[task.id] = task;
    }
    for (final dep in dependencies) {
      // Ignore links to tasks we can't see.
      if (!_byId.containsKey(dep.taskId) ||
          !_byId.containsKey(dep.dependsOnTaskId)) {
        continue;
      }
      if (!(_dependsOn[dep.taskId] ?? const {}).contains(dep.dependsOnTaskId)) {
        _dependencies.add(dep);
      }
      _dependsOn.putIfAbsent(dep.taskId, () => {}).add(dep.dependsOnTaskId);
      _dependents.putIfAbsent(dep.dependsOnTaskId, () => {}).add(dep.taskId);
    }
  }

  final List<Task> tasks;
  final _dependencies = <TaskDependency>[];
  final _byId = <String, Task>{};
  final _dependsOn = <String, Set<String>>{};
  final _dependents = <String, Set<String>>{};

  /// The links between tasks on this board.
  List<TaskDependency> get dependencies => List.unmodifiable(_dependencies);

  /// A copy with [task] replacing the task with the same id, or added at the
  /// end if it's new (the list is ordered by creation time).
  TaskBoard withTask(Task task) {
    final index = tasks.indexWhere((t) => t.id == task.id);
    return TaskBoard(
      index == -1 ? [...tasks, task] : ([...tasks]..[index] = task),
      _dependencies,
    );
  }

  /// A copy without the task [id] or any link touching it, mirroring the
  /// `on delete cascade` foreign keys on `task_dependencies`.
  TaskBoard withoutTask(String id) => TaskBoard(
        tasks.where((t) => t.id != id).toList(),
        _dependencies
            .where((d) => d.taskId != id && d.dependsOnTaskId != id)
            .toList(),
      );

  /// A copy with the [added] links and without the [removed] ones.
  TaskBoard withDependencies({
    Iterable<TaskDependency> added = const [],
    Iterable<TaskDependency> removed = const [],
  }) {
    String key(TaskDependency d) => '${d.taskId}/${d.dependsOnTaskId}';
    final removedKeys = removed.map(key).toSet();
    return TaskBoard(tasks, [
      ..._dependencies.where((d) => !removedKeys.contains(key(d))),
      ...added,
    ]);
  }

  Task? byId(String id) => _byId[id];

  /// Tasks [task] depends on.
  List<Task> dependenciesOf(Task task) =>
      (_dependsOn[task.id] ?? const {}).map((id) => _byId[id]!).toList();

  /// Tasks that depend on [task].
  List<Task> dependentsOf(Task task) =>
      (_dependents[task.id] ?? const {}).map((id) => _byId[id]!).toList();

  /// Unfinished dependencies holding [task] back.
  List<Task> blockersOf(Task task) => dependenciesOf(task)
      .where((dep) => dep.status != TaskStatus.done)
      .toList();

  bool isBlocked(Task task) => blockersOf(task).isNotEmpty;

  List<Task> get inProgress =>
      tasks.where((t) => t.status == TaskStatus.inProgress).toList();

  List<Task> get ready => tasks
      .where((t) => t.status == TaskStatus.todo && !isBlocked(t))
      .toList();

  List<Task> get blocked => tasks
      .where((t) => t.status == TaskStatus.todo && isBlocked(t))
      .toList();

  List<Task> get done =>
      tasks.where((t) => t.status == TaskStatus.done).toList();

  /// Why [task] can't move to [to], or null if it can.
  String? statusChangeBlockedReason(Task task, TaskStatus to) {
    if (to == task.status) return null;
    if (to != TaskStatus.todo) {
      final blockers = blockersOf(task);
      if (blockers.isNotEmpty) {
        return 'Blocked by ${_titles(blockers)}';
      }
    }
    if (task.status == TaskStatus.done) {
      final started = dependentsOf(task)
          .where((t) => t.status != TaskStatus.todo)
          .toList();
      if (started.isNotEmpty) {
        return 'Can\'t reopen: ${_titles(started)} already started';
      }
    }
    return null;
  }

  /// Tasks [task] may depend on without creating a cycle.
  List<Task> dependencyCandidatesFor(Task task) =>
      tasks.where((t) => t.id != task.id && !_reaches(t.id, task.id)).toList();

  /// Why [task] can't have exactly [dependencyIds], or null if it can.
  String? dependencyChangeBlockedReason(Task task, Set<String> dependencyIds) {
    if (task.status == TaskStatus.todo) return null;
    final unfinished = dependencyIds
        .map((id) => _byId[id]!)
        .where((t) => t.status != TaskStatus.done)
        .toList();
    if (unfinished.isEmpty) return null;
    return '"${task.title}" has already started, so it can only depend on '
        'finished tasks. Not finished: ${_titles(unfinished)}';
  }

  /// Whether [from] transitively depends on [to].
  bool _reaches(String from, String to) {
    final seen = <String>{};
    final stack = [from];
    while (stack.isNotEmpty) {
      final id = stack.removeLast();
      if (id == to) return true;
      if (seen.add(id)) stack.addAll(_dependsOn[id] ?? const {});
    }
    return false;
  }

  static String _titles(List<Task> tasks) =>
      tasks.map((t) => '"${t.title}"').join(', ');
}
