import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../developer_calculator/presentation/dev_calculator_page.dart';
import '../../notes/domain/note.dart';
import '../../notes/presentation/note_editor_page.dart';
import '../../notes/presentation/providers/notes_providers.dart';
import '../../notes/presentation/widgets/note_card.dart';
import '../../pomodoro/domain/pomodoro.dart';
import '../../pomodoro/presentation/providers/pomodoro_providers.dart';
import '../../settings/presentation/settings_page.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/providers/tasks_providers.dart';
import '../../tasks/presentation/task_editor_page.dart';
import '../../tasks/presentation/widgets/task_tile.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  String _greeting() {
    final int h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppSettings settings = ref.watch(settingsControllerProvider);
    final CalendarSystem system = settings.calendarSystem;
    final DateTime today = DateTime.now();

    final AsyncValue<List<Task>> plan = ref.watch(todayPlanProvider);
    final AsyncValue<List<Note>> recent = ref.watch(recentNotesProvider);
    final AsyncValue<PomodoroStats> stats = ref.watch(pomodoroStatsProvider);
    final TimerState timer = ref.watch(pomodoroTimerProvider);

    return AuraScaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 140),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(_greeting(), style: theme.textTheme.headlineMedium),
                      if (settings.showDualDates)
                        Text(DateX.dual(today),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant))
                      else
                        Text(DateX.format(today, system),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => _push(context, const DevCalculatorPage()),
                  icon: const Icon(Icons.calculate_rounded),
                  tooltip: 'Dev tools',
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filledTonal(
                  onPressed: () => _push(context, const SettingsPage()),
                  icon: const Icon(Icons.settings_rounded),
                  tooltip: 'Settings',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _QuickActions(
              onNote: () => _push(context, const NoteEditorPage()),
              onTask: () => _push(context, const TaskEditorPage()),
            ),
            if (!timer.isIdle) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              _ActiveFocusCard(timer: timer),
            ],
            const SizedBox(height: AppSpacing.sm),
            const SectionHeader(
                title: 'Productivity', icon: Icons.insights_rounded),
            _StatsRow(stats: stats, openTasks: plan.valueOrNull?.length ?? 0),
            const SizedBox(height: AppSpacing.sm),
            SectionHeader(
              title: "Today's plan",
              icon: Icons.today_rounded,
              subtitle: 'Due today or overdue',
            ),
            plan.when(
              loading: () => const _LoadingTile(),
              error: (Object e, _) => Text('Error: $e'),
              data: (List<Task> tasks) {
                if (tasks.isEmpty) {
                  return _emptyTile(theme, 'Nothing due — enjoy the calm ✨');
                }
                return Column(
                  children: <Widget>[
                    for (final Task task in tasks.take(4))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: TaskTile(
                          task: task,
                          system: system,
                          onToggle: () {
                            Haptics.success();
                            ref.read(tasksControllerProvider).toggleDone(task);
                          },
                          onTap: () =>
                              _push(context, TaskEditorPage(taskId: task.id)),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            const SectionHeader(
                title: 'Recent notes', icon: Icons.sticky_note_2_outlined),
            recent.when(
              loading: () => const _LoadingTile(),
              error: (Object e, _) => Text('Error: $e'),
              data: (List<Note> notes) {
                if (notes.isEmpty) {
                  return _emptyTile(theme, 'No notes yet — jot down an idea');
                }
                return Column(
                  children: <Widget>[
                    for (final Note note in notes.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: NoteCard(
                          note: note,
                          system: system,
                          onTap: () =>
                              _push(context, NoteEditorPage(noteId: note.id)),
                          onTogglePin: () =>
                              ref.read(notesControllerProvider).togglePin(note),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Haptics.light();
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Widget _emptyTile(ThemeData theme, String text) => GlassCard(
        child: Row(
          children: <Widget>[
            Icon(Icons.check_circle_outline_rounded,
                color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: Text(text, style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onNote, required this.onTask});
  final VoidCallback onNote;
  final VoidCallback onTask;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _ActionButton(
            icon: Icons.note_add_rounded,
            label: 'New note',
            onTap: onNote,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionButton(
            icon: Icons.add_task_rounded,
            label: 'New task',
            onTap: onTask,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _ActiveFocusCard extends ConsumerWidget {
  const _ActiveFocusCard({required this.timer});
  final TimerState timer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    return GlassCard(
      tint: AppColors.accentA.withValues(alpha: 0.2),
      child: Row(
        children: <Widget>[
          Icon(
            timer.phase.isFocus ? Icons.bolt_rounded : Icons.coffee_rounded,
            color: theme.colorScheme.primary,
            size: 30,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(timer.phase.label, style: theme.textTheme.titleSmall),
                Text(
                  '${timer.formatted} · ${timer.isRunning ? 'running' : 'paused'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: ref.read(pomodoroTimerProvider.notifier).toggle,
            icon: Icon(
                timer.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats, required this.openTasks});
  final AsyncValue<PomodoroStats> stats;
  final int openTasks;

  @override
  Widget build(BuildContext context) {
    final PomodoroStats? s = stats.valueOrNull;
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            value: '${s?.todayMinutes ?? 0}m',
            label: 'Focus today',
            color: AppColors.accentC,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            value: '${s?.todaySessions ?? 0}',
            label: 'Sessions',
            color: AppColors.accentB,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.pending_actions_rounded,
            value: '$openTasks',
            label: 'To do',
            color: AppColors.accentA,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.lg),
      child: Column(
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: theme.textTheme.titleLarge),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
