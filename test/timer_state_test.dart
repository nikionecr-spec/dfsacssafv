import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_app/features/pomodoro/domain/pomodoro.dart';

void main() {
  group('TimerState', () {
    const TimerState state = TimerState(
      phase: PomodoroPhase.focus,
      totalSeconds: 1500,
      remainingSeconds: 65,
      isRunning: false,
      completedFocusSessions: 0,
    );

    test('formats mm:ss', () {
      expect(state.formatted, '01:05');
    });

    test('computes progress', () {
      expect(state.progress, closeTo((1500 - 65) / 1500, 1e-9));
    });

    test('is not idle when partially elapsed', () {
      expect(state.isIdle, isFalse);
    });

    test('is idle at full duration and stopped', () {
      const TimerState idle = TimerState(
        phase: PomodoroPhase.focus,
        totalSeconds: 1500,
        remainingSeconds: 1500,
        isRunning: false,
        completedFocusSessions: 0,
      );
      expect(idle.isIdle, isTrue);
    });
  });
}
