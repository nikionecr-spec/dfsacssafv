import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// A rounded, translucent "glass" surface.
///
/// Performance note: a real backdrop blur is one of the most expensive things
/// you can put on screen, so it is *opt-in*. In long, scrolling lists pass
/// `blur: false` — you still get the frosted, layered look from the gradient
/// fill and border, but without paying for a `BackdropFilter` per row. Each
/// card is wrapped in a [RepaintBoundary] so its raster is cached.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadii.lg,
    this.onTap,
    this.onLongPress,
    this.blur = false,
    this.blurSigma = 18,
    this.tint,
    this.border = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool blur;
  final double blurSigma;
  final Color? tint;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final BorderRadius borderRadius = BorderRadius.circular(radius);

    final Color fillTop = (tint ?? scheme.surfaceContainerHigh)
        .withValues(alpha: isDark ? 0.55 : 0.80);
    final Color fillBottom = (tint ?? scheme.surfaceContainer)
        .withValues(alpha: isDark ? 0.30 : 0.65);

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[fillTop, fillBottom],
        ),
        border: border
            ? Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.55),
                width: 1,
              )
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: borderRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (blur) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: surface,
      );
    }

    return RepaintBoundary(
      child: ClipRRect(borderRadius: borderRadius, child: surface),
    );
  }
}
