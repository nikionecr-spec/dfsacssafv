import 'package:flutter/material.dart';

/// A tiny 7-bar weekly focus chart, hand-painted so it costs almost nothing
/// and matches the app's theme exactly (no charting dependency).
class FocusStatsChart extends StatelessWidget {
  const FocusStatsChart({super.key, required this.weekMinutes});

  /// Focus minutes for the last 7 days, oldest first.
  final List<int> weekMinutes;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // Weekday initials for the last 7 days, ending today.
    final DateTime today = DateTime.now();
    final List<String> labels = <String>[
      for (int i = 6; i >= 0; i--)
        _initial(today.subtract(Duration(days: i)).weekday),
    ];

    return SizedBox(
      height: 120,
      child: CustomPaint(
        painter: _BarsPainter(
          values: weekMinutes,
          labels: labels,
          barColor: scheme.primary,
          trackColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          labelColor: scheme.onSurfaceVariant,
          textDirection: Directionality.of(context),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  static String _initial(int weekday) =>
      const <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'][weekday - 1];
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.values,
    required this.labels,
    required this.barColor,
    required this.trackColor,
    required this.labelColor,
    required this.textDirection,
  });

  final List<int> values;
  final List<String> labels;
  final Color barColor;
  final Color trackColor;
  final Color labelColor;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final int maxValue = values.fold<int>(1, (int a, int b) => a > b ? a : b);
    const double labelSpace = 20;
    final double chartHeight = size.height - labelSpace;
    final double slot = size.width / values.length;
    const double barWidth = 14;
    final double radius = barWidth / 2;

    for (int i = 0; i < values.length; i++) {
      final double cx = slot * i + slot / 2;
      final double left = cx - barWidth / 2;

      // Track.
      final RRect track = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 0, barWidth, chartHeight),
        Radius.circular(radius),
      );
      canvas.drawRRect(track, Paint()..color = trackColor);

      // Value bar.
      final double fraction = (values[i] / maxValue).clamp(0.0, 1.0);
      final double barHeight = chartHeight * fraction;
      if (barHeight > 1) {
        final RRect bar = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, chartHeight - barHeight, barWidth, barHeight),
          Radius.circular(radius),
        );
        canvas.drawRRect(bar, Paint()..color = barColor);
      }

      // Label.
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(color: labelColor, fontSize: 11),
        ),
        textDirection: textDirection,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, size.height - labelSpace + 4));
    }
  }

  @override
  bool shouldRepaint(_BarsPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.barColor != barColor;
}
