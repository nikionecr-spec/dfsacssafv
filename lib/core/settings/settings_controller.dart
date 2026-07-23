import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../utils/date_x.dart';
import 'app_settings.dart';

/// Holds the live [AppSettings] and persists every change.
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(settingsRepositoryProvider).current;

  Future<void> _update(AppSettings next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  Future<void> toggleDarkMode() => _update(state.copyWith(
        themeMode:
            state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      ));

  Future<void> setCalendarSystem(CalendarSystem system) =>
      _update(state.copyWith(calendarSystem: system));

  Future<void> setShowDualDates(bool value) =>
      _update(state.copyWith(showDualDates: value));

  Future<void> setEditorTextScale(double scale) =>
      _update(state.copyWith(editorTextScale: scale.clamp(0.8, 1.8)));

  Future<void> setFocusMinutes(int minutes) =>
      _update(state.copyWith(focusMinutes: minutes.clamp(1, 120)));

  Future<void> setShortBreakMinutes(int minutes) =>
      _update(state.copyWith(shortBreakMinutes: minutes.clamp(1, 60)));

  Future<void> setLongBreakMinutes(int minutes) =>
      _update(state.copyWith(longBreakMinutes: minutes.clamp(1, 90)));

  Future<void> setSessionsBeforeLongBreak(int count) =>
      _update(state.copyWith(sessionsBeforeLongBreak: count.clamp(1, 12)));
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
