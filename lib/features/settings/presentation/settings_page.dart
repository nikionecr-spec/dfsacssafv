import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/section_header.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsControllerProvider);
    final SettingsController controller =
        ref.read(settingsControllerProvider.notifier);

    return AuraScaffold(
      appBar: AppBar(title: const Text('Settings')),
      extendBody: false,
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            const SectionHeader(title: 'Appearance', icon: Icons.palette_outlined),
            GlassCard(
              child: Column(
                children: <Widget>[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Theme'),
                    trailing: SegmentedButton<ThemeMode>(
                      segments: const <ButtonSegment<ThemeMode>>[
                        ButtonSegment<ThemeMode>(
                            value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded)),
                        ButtonSegment<ThemeMode>(
                            value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded)),
                        ButtonSegment<ThemeMode>(
                            value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded)),
                      ],
                      selected: <ThemeMode>{settings.themeMode},
                      showSelectedIcon: false,
                      onSelectionChanged: (Set<ThemeMode> value) {
                        Haptics.selection();
                        controller.setThemeMode(value.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Calendar', icon: Icons.calendar_month_outlined),
            GlassCard(
              child: Column(
                children: <Widget>[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Calendar system'),
                    subtitle: Text(settings.calendarSystem == CalendarSystem.jalali
                        ? 'Jalali (Shamsi)'
                        : 'Gregorian'),
                    trailing: SegmentedButton<CalendarSystem>(
                      segments: const <ButtonSegment<CalendarSystem>>[
                        ButtonSegment<CalendarSystem>(
                            value: CalendarSystem.jalali, label: Text('شمسی')),
                        ButtonSegment<CalendarSystem>(
                            value: CalendarSystem.gregorian, label: Text('میلادی')),
                      ],
                      selected: <CalendarSystem>{settings.calendarSystem},
                      onSelectionChanged: (Set<CalendarSystem> value) {
                        Haptics.selection();
                        controller.setCalendarSystem(value.first);
                      },
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show dual dates'),
                    subtitle: const Text('Display Jalali and Gregorian together'),
                    value: settings.showDualDates,
                    onChanged: (bool v) => controller.setShowDualDates(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Editor', icon: Icons.edit_note_rounded),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Text size · ${(settings.editorTextScale * 100).round()}%'),
                  Slider(
                    value: settings.editorTextScale,
                    min: 0.8,
                    max: 1.8,
                    divisions: 10,
                    label: '${(settings.editorTextScale * 100).round()}%',
                    onChanged: (double v) => controller.setEditorTextScale(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Pomodoro', icon: Icons.timer_outlined),
            GlassCard(
              child: Column(
                children: <Widget>[
                  _stepper(context, 'Focus (min)', settings.focusMinutes,
                      (int v) => controller.setFocusMinutes(v), step: 5, min: 5, max: 90),
                  _stepper(context, 'Short break (min)', settings.shortBreakMinutes,
                      (int v) => controller.setShortBreakMinutes(v), min: 1, max: 30),
                  _stepper(context, 'Long break (min)', settings.longBreakMinutes,
                      (int v) => controller.setLongBreakMinutes(v), min: 5, max: 45),
                  _stepper(context, 'Sessions before long break',
                      settings.sessionsBeforeLongBreak,
                      (int v) => controller.setSessionsBeforeLongBreak(v),
                      min: 2, max: 8),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(
                title: 'Notifications', icon: Icons.notifications_outlined),
            GlassCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Enable reminders'),
                subtitle:
                    const Text('Grant permission for task, event and focus alerts'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  Haptics.light();
                  await ref
                      .read(notificationServiceProvider)
                      .requestPermissions();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Permission requested')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text('Aura · v1.0.0',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepper(
    BuildContext context,
    String label,
    int value,
    ValueChanged<int> onChanged, {
    int step = 1,
    int min = 0,
    int max = 100,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded),
            onPressed: value - step >= min
                ? () {
                    Haptics.selection();
                    onChanged(value - step);
                  }
                : null,
          ),
          SizedBox(
            width: 32,
            child: Text('$value', textAlign: TextAlign.center),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: value + step <= max
                ? () {
                    Haptics.selection();
                    onChanged(value + step);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
