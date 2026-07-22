import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A soft, premium "aurora" backdrop.
///
/// It is intentionally cheap: a base [LinearGradient] plus two [RadialGradient]
/// blobs that drift very slowly. There is **no blur** — the softness comes from
/// wide radial gradients, which the GPU handles trivially, so this never costs
/// us frames even at 120 Hz. The whole thing is a [RepaintBoundary].
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Color> base = isDark
        ? <Color>[AppColors.darkBgTop, AppColors.darkBgBottom]
        : <Color>[AppColors.lightBgTop, AppColors.lightBgBottom];

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: base,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? _) {
              final double t = _controller.value;
              return CustomPaint(
                painter: _AuroraPainter(t: t, dark: isDark),
              );
            },
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.t, required this.dark});

  final double t;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final double opacity = dark ? 0.28 : 0.20;

    void blob(Offset center, double radius, Color color) {
      final Paint paint = Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    final double w = size.width;
    final double h = size.height;

    blob(
      Offset(w * (0.2 + 0.1 * t), h * (0.18 + 0.05 * t)),
      w * 0.7,
      AppColors.accentA,
    );
    blob(
      Offset(w * (0.85 - 0.08 * t), h * (0.28 + 0.06 * (1 - t))),
      w * 0.6,
      AppColors.accentB,
    );
    blob(
      Offset(w * (0.6 + 0.05 * t), h * (0.9 - 0.05 * t)),
      w * 0.75,
      AppColors.accentC,
    );
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) => oldDelegate.t != t;
}
