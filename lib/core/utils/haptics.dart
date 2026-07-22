import 'package:flutter/services.dart';

/// Thin wrapper over [HapticFeedback] so call-sites read intent, not mechanics.
///
/// Uses only the built-in platform channel — no third-party dependency.
class Haptics {
  const Haptics._();

  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void selection() => HapticFeedback.selectionClick();
  static void success() => HapticFeedback.mediumImpact();
}
