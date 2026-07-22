import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/id.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/task.dart';
import 'providers/tasks_providers.dart';

class _EditableItem {
  _EditableItem({required this.id, required String text, required this.done})
      : controller = TextEditingController(text: text);
  final String id;
  final TextEditingController controller;
  bool done;
}

class TaskEditorPage extends ConsumerStatefulWidget {
  const TaskEditorPage({super.key, this.taskId});
  final String? taskId;

  @override
  ConsumerState<TaskEditorPage> createState() => _TaskEditorPageState();
}

class _TaskEditorPageState extends ConsumerState<TaskEditorPage> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final List<_EditableItem> _items = <_EditableItem>[];

  Priority _priority = Priority.medium;
  TaskStatus _status = TaskStatus.todo;
  DateTime? _deadline;
  bool _loading = true;
  bool _deleted = false;
  String? _existingId;
  late DateTime _createdAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.taskId != null) {
      final Task? task =
          await ref.read(tasksRepositoryProvider).getTask(widget.taskId!);
      if (task != null) {
        _existingId = task.id;
        _title.text = task.title;
        _notes.text = task.notes ?? '';
        _priority = task.priority;
        _status = task.status;
        _deadline = task.deadline;
        _createdAt = task.createdAt;
        for (final ChecklistItem item in task.items) {
          _items.add(_EditableItem(
              id: item.id, text: item.text, done: item.done));
        }
      } else {
        _createdAt = DateTime.now();
      }
    } else {
      _createdAt = DateTime.now();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    for (final _EditableItem item in _items) {
      item.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_deleted) return;
    final String title = _title.text.trim();
    if (title.isEmpty) return;
    final String id = _existingId ?? newId();
    final List<ChecklistItem> items = <ChecklistItem>[];
    for (int i = 0; i < _items.length; i++) {
      final _EditableItem e = _items[i];
      final String text = e.controller.text.trim();
      if (text.isEmpty) continue;
      items.add(ChecklistItem(
          id: e.id, taskId: id, text: text, done: e.done, position: i));
    }
    final Task task = Task(
      id: id,
      title: title,
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      priority: _priority,
      status: _status,
      deadline: _deadline,
      items: items,
    );
    _existingId = id;
    await ref.read(tasksControllerProvider).save(task);
  }

  Future<void> _pickDeadline() async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
    );
    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 9,
        time?.minute ?? 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CalendarSystem system = ref.watch(
        settingsControllerProvider.select((AppSettings s) => s.calendarSystem));

    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? _) => _save(),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(_existingId == null ? 'New task' : 'Edit task'),
          actions: <Widget>[
            if (_existingId != null)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _confirmDelete,
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: <Widget>[
                  TextField(
                    controller: _title,
                    style: theme.textTheme.titleLarge,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'Task title'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Priority', style: theme.textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<Priority>(
                    segments: <ButtonSegment<Priority>>[
                      for (final Priority p in Priority.values)
                        ButtonSegment<Priority>(
                          value: p,
                          label: Text(p.label),
                          icon: Icon(Icons.flag_rounded, color: p.color),
                        ),
                    ],
                    selected: <Priority>{_priority},
                    onSelectionChanged: (Set<Priority> value) {
                      Haptics.selection();
                      setState(() => _priority = value.first);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.event_rounded),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _deadline == null
                                ? 'No deadline'
                                : '${DateX.format(_deadline!, system)} · ${DateX.timeOfDay(_deadline!)}',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        if (_deadline != null)
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(() => _deadline = null),
                          ),
                        TextButton(
                          onPressed: _pickDeadline,
                          child: Text(_deadline == null ? 'Set' : 'Change'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: <Widget>[
                      Text('Checklist', style: theme.textTheme.labelLarge),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _items.add(_EditableItem(
                                id: newId(), text: '', done: false));
                          });
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add item'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ..._items.map(_buildItemRow),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Notes', style: theme.textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _notes,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                        hintText: 'Add details, links, context…'),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
      ),
    );
  }

  Widget _buildItemRow(_EditableItem item) {
    return Padding(
      key: ValueKey<String>(item.id),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Checkbox(
            value: item.done,
            onChanged: (bool? value) =>
                setState(() => item.done = value ?? false),
          ),
          Expanded(
            child: TextField(
              controller: item.controller,
              decoration: const InputDecoration(
                hintText: 'Checklist item',
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () {
              setState(() {
                item.controller.dispose();
                _items.remove(item);
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This cannot be undone.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && _existingId != null) {
      _deleted = true;
      await ref.read(tasksControllerProvider).delete(_existingId!);
      if (mounted) Navigator.of(context).pop();
    }
  }
}
