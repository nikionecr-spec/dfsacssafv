import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/settings/settings_controller.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/id.dart';
import '../../data/pomodoro_repository.dart';
import '../../domain/pomodoro.dart';

final pomodoroRepositoryProvider = Provider<PomodoroRepository>(
  (ref) => PomodoroRepository(ref.watch(databaseProvider)),
);

final pomodoroStatsProvider = FutureProvider.autoDispose<PomodoroStats>(
  (ref) => ref.watch(pomodoroRepositoryProvider).stats(),
);

/// Drives the countdown, phase transitions, statistics logging and the ongoing
/// notification. Lives for the whole app session so the timer keeps running
/// while you move between tabs.
class PomodoroTimer extends Notifier<TimerState> {
  Timer? _ticker;
  DateTime? _phaseStart;

  @override
  TimerState build() {
    ref.read(notificationServiceProvider).onAction = _handleAction;
    ref.onDispose(() => _ticker?.cancel());

    // Keep an idle timer in sync with the durations chosen in settings.
    ref.listen<AppSettings>(settingsControllerProvider, (AppSettings? _, AppSettings __) {
      if (!state.isRunning && state.isIdle) {
        _setupPhase(state.phase, autoStart: false);
      }
    });

    final int total = _durationFor(PomodoroPhase.focus);
    return TimerState(
      phase: PomodoroPhase.focus,
      totalSeconds: total,
      remainingSeconds: total,
      isRunning: false,
      completedFocusSessions: 0,
    );
  }

  int _durationFor(PomodoroPhase phase) {
    final AppSettings s = ref.read(settingsControllerProvider);
    return switch (phase) {
      PomodoroPhase.focus => s.focusMinutes * 60,
      PomodoroPhase.shortBreak => s.shortBreakMinutes * 60,
      PomodoroPhase.longBreak => s.longBreakMinutes * 60,
    };
  }

  void start() {
    if (state.isRunning) return;
    Haptics.light();
    _phaseStart ??= DateTime.now();
    state = state.copyWith(isRunning: true);
    _startTicker();
    _updateNotification();
  }

  void pause() {
    _ticker?.cancel();
    state = state.copyWith(isRunning: false);
    _updateNotification();
  }

  void toggle() => state.isRunning ? pause() : start();

  void reset() {
    _ticker?.cancel();
    _phaseStart = null;
    _setupPhase(state.phase, autoStart: false);
  }

  void skip() {
    _ticker?.cancel();
    Haptics.medium();
    if (state.phase.isFocus) {
      final int threshold =
          ref.read(settingsControllerProvider).sessionsBeforeLongBreak;
      final PomodoroPhase next =
          ((state.completedFocusSessions + 1) % threshold == 0)
              ? PomodoroPhase.longBreak
              : PomodoroPhase.shortBreak;
      _setupPhase(next, autoStart: false);
    } else {
      _setupPhase(PomodoroPhase.focus, autoStart: false);
    }
  }

  void stop() {
    _ticker?.cancel();
    _phaseStart = null;
    final int total = _durationFor(PomodoroPhase.focus);
    state = TimerState(
      phase: PomodoroPhase.focus,
      totalSeconds: total,
      remainingSeconds: total,
      isRunning: false,
      completedFocusSessions: 0,
    );
    ref.read(notificationServiceProvider).cancelPomodoro();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final int remaining = state.remainingSeconds - 1;
    if (remaining <= 0) {
      unawaited(_completePhase());
    } else {
      state = state.copyWith(remainingSeconds: remaining);
      _updateNotification();
    }
  }

  Future<void> _completePhase() async {
    _ticker?.cancel();
    Haptics.heavy();

    if (state.phase.isFocus) {
      final DateTime start = _phaseStart ??
          DateTime.now().subtract(Duration(seconds: state.totalSeconds));
      await ref.read(pomodoroRepositoryProvider).insertSession(
            PomodoroSession(
              id: newId(),
              start: start,
              end: DateTime.now(),
              focusSeconds: state.totalSeconds,
            ),
          );
      ref.invalidate(pomodoroStatsProvider);

      final int completed = state.completedFocusSessions + 1;
      final int threshold =
          ref.read(settingsControllerProvider).sessionsBeforeLongBreak;
      final PomodoroPhase next = (completed % threshold == 0)
          ? PomodoroPhase.longBreak
          : PomodoroPhase.shortBreak;
      _setupPhase(next, completedFocusSessions: completed, autoStart: true);
    } else {
      _setupPhase(PomodoroPhase.focus, autoStart: true);
    }
  }

  void _setupPhase(
    PomodoroPhase phase, {
    int? completedFocusSessions,
    bool autoStart = false,
  }) {
    final int total = _durationFor(phase);
    _phaseStart = autoStart ? DateTime.now() : null;
    state = TimerState(
      phase: phase,
      totalSeconds: total,
      remainingSeconds: total,
      isRunning: autoStart,
      completedFocusSessions:
          completedFocusSessions ?? state.completedFocusSessions,
    );
    if (autoStart) _startTicker();
    _updateNotification();
  }

  void _updateNotification() {
    final NotificationService n = ref.read(notificationServiceProvider);
    if (state.isRunning || !state.isIdle) {
      n.showPomodoro(
        title: '${state.phase.label} · ${state.formatted}',
        body: state.isRunning ? 'Timer running' : 'Paused',
        isRunning: state.isRunning,
      );
    } else {
      n.cancelPomodoro();
    }
  }

  void _handleAction(String actionId) {
    switch (actionId) {
      case NotificationService.actionPause:
        pause();
      case NotificationService.actionResume:
        start();
      case NotificationService.actionSkip:
        skip();
      case NotificationService.actionStop:
        stop();
    }
  }
}

final pomodoroTimerProvider =
    NotifierProvider<PomodoroTimer, TimerState>(PomodoroTimer.new);
