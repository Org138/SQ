import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_quickstart/components/auth_required_state.dart';
import 'package:supabase_quickstart/models/task.dart';
import 'package:supabase_quickstart/utils/constants.dart';

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
          .select('id, title, description, status, due_date')
          .order('created_at', ascending: true);
      final dependencies = await supabase
          .from('task_dependencies')
          .select('task_id, depends_on_task_id');
      _board = TaskBoard(
        tasks.map(Task.fromMap).toList(),
        dependencies.map(TaskDependency.fromMap).toList(),
      );
    } catch (error) {
      if (mounted) context.showErrorSnackBar(message: _errorMessage(error));
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  /// Runs [write], then reloads. Shows the database's message if it fails
  /// (e.g. a gating trigger rejected it). Returns whether it succeeded.
  Future<bool> _write(Future<void> Function() write) async {
    try {
      await write();
    } catch (error) {
      if (mounted) context.showErrorSnackBar(message: _errorMessage(error));
      return false;
    }
    if (!mounted) return false;
    await _loadTasks();
    return true;
  }

  Future<void> _setStatus(Task task, TaskStatus status) async {
    final reason = _board.statusChangeBlockedReason(task, status);
    if (reason != null) {
      context.showErrorSnackBar(message: reason);
      return;
    }
    await _write(() => supabase
        .from('tasks')
        .update({'status': status.dbValue}).eq('id', task.id));
  }

  Future<void> _createTask() async {
    final result = await showDialog<_NewTask>(
      context: context,
      builder: (_) => const _NewTaskDialog(),
    );
    if (result == null) return;
    await _write(() => supabase.from('tasks').insert({
          'title': result.title,
          if (result.description.isNotEmpty) 'description': result.description,
          if (result.dueDate != null) 'due_date': _formatDate(result.dueDate!),
        }));
  }

  Future<void> _deleteTask(Task task) async {
    final dependents = _board.dependentsOf(task);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${task.title}"?'),
        content: Text(dependents.isEmpty
            ? 'This can\'t be undone.'
            : 'It will also be removed as a dependency from '
                '${dependents.map((t) => '"${t.title}"').join(', ')}. '
                'This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _write(() => supabase.from('tasks').delete().eq('id', task.id));
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
      context.showErrorSnackBar(message: reason);
      return;
    }
    final added = selected.difference(current);
    final removed = current.difference(selected);
    if (added.isEmpty && removed.isEmpty) return;

    if (removed.isNotEmpty) {
      final ok = await _write(() => supabase
          .from('task_dependencies')
          .delete()
          .eq('task_id', task.id)
          .inFilter('depends_on_task_id', removed.toList()));
      if (!ok) return;
    }
    if (added.isNotEmpty) {
      await _write(() => supabase.from('task_dependencies').insert([
            for (final id in added)
              {'task_id': task.id, 'depends_on_task_id': id}
          ]));
    }
  }

  @override
  void onAuthenticated(Session session) {
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadTasks,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New task',
        onPressed: _loading ? null : _createTask,
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _board.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_board.tasks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No tasks yet. Tap + to add one, then link tasks that must be '
            'finished first.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          ..._section('In progress', _board.inProgress),
          ..._section('Ready to start', _board.ready),
          ..._section('Blocked', _board.blocked),
          ..._section('Done', _board.done),
        ],
      ),
    );
  }

  List<Widget> _section(String title, List<Task> tasks) {
    if (tasks.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(
          '$title (${tasks.length})',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
      for (final task in tasks) _taskTile(task),
    ];
  }

  Widget _taskTile(Task task) {
    final blockers = _board.blockersOf(task);
    final dependencies = _board.dependenciesOf(task);
    final details = <String>[
      if (task.description != null && task.description!.isNotEmpty)
        task.description!,
      if (task.dueDate != null) 'Due ${_formatDate(task.dueDate!)}',
      if (blockers.isNotEmpty)
        'Waiting on: ${blockers.map((t) => t.title).join(', ')}'
      else if (dependencies.isNotEmpty)
        'Depends on: ${dependencies.map((t) => t.title).join(', ')}',
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
        tooltip: 'Task actions',
        onSelected: (action) => _onAction(task, action),
        itemBuilder: (_) => [
          for (final status in TaskStatus.values)
            if (status != task.status)
              _statusMenuItem(task, status),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: _TaskAction.dependencies,
            child: Text('Edit dependencies…'),
          ),
          const PopupMenuItem(
            value: _TaskAction.delete,
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<_TaskAction> _statusMenuItem(Task task, TaskStatus status) {
    final reason = _board.statusChangeBlockedReason(task, status);
    final label = {
      TaskStatus.todo: 'Move back to To do',
      TaskStatus.inProgress: 'Start',
      TaskStatus.done: 'Mark done',
    }[status]!;
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
                Text(reason, style: Theme.of(context).textTheme.bodySmall),
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
            ? const Tooltip(
                message: 'Started, but a dependency is no longer done',
                child: Icon(Icons.warning_amber, color: Colors.orange),
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

/// Database errors carry a readable message (including the gating
/// triggers'); anything else, such as being offline, gets a generic one.
String _errorMessage(Object error) => error is PostgrestException
    ? error.message
    : "Couldn't reach the server. Check your connection and try again.";

/// Status actions share names with [TaskStatus] values.
enum _TaskAction { todo, inProgress, done, dependencies, delete }

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
    return AlertDialog(
      title: const Text('New task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Title'),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          TextField(
            controller: _descriptionController,
            decoration:
                const InputDecoration(labelText: 'Description (optional)'),
            maxLines: 3,
            minLines: 1,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(_dueDate == null
                    ? 'No due date'
                    : 'Due ${_formatDate(_dueDate!)}'),
              ),
              if (_dueDate != null)
                IconButton(
                  tooltip: 'Clear due date',
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() {
                    _dueDate = null;
                  }),
                ),
              TextButton(
                onPressed: _pickDueDate,
                child: const Text('Pick date'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _titleController.text.trim().isEmpty ? null : _submit,
          child: const Text('Add'),
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
    return AlertDialog(
      title: Text('"${widget.task.title}" is blocked by'),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.candidates.isEmpty
            ? const Text('No other tasks can be linked without creating a '
                'loop. Add more tasks first.')
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final candidate in widget.candidates)
                    CheckboxListTile(
                      value: _selected.contains(candidate.id),
                      title: Text(candidate.title),
                      subtitle: Text(candidate.status.label),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
