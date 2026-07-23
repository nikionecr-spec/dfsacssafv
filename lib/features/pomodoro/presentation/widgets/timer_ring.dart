import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/pomodoro.dart';

/// A smoothly animated circular progress ring for the timer.
///
/// The sweep is interpolated with a [TweenAnimationBuilder] over one second
/// (matching the tick cadence) so the arc glides rather than stepping — this is
/// a single arc + one blurred glow arc, so it is very cheap to repaint.
class TimerRing extends StatelessWidget {
  const TimerRing({
    super.key,
    required this.progress,
    required this.phase,
    required this.child,
    this.size = 260,
  });

  final double progress;
  final PomodoroPhase phase;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<Color> gradient = switch (phase) {
      PomodoroPhase.focus => <Color>[AppColors.accentA, AppColors.accentB],
      PomodoroPhase.shortBreak => <Color>[AppColors.priorityLow, AppColors.accentB],
      PomodoroPhase.longBreak => <Color>[AppColors.accentC, AppColors.accentA],
    };

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 950),
        curve: Curves.linear,
        builder: (BuildContext context, double value, Widget? child) {
          return CustomPaint(
            painter: _RingPainter(
              progress: value,
              gradient: gradient,
              track: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            child: child,
          );
        },
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.gradient,
    required this.track,
  });

  final double progress;
  final List<Color> gradient;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 16;
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - stroke) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    const double startAngle = -math.pi / 2;
    final double sweep = 2 * math.pi * progress;

    final Shader shader = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + 2 * math.pi,
      colors: gradient,
      transform: GradientRotation(startAngle),
    ).createShader(rect);

    // Soft glow underneath.
    final Paint glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = shader
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(rect, startAngle, sweep, false, glow);

    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = shader;
    canvas.drawArc(rect, startAngle, sweep, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.gradient != gradient ||
      oldDelegate.track != track;
}
