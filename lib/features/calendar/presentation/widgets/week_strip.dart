import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/date_x.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/persian_digits.dart';
import '../providers/calendar_providers.dart';

/// A one-week horizontal selector centred on the selected day's week. Week
/// starts on Saturday for Jalali, Monday for Gregorian.
class WeekStrip extends ConsumerWidget {
  const WeekStrip({super.key, required this.system});

  final CalendarSystem system;

  DateTime _weekStart(DateTime day) {
    if (system == CalendarSystem.jalali) {
      final int wd = Jalali.fromDateTime(day).weekDay; // 1 = Saturday
      return day.subtract(Duration(days: wd - 1));
    }
    final int wd = day.weekday; // 1 = Monday
    return day.subtract(Duration(days: wd - 1));
  }

  String _weekdayLabel(DateTime day) {
    if (system == CalendarSystem.jalali) {
      return DateX.jalaliWeekdaysShort[Jalali.fromDateTime(day).weekDay - 1];
    }
    return const <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1];
  }

  String _dayLabel(DateTime day) {
    if (system == CalendarSystem.jalali) {
      return Jalali.fromDateTime(day).day.toPersianDigits();
    }
    return '${day.day}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final DateTime selected = ref.watch(selectedDayProvider);
    final DateTime start = _weekStart(selected);

    return SizedBox(
      height: 76,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < 7; i++)
            Builder(builder: (BuildContext context) {
              final DateTime day = DateX.dayOnly(start.add(Duration(days: i)));
              final bool isSelected = DateX.isSameDay(day, selected);
              final bool isToday = DateX.isToday(day);
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    Haptics.selection();
                    ref.read(selectedDayProvider.notifier).state = day;
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHigh
                              .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: isToday && !isSelected
                          ? Border.all(color: theme.colorScheme.primary)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          _weekdayLabel(day),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dayLabel(day),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
