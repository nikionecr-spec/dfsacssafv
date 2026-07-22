import 'dart:async';

import 'package:flutter/foundation.dart';

/// Coalesces rapid calls into a single trailing invocation.
///
/// Used by the fast search fields so we don't hit the database on every
/// keystroke — we wait for a short pause first.
class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 250)});

  final Duration duration;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() => _timer?.cancel();
}
