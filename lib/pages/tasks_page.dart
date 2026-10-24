import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqproject/components/auth_required_state.dart';
import 'package:sqproject/l10n/app_localizations.dart';
import 'package:sqproject/models/task.dart';
import 'package:sqproject/utils/constants.dart';
import 'package:sqproject/utils/error_messages.dart';

/// Lists the user's tasks grouped by state. A task can't be started or
/// finished until everything it depends on is done.
class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends AuthRequiredState<TasksPage> {
  TaskBoard _board = TaskBoard(const [], const []);
  var _loading = true;

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
    });
    try {
      final tasks = await supabase
          .from('tasks')
          .select(_taskColumns)
          .order('created_at', ascending: true);
      final dependencies = await supabase
          .from('task_dependencies')
          .select(_dependencyColumns);
      _board = TaskBoard(
        tasks.map(Task.fromMap).toList(),
        dependencies.map(TaskDependency.fromMap).toList(),
      );
    } catch (error) {
      if (mounted) {
        context.showErrorSnackBar(
            message: errorMessage(AppLocalizations.of(context), error));
      }
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  /// Runs [write] and updates the board from the rows it returns, so only
  /// the changed rows are downloaded rather than every list again. Triggers
  /// only modify the row being written, so the result matches a reload.
  /// Shows an error message if it fails (e.g. a gating trigger rejected
  /// it). Returns whether it succeeded.
  Future<bool> _write<T>(
    Future<T> Function() write,
    TaskBoard Function(TaskBoard board, T result) apply,
  ) async {
    final T result;
    try {
      result = await write();
    } catch (error) {
      if (mounted) {
        context.showErrorSnackBar(
            message: errorMessage(AppLocalizations.of(context), error));
      }
      return false;
    }
    if (!mounted) return false;
    setState(() {
      _board = apply(_board, result);
    });
    return true;
  }

  Future<void> _setStatus(Task task, TaskStatus status) async {
    final reason = _board.statusChangeBlockedReason(task, status);
    if (reason != null) {
      context.showErrorSnackBar(
          message: _reasonMessage(AppLocalizations.of(context), task, reason));
      return;
    }
    await _write(
      () => supabase
          .from('tasks')
          .update({'status': status.dbValue})
          .eq('id', task.id)
          .select(_taskColumns)
          .single(),
      (board, row) => board.withTask(Task.fromMap(row)),
    );
  }

  Future<void> _createTask() async {
    final result = await showDialog<_NewTask>(
      context: context,
      builder: (_) => const _NewTaskDialog(),
    );
    if (result == null) return;
    await _write(
      () => supabase
          .from('tasks')
          .insert({
            'title': result.title,
            if (result.description.isNotEmpty)
              'description': result.description,
            if (result.dueDate != null)
              'due_date': _formatDate(result.dueDate!),
          })
          .select(_taskColumns)
          .single(),
      (board, row) => board.withTask(Task.fromMap(row)),
    );
  }

  Future<void> _deleteTask(Task task) async {
    final dependents = _board.dependentsOf(task);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.deleteTaskTitle(task.title)),
          content: Text(dependents.isEmpty
              ? l10n.deleteCannotUndo
              : l10n.deleteAlsoUnlinks(_titles(dependents))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.deleteTask),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    // Only drop what the database says it deleted.
    await _write(
      () => supabase.from('tasks').delete().eq('id', task.id).select('id'),
      (board, rows) => rows.fold(
          board, (board, row) => board.withoutTask(row['id'] as String)),
    );
  }

  Future<void> _editDependencies(Task task) async {
    final current = _board.dependenciesOf(task).map((t) => t.id).toSet();
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _DependenciesDialog(
        task: task,
        candidates: _board.dependencyCandidatesFor(task),
        initial: current,
      ),
    );
    if (selected == null || !mounted) return;
    final reason = _board.dependencyChangeBlockedReason(task, selected);
    if (reason != null) {
      context.showErrorSnackBar(
          message: _reasonMessage(AppLocalizations.of(context), task, reason));
      return;
    }
    final added = selected.difference(current);
    final removed = current.difference(selected);
    if (added.isEmpty && removed.isEmpty) return;

    if (removed.isNotEmpty) {
      final ok = await _write(
        () => supabase
            .from('task_dependencies')
            .delete()
            .eq('task_id', task.id)
            .inFilter('depends_on_task_id', removed.toList())
            .select(_dependencyColumns),
        (board, rows) => board.withDependencies(
            removed: rows.map(TaskDependency.fromMap)),
      );
      if (!ok) return;
    }
    if (added.isNotEmpty) {
      await _write(
        () => supabase
            .from('task_dependencies')
            .insert([
              for (final id in added)
                {'task_id': task.id, 'depends_on_task_id': id}
            ])
            .select(_dependencyColumns),
        (board, rows) =>
            board.withDependencies(added: rows.map(TaskDependency.fromMap)),
      );
    }
  }

  @override
  void onAuthenticated(Session session) {
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myTasks),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadTasks,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.newTask,
        onPressed: _loading ? null : _createTask,
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);
    if (_loading && _board.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_board.tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.noTasks, textAlign: TextAlign.center),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          ..._section(l10n.sectionInProgress, _board.inProgress),
          ..._section(l10n.sectionReady, _board.ready),
          ..._section(l10n.sectionBlocked, _board.blocked),
          ..._section(l10n.sectionDone, _board.done),
        ],
      ),
    );
  }

  /// [tasks] under a [header] that's given their count.
  List<Widget> _section(String Function(int count) header, List<Task> tasks) {
    if (tasks.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(
          header(tasks.length),
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
      for (final task in tasks) _taskTile(task),
    ];
  }

  Widget _taskTile(Task task) {
    final l10n = AppLocalizations.of(context);
    final blockers = _board.blockersOf(task);
    final dependencies = _board.dependenciesOf(task);
    final details = <String>[
      if (task.description != null && task.description!.isNotEmpty)
        task.description!,
      if (task.dueDate != null) l10n.taskDue(task.dueDate!),
      if (blockers.isNotEmpty)
        l10n.waitingOn(blockers.map((t) => t.title).join(', '))
      else if (dependencies.isNotEmpty)
        l10n.dependsOn(dependencies.map((t) => t.title).join(', ')),
    ];

    return ListTile(
      leading: _statusIcon(task, blockers.isNotEmpty),
      title: Text(
        task.title,
        style: task.status == TaskStatus.done
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: details.isEmpty ? null : Text(details.join('\n')),
      isThreeLine: details.length > 1,
      trailing: PopupMenuButton<_TaskAction>(
        tooltip: l10n.taskActions,
        onSelected: (action) => _onAction(task, action),
        itemBuilder: (_) => [
          for (final status in TaskStatus.values)
            if (status != task.status)
              _statusMenuItem(task, status),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _TaskAction.dependencies,
            child: Text(l10n.editDependencies),
          ),
          PopupMenuItem(
            value: _TaskAction.delete,
            child: Text(l10n.deleteTask),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<_TaskAction> _statusMenuItem(Task task, TaskStatus status) {
    final l10n = AppLocalizations.of(context);
    final reason = _board.statusChangeBlockedReason(task, status);
    final label = switch (status) {
      TaskStatus.todo => l10n.moveToTodo,
      TaskStatus.inProgress => l10n.startTask,
      TaskStatus.done => l10n.markDone,
    };
    return PopupMenuItem(
      value: _TaskAction.values.byName(status.name),
      enabled: reason == null,
      child: reason == null
          ? Text(label)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                Text(_reasonMessage(l10n, task, reason),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
    );
  }

  Widget _statusIcon(Task task, bool blocked) {
    switch (task.status) {
      case TaskStatus.done:
        return const Icon(Icons.check_circle, color: Colors.green);
      case TaskStatus.inProgress:
        return blocked
            ? Tooltip(
                message: AppLocalizations.of(context).startedButBlocked,
                child: const Icon(Icons.warning_amber, color: Colors.orange),
              )
            : const Icon(Icons.timelapse, color: Colors.lightBlue);
      case TaskStatus.todo:
        return blocked
            ? const Icon(Icons.lock_outline, color: Colors.grey)
            : const Icon(Icons.radio_button_unchecked);
    }
  }

  void _onAction(Task task, _TaskAction action) {
    switch (action) {
      case _TaskAction.todo:
        _setStatus(task, TaskStatus.todo);
        break;
      case _TaskAction.inProgress:
        _setStatus(task, TaskStatus.inProgress);
        break;
      case _TaskAction.done:
        _setStatus(task, TaskStatus.done);
        break;
      case _TaskAction.dependencies:
        _editDependencies(task);
        break;
      case _TaskAction.delete:
        _deleteTask(task);
        break;
    }
  }
}

/// The message for [reason], which refused a change to [task].
String _reasonMessage(
        AppLocalizations l10n, Task task, BlockedReason reason) =>
    switch (reason) {
      BlockedByDependencies(:final tasks) => l10n.blockedBy(_titles(tasks)),
      DependentsStarted(:final tasks) => l10n.cantReopen(_titles(tasks)),
      DependenciesNotFinished(:final tasks) =>
        l10n.dependenciesNotFinished(task.title, _titles(tasks)),
    };

/// Quoted task titles, listed the way the database triggers list them.
String _titles(List<Task> tasks) =>
    tasks.map((t) => '"${t.title}"').join(', ');

String _statusLabel(AppLocalizations l10n, TaskStatus status) =>
    switch (status) {
      TaskStatus.todo => l10n.statusTodo,
      TaskStatus.inProgress => l10n.statusInProgress,
      TaskStatus.done => l10n.statusDone,
    };

const _taskColumns = 'id, title, description, status, due_date';
const _dependencyColumns = 'task_id, depends_on_task_id';

/// Status actions share names with [TaskStatus] values.
enum _TaskAction { todo, inProgress, done, dependencies, delete }

/// The `due_date` column's format. Shown dates use the locale's format.
String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class _NewTask {
  const _NewTask(this.title, this.description, this.dueDate);

  final String title;
  final String description;
  final DateTime? dueDate;
}

class _NewTaskDialog extends StatefulWidget {
  const _NewTaskDialog();

  @override
  _NewTaskDialogState createState() => _NewTaskDialogState();
}

class _NewTaskDialogState extends State<_NewTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context)
        .pop(_NewTask(title, _descriptionController.text.trim(), _dueDate));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.newTask),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.taskTitleLabel),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          TextField(
            controller: _descriptionController,
            decoration:
                InputDecoration(labelText: l10n.taskDescriptionLabel),
            maxLines: 3,
            minLines: 1,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(_dueDate == null
                    ? l10n.noDueDate
                    : l10n.taskDue(_dueDate!)),
              ),
              if (_dueDate != null)
                IconButton(
                  tooltip: l10n.clearDueDate,
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() {
                    _dueDate = null;
                  }),
                ),
              TextButton(
                onPressed: _pickDueDate,
                child: Text(l10n.pickDueDate),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _titleController.text.trim().isEmpty ? null : _submit,
          child: Text(l10n.addTask),
        ),
      ],
    );
  }
}

class _DependenciesDialog extends StatefulWidget {
  const _DependenciesDialog({
    required this.task,
    required this.candidates,
    required this.initial,
  });

  final Task task;
  final List<Task> candidates;
  final Set<String> initial;

  @override
  _DependenciesDialogState createState() => _DependenciesDialogState();
}

class _DependenciesDialogState extends State<_DependenciesDialog> {
  late final Set<String> _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.dependenciesTitle(widget.task.title)),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.candidates.isEmpty
            ? Text(l10n.noDependencyCandidates)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.dependenciesSelected(_selected.length)),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final candidate in widget.candidates)
                          CheckboxListTile(
                            value: _selected.contains(candidate.id),
                            title: Text(candidate.title),
                            subtitle:
                                Text(_statusLabel(l10n, candidate.status)),
                            onChanged: (checked) => setState(() {
                              if (checked == true) {
                                _selected.add(candidate.id);
                              } else {
                                _selected.remove(candidate.id);
                              }
                            }),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(l10n.saveDependencies),
        ),
      ],
    );
  }
}
