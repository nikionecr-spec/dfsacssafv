import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/id.dart';
import '../../../core/widgets/glass_card.dart';
import '../../notes/domain/note.dart';
import '../../notes/presentation/providers/notes_providers.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/providers/tasks_providers.dart';
import '../domain/calendar_event.dart';
import 'providers/calendar_providers.dart';

class EventEditorPage extends ConsumerStatefulWidget {
  const EventEditorPage({super.key, this.eventId, required this.day});

  final String? eventId;
  final DateTime day;

  @override
  ConsumerState<EventEditorPage> createState() => _EventEditorPageState();
}

class _EventEditorPageState extends ConsumerState<EventEditorPage> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();

  late DateTime _start;
  late DateTime _end;
  bool _allDay = false;
  int? _color;
  String? _noteId;
  String? _taskId;

  bool _loading = true;
  bool _deleted = false;
  String? _existingId;

  @override
  void initState() {
    super.initState();
    final DateTime base = DateX.dayOnly(widget.day);
    _start = base.add(const Duration(hours: 9));
    _end = base.add(const Duration(hours: 10));
    _load();
  }

  Future<void> _load() async {
    if (widget.eventId != null) {
      final CalendarEvent? event =
          await ref.read(eventsRepositoryProvider).getEvent(widget.eventId!);
      if (event != null) {
        _existingId = event.id;
        _title.text = event.title;
        _description.text = event.description ?? '';
        _start = event.start;
        _end = event.end;
        _allDay = event.allDay;
        _color = event.color;
        _noteId = event.noteId;
        _taskId = event.taskId;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_deleted) return;
    final String title = _title.text.trim();
    if (title.isEmpty) return;
    final String id = _existingId ?? newId();
    final CalendarEvent event = CalendarEvent(
      id: id,
      title: title,
      description:
          _description.text.trim().isEmpty ? null : _description.text.trim(),
      start: _start,
      end: _end.isBefore(_start) ? _start.add(const Duration(hours: 1)) : _end,
      allDay: _allDay,
      color: _color,
      noteId: _noteId,
      taskId: _taskId,
    );
    _existingId = id;
    await ref.read(calendarControllerProvider).save(event);
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final DateTime initial = isStart ? _start : _end;
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 2),
      lastDate: DateTime(initial.year + 5),
    );
    if (date == null || !mounted) return;
    TimeOfDay? time = TimeOfDay.fromDateTime(initial);
    if (!_allDay) {
      time = await showTimePicker(
          context: context, initialTime: TimeOfDay.fromDateTime(initial));
      if (time == null) return;
    }
    setState(() {
      final DateTime combined =
          DateTime(date.year, date.month, date.day, time!.hour, time.minute);
      if (isStart) {
        final Duration span = _end.difference(_start);
        _start = combined;
        _end = combined.add(span.isNegative ? const Duration(hours: 1) : span);
      } else {
        _end = combined;
      }
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
          title: Text(_existingId == null ? 'New event' : 'Edit event'),
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
                    decoration: const InputDecoration(hintText: 'Event title'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('All day'),
                      value: _allDay,
                      onChanged: (bool value) => setState(() => _allDay = value),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _timeRow(theme, system, 'Starts', _start,
                      () => _pickDateTime(isStart: true)),
                  const SizedBox(height: AppSpacing.sm),
                  _timeRow(theme, system, 'Ends', _end,
                      () => _pickDateTime(isStart: false)),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Color', style: theme.textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  _colorPicker(theme),
                  const SizedBox(height: AppSpacing.lg),
                  _linkRow(
                    theme,
                    icon: Icons.sticky_note_2_outlined,
                    label: 'Link note',
                    valueLabel: _noteId == null ? null : 'Linked',
                    onTap: _pickNote,
                    onClear:
                        _noteId == null ? null : () => setState(() => _noteId = null),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _linkRow(
                    theme,
                    icon: Icons.checklist_rounded,
                    label: 'Link task',
                    valueLabel: _taskId == null ? null : 'Linked',
                    onTap: _pickTask,
                    onClear:
                        _taskId == null ? null : () => setState(() => _taskId = null),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _description,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration:
                        const InputDecoration(hintText: 'Description…'),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
      ),
    );
  }

  Widget _timeRow(ThemeData theme, CalendarSystem system, String label,
      DateTime value, VoidCallback onTap) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Text(label, style: theme.textTheme.bodyLarge),
          const Spacer(),
          Text(
            _allDay
                ? DateX.format(value, system)
                : '${DateX.format(value, system)} · ${DateX.timeOfDay(value)}',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.edit_calendar_rounded, size: 18),
        ],
      ),
    );
  }

  Widget _colorPicker(ThemeData theme) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: <Widget>[
        for (final Color c in AppColors.palette)
          GestureDetector(
            onTap: () => setState(() => _color = c.toARGB32()),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _color == c.toARGB32()
                      ? theme.colorScheme.onSurface
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _linkRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String? valueLabel,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(valueLabel ?? label)),
          if (onClear != null)
            IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onClear),
        ],
      ),
    );
  }

  Future<void> _pickNote() async {
    final List<Note> notes =
        await ref.read(notesRepositoryProvider).getNotes(limit: 100);
    if (!mounted) return;
    final String? id = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'Link a note',
        entries: <({String id, String label})>[
          for (final Note n in notes)
            (id: n.id, label: n.title.isEmpty ? 'Untitled' : n.title),
        ],
      ),
    );
    if (id != null) setState(() => _noteId = id);
  }

  Future<void> _pickTask() async {
    final List<Task> tasks =
        await ref.read(tasksRepositoryProvider).getTasks();
    if (!mounted) return;
    final String? id = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'Link a task',
        entries: <({String id, String label})>[
          for (final Task t in tasks) (id: t.id, label: t.title),
        ],
      ),
    );
    if (id != null) setState(() => _taskId = id);
  }

  Future<void> _confirmDelete() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete event?'),
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
      await ref.read(calendarControllerProvider).delete(_existingId!);
      if (mounted) Navigator.of(context).pop();
    }
  }
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({required this.title, required this.entries});

  final String title;
  final List<({String id, String label})> entries;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: GlassCard(
          blur: true,
          radius: AppRadii.xl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text('Nothing to link yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      for (final ({String id, String label}) e in entries)
                        ListTile(
                          title: Text(e.label,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => Navigator.pop(context, e.id),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
