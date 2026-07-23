import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/pomodoro.dart';
import 'providers/pomodoro_providers.dart';
import 'widgets/focus_stats_chart.dart';
import 'widgets/timer_ring.dart';

class PomodoroPage extends ConsumerWidget {
  const PomodoroPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final TimerState timer = ref.watch(pomodoroTimerProvider);
    final int threshold = ref.watch(
        settingsControllerProvider.select((AppSettings s) => s.sessionsBeforeLongBreak));

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
                  child: Text('Focus', style: theme.textTheme.headlineMedium),
                ),
                IconButton.filledTonal(
                  tooltip: 'Focus mode',
                  onPressed: () {
                    Haptics.light();
                    Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const FocusModePage(),
                    ));
                  },
                  icon: const Icon(Icons.fullscreen_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(child: _PhasePill(phase: timer.phase)),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: TimerRing(
                progress: timer.progress,
                phase: timer.phase,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(timer.formatted,
                        style: theme.textTheme.displaySmall?.copyWith(
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures()
                            ])),
                    Text(timer.phase.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SessionDots(
                completed: timer.completedFocusSessions % threshold,
                total: threshold),
            const SizedBox(height: AppSpacing.xl),
            _Controls(timer: timer),
            const SizedBox(height: AppSpacing.xxl),
            const _StatsCard(),
          ],
        ),
      ),
    );
  }
}

class _PhasePill extends StatelessWidget {
  const _PhasePill({required this.phase});
  final PomodoroPhase phase;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(phase.isFocus ? Icons.bolt_rounded : Icons.coffee_rounded,
              size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(phase.label,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.primary)),
        ],
      ),
    );
  }
}

class _SessionDots extends StatelessWidget {
  const _SessionDots({required this.completed, required this.total});
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < total; i++)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < completed
                  ? scheme.primary
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls({required this.timer});
  final TimerState timer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PomodoroTimer controller = ref.read(pomodoroTimerProvider.notifier);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _CircleButton(
          icon: Icons.refresh_rounded,
          onTap: controller.reset,
          filled: false,
        ),
        const SizedBox(width: AppSpacing.xl),
        _PlayButton(
          isRunning: timer.isRunning,
          onTap: controller.toggle,
        ),
        const SizedBox(width: AppSpacing.xl),
        _CircleButton(
          icon: Icons.skip_next_rounded,
          onTap: controller.skip,
          filled: false,
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.isRunning, required this.onTap});
  final bool isRunning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: 88,
        height: 88,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: <Color>[AppColors.accentA, AppColors.accentB],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color(0x557C5CFF),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 44,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.filled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled
              ? scheme.primary
              : scheme.surfaceContainerHigh.withValues(alpha: 0.6),
          border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Icon(icon, color: scheme.onSurface),
      ),
    );
  }
}

class _StatsCard extends ConsumerWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<PomodoroStats> stats = ref.watch(pomodoroStatsProvider);
    return GlassCard(
      child: stats.when(
        loading: () => const SizedBox(
            height: 160, child: Center(child: CircularProgressIndicator())),
        error: (Object e, _) => Text('Error: $e'),
        data: (PomodoroStats s) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('This week', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                _Stat(label: 'Today', value: '${s.todayMinutes}m'),
                const SizedBox(width: AppSpacing.xl),
                _Stat(label: 'Sessions', value: '${s.todaySessions}'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FocusStatsChart(weekMinutes: s.weekMinutes),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(value,
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: theme.colorScheme.primary)),
        Text(label,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

/// A distraction-free full-screen timer.
class FocusModePage extends ConsumerWidget {
  const FocusModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final TimerState timer = ref.watch(pomodoroTimerProvider);
    final PomodoroTimer controller = ref.read(pomodoroTimerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.darkBgBottom,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close_fullscreen_rounded,
                    color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(timer.phase.label,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.white70)),
                  const SizedBox(height: AppSpacing.xl),
                  TimerRing(
                    progress: timer.progress,
                    phase: timer.phase,
                    size: 300,
                    child: Text(
                      timer.formatted,
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures()
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _PlayButton(
                      isRunning: timer.isRunning, onTap: controller.toggle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
