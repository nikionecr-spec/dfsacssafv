import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../domain/task.dart';
import 'providers/tasks_providers.dart';
import 'task_editor_page.dart';
import 'widgets/task_tile.dart';

class TasksPage extends ConsumerWidget {
  const TasksPage({super.key});

  void _openEditor(BuildContext context, String? id) {
    Haptics.light();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TaskEditorPage(taskId: id),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final CalendarSystem system = ref.watch(
        settingsControllerProvider.select((AppSettings s) => s.calendarSystem));
    final AsyncValue<List<Task>> tasks = ref.watch(tasksListProvider);
    final bool showCompleted = ref.watch(showCompletedTasksProvider);

    return AuraScaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () => _openEditor(context, null),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New task'),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text('Tasks', style: theme.textTheme.headlineMedium),
                  ),
                  FilterChip(
                    label: const Text('Completed'),
                    selected: showCompleted,
                    onSelected: (bool value) {
                      Haptics.selection();
                      ref.read(showCompletedTasksProvider.notifier).state = value;
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasks.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (Object e, _) => Center(child: Text('Error: $e')),
                data: (List<Task> items) {
                  if (items.isEmpty) {
                    return EmptyState(
                      icon: Icons.checklist_rounded,
                      title: 'No tasks',
                      message:
                          'Plan your day, add checklists and set deadlines with reminders.',
                      action: FilledButton.icon(
                        onPressed: () => _openEditor(context, null),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add a task'),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 120),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (BuildContext context, int i) {
                      final Task task = items[i];
                      return Dismissible(
                        key: ValueKey<String>(task.id),
                        direction: DismissDirection.endToStart,
                        background: _deleteBackground(theme),
                        onDismissed: (_) {
                          Haptics.medium();
                          ref.read(tasksControllerProvider).delete(task.id);
                        },
                        child: TaskTile(
                          task: task,
                          system: system,
                          onToggle: () {
                            Haptics.success();
                            ref.read(tasksControllerProvider).toggleDone(task);
                          },
                          onTap: () => _openEditor(context, task.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deleteBackground(ThemeData theme) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Icon(Icons.delete_rounded, color: theme.colorScheme.onErrorContainer),
    );
  }
}
