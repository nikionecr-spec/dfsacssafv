import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/aura_scaffold.dart';
import 'providers/calendar_providers.dart';
import 'widgets/day_agenda.dart';
import 'widgets/month_view.dart';
import 'widgets/week_strip.dart';

enum CalendarViewMode { month, week, day }

final calendarViewProvider =
    StateProvider<CalendarViewMode>((ref) => CalendarViewMode.month);

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppSettings settings = ref.watch(settingsControllerProvider);
    final CalendarSystem system = settings.calendarSystem;
    final CalendarViewMode view = ref.watch(calendarViewProvider);
    final DateTime selected = ref.watch(selectedDayProvider);

    return AuraScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Calendar', style: theme.textTheme.headlineMedium),
                        if (settings.showDualDates)
                          Text(
                            DateX.dual(selected),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Switch calendar system',
                    onPressed: () {
                      Haptics.selection();
                      ref.read(settingsControllerProvider.notifier)
                          .setCalendarSystem(
                        system == CalendarSystem.jalali
                            ? CalendarSystem.gregorian
                            : CalendarSystem.jalali,
                      );
                    },
                    icon: const Icon(Icons.translate_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: SegmentedButton<CalendarViewMode>(
                segments: const <ButtonSegment<CalendarViewMode>>[
                  ButtonSegment<CalendarViewMode>(
                      value: CalendarViewMode.month, label: Text('Month')),
                  ButtonSegment<CalendarViewMode>(
                      value: CalendarViewMode.week, label: Text('Week')),
                  ButtonSegment<CalendarViewMode>(
                      value: CalendarViewMode.day, label: Text('Day')),
                ],
                selected: <CalendarViewMode>{view},
                onSelectionChanged: (Set<CalendarViewMode> value) {
                  Haptics.selection();
                  ref.read(calendarViewProvider.notifier).state = value.first;
                },
              ),
            ),
            if (view == CalendarViewMode.month) MonthView(system: system),
            if (view == CalendarViewMode.week)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: WeekStrip(system: system),
              ),
            const Divider(height: AppSpacing.lg, indent: 16, endIndent: 16),
            Expanded(child: DayAgenda(day: selected, system: system)),
          ],
        ),
      ),
    );
  }
}
