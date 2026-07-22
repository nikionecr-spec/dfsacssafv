import 'package:flutter/foundation.dart';

enum PomodoroPhase {
  focus('Focus'),
  shortBreak('Short break'),
  longBreak('Long break');

  const PomodoroPhase(this.label);
  final String label;

  bool get isFocus => this == PomodoroPhase.focus;
}

/// A completed (or logged) focus session, used for statistics.
@immutable
class PomodoroSession {
  const PomodoroSession({
    required this.id,
    required this.start,
    required this.end,
    required this.focusSeconds,
    this.completed = true,
  });

  final String id;
  final DateTime start;
  final DateTime end;
  final int focusSeconds;
  final bool completed;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch,
        'focus_seconds': focusSeconds,
        'completed': completed ? 1 : 0,
      };

  factory PomodoroSession.fromMap(Map<String, Object?> m) => PomodoroSession(
        id: m['id']! as String,
        start: DateTime.fromMillisecondsSinceEpoch(m['start']! as int),
        end: DateTime.fromMillisecondsSinceEpoch(m['end']! as int),
        focusSeconds: m['focus_seconds']! as int,
        completed: (m['completed']! as int) == 1,
      );
}

/// The live state of the timer.
@immutable
class TimerState {
  const TimerState({
    required this.phase,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.isRunning,
    required this.completedFocusSessions,
  });

  final PomodoroPhase phase;
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;

  /// Number of focus sessions finished within the current long-break cycle.
  final int completedFocusSessions;

  double get progress =>
      totalSeconds == 0 ? 0 : (totalSeconds - remainingSeconds) / totalSeconds;

  bool get isIdle => !isRunning && remainingSeconds == totalSeconds;

  String get formatted {
    final int m = remainingSeconds ~/ 60;
    final int s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  TimerState copyWith({
    PomodoroPhase? phase,
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
    int? completedFocusSessions,
  }) {
    return TimerState(
      phase: phase ?? this.phase,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      completedFocusSessions:
          completedFocusSessions ?? this.completedFocusSessions,
    );
  }
}

/// Aggregated focus statistics for the dashboard and the Pomodoro screen.
@immutable
class PomodoroStats {
  const PomodoroStats({
    required this.todayMinutes,
    required this.todaySessions,
    required this.weekMinutes,
  });

  /// Focus minutes today.
  final int todayMinutes;

  /// Completed focus sessions today.
  final int todaySessions;

  /// Focus minutes for each of the last 7 days (oldest first).
  final List<int> weekMinutes;
}
