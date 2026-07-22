import 'package:flutter/material.dart';

/// Central color palette for the "Aura" design system.
///
/// The palette is intentionally small and semantic. Component colors are
/// derived from a single [seed] via [ColorScheme.fromSeed] so the whole app
/// stays visually coherent, while a handful of bespoke gradient / glass tints
/// give the premium, glassmorphic feel.
class AppColors {
  const AppColors._();

  /// Brand seed — a vivid indigo/violet that anchors the Material 3 scheme.
  static const Color seed = Color(0xFF6C5CE7);

  /// Accent gradient stops used for hero surfaces, the timer ring and CTAs.
  static const Color accentA = Color(0xFF7C5CFF);
  static const Color accentB = Color(0xFF00D2FF);
  static const Color accentC = Color(0xFFFF6AD5);

  /// Dark background gradient stops (top -> bottom).
  static const Color darkBgTop = Color(0xFF0E0F1A);
  static const Color darkBgBottom = Color(0xFF05060B);

  /// Light background gradient stops.
  static const Color lightBgTop = Color(0xFFF6F7FF);
  static const Color lightBgBottom = Color(0xFFECEEFA);

  /// Priority colors for tasks.
  static const Color priorityLow = Color(0xFF3BC9A6);
  static const Color priorityMedium = Color(0xFFF4A93B);
  static const Color priorityHigh = Color(0xFFF25C7A);

  /// A palette offered when picking colors for events / notes.
  static const List<Color> palette = <Color>[
    Color(0xFF7C5CFF),
    Color(0xFF00B8D9),
    Color(0xFF36B37E),
    Color(0xFFFFAB00),
    Color(0xFFFF5630),
    Color(0xFFFF6AD5),
    Color(0xFF4C9AFF),
    Color(0xFF8777D9),
  ];

  /// Glass tint for translucent surfaces in dark mode.
  static Color glassDark(double opacity) =>
      Colors.white.withValues(alpha: opacity);

  /// Glass tint for translucent surfaces in light mode.
  static Color glassLight(double opacity) =>
      Colors.white.withValues(alpha: opacity);
}
