import 'package:flutter/material.dart';

import '../utils/date_x.dart';

/// Immutable snapshot of all user preferences.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.calendarSystem = CalendarSystem.jalali,
    this.showDualDates = true,
    this.editorTextScale = 1.0,
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsBeforeLongBreak = 4,
  });

  final ThemeMode themeMode;
  final CalendarSystem calendarSystem;
  final bool showDualDates;
  final double editorTextScale;
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int sessionsBeforeLongBreak;

  AppSettings copyWith({
    ThemeMode? themeMode,
    CalendarSystem? calendarSystem,
    bool? showDualDates,
    double? editorTextScale,
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLongBreak,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      calendarSystem: calendarSystem ?? this.calendarSystem,
      showDualDates: showDualDates ?? this.showDualDates,
      editorTextScale: editorTextScale ?? this.editorTextScale,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
    );
  }

  Map<String, String> toMap() => <String, String>{
        'themeMode': themeMode.name,
        'calendarSystem': calendarSystem.name,
        'showDualDates': showDualDates ? '1' : '0',
        'editorTextScale': editorTextScale.toString(),
        'focusMinutes': '$focusMinutes',
        'shortBreakMinutes': '$shortBreakMinutes',
        'longBreakMinutes': '$longBreakMinutes',
        'sessionsBeforeLongBreak': '$sessionsBeforeLongBreak',
      };

  factory AppSettings.fromMap(Map<String, String> m) {
    T pick<T>(String key, T fallback, T Function(String) parse) {
      final String? raw = m[key];
      if (raw == null) return fallback;
      try {
        return parse(raw);
      } catch (_) {
        return fallback;
      }
    }

    return AppSettings(
      themeMode: pick('themeMode', ThemeMode.dark,
          (String v) => ThemeMode.values.byName(v)),
      calendarSystem: pick('calendarSystem', CalendarSystem.jalali,
          (String v) => CalendarSystem.values.byName(v)),
      showDualDates: pick('showDualDates', true, (String v) => v == '1'),
      editorTextScale:
          pick('editorTextScale', 1.0, (String v) => double.parse(v)),
      focusMinutes: pick('focusMinutes', 25, int.parse),
      shortBreakMinutes: pick('shortBreakMinutes', 5, int.parse),
      longBreakMinutes: pick('longBreakMinutes', 15, int.parse),
      sessionsBeforeLongBreak:
          pick('sessionsBeforeLongBreak', 4, int.parse),
    );
  }
}
