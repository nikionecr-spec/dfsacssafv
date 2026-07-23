import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/date_x.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../notes/domain/note.dart';
import '../../../notes/presentation/note_editor_page.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../../../tasks/domain/task.dart';
import '../../../tasks/presentation/providers/tasks_providers.dart';
import '../../../tasks/presentation/task_editor_page.dart';
import '../../domain/calendar_event.dart';
import '../event_editor_page.dart';
import '../providers/calendar_providers.dart';

/// Everything scheduled or linked to [day]: events, notes linked to the day,
/// and tasks due that day.
class DayAgenda extends ConsumerWidget {
  const DayAgenda({super.key, required this.day, required this.system});

  final DateTime day;
  final CalendarSystem system;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<CalendarEvent>> events =
        ref.watch(eventsForDayProvider(day));
    final AsyncValue<List<Note>> notes = ref.watch(notesForDayProvider(day));
    final AsyncValue<List<Task>> tasks = ref.watch(tasksForDayProvider(day));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 140),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                DateX.relativeDay(day, system),
                style: theme.textTheme.titleMedium,
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () {
                Haptics.light();
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => EventEditorPage(day: day),
                ));
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Event'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        events.when(
          loading: () => const SizedBox.shrink(),
          error: (Object e, _) => Text('Error: $e'),
          data: (List<CalendarEvent> items) {
            if (items.isEmpty) {
              return _muted(theme, 'No events');
            }
            return Column(
              children: <Widget>[
                for (final CalendarEvent event in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _EventRow(event: event),
                  ),
              ],
            );
          },
        ),
        _sectionData<Note>(
          theme,
          title: 'Linked notes',
          async: notes,
          builder: (Note note) => GlassCard(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => NoteEditorPage(noteId: note.id),
            )),
            child: Row(
              children: <Widget>[
                const Icon(Icons.sticky_note_2_outlined, size: 18),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(note.title.isEmpty ? 'Untitled' : note.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
        _sectionData<Task>(
          theme,
          title: 'Tasks due',
          async: tasks,
          builder: (Task task) => GlassCard(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => TaskEditorPage(taskId: task.id),
            )),
            child: Row(
              children: <Widget>[
                Icon(Icons.flag_rounded, size: 18, color: task.priority.color),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(task.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Text(DateX.timeOfDay(task.deadline ?? day),
                    style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionData<T>(
    ThemeData theme, {
    required String title,
    required AsyncValue<List<T>> async,
    required Widget Function(T) builder,
  }) {
    return async.maybeWhen(
      data: (List<T> items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            for (final T item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: builder(item),
              ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _muted(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(text,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      );
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});
  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent =
        event.color != null ? Color(event.color!) : theme.colorScheme.primary;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => EventEditorPage(eventId: event.id, day: event.start),
      )),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(event.title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  event.allDay
                      ? 'All day'
                      : '${DateX.timeOfDay(event.start)} – ${DateX.timeOfDay(event.end)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
