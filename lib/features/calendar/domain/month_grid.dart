import 'package:shamsi_date/shamsi_date.dart';

import '../../../core/utils/date_x.dart';
import '../../../core/utils/persian_digits.dart';

/// A fully computed month grid for either calendar system.
///
/// The grid is a flat list of 7*N cells where a `null` entry is a blank
/// leading/trailing pad and a non-null entry is that day (at local midnight).
class MonthGrid {
  MonthGrid({
    required this.title,
    required this.weekdayLabels,
    required this.cells,
    required this.system,
  });

  final String title;
  final List<String> weekdayLabels;
  final List<DateTime?> cells;
  final CalendarSystem system;

  /// The number that should be shown in a day cell.
  String dayLabel(DateTime date) {
    if (system == CalendarSystem.jalali) {
      return Jalali.fromDateTime(date).day.toPersianDigits();
    }
    return '${date.day}';
  }
}

/// Builds the grid for the month that [anchor] falls in.
MonthGrid buildMonthGrid(DateTime anchor, CalendarSystem system) {
  if (system == CalendarSystem.jalali) {
    return _buildJalali(anchor);
  }
  return _buildGregorian(anchor);
}

MonthGrid _buildJalali(DateTime anchor) {
  final Jalali j = Jalali.fromDateTime(anchor);
  final Jalali first = Jalali(j.year, j.month, 1);
  final DateTime firstDate = DateX.dayOnly(first.toDateTime());
  final Jalali nextMonth =
      j.month == 12 ? Jalali(j.year + 1, 1, 1) : Jalali(j.year, j.month + 1, 1);
  final DateTime nextDate = DateX.dayOnly(nextMonth.toDateTime());
  final int daysInMonth = nextDate.difference(firstDate).inDays;
  final int leading = first.weekDay - 1; // weekDay: 1 = Saturday.

  return MonthGrid(
    title: DateX.monthTitle(anchor, CalendarSystem.jalali),
    weekdayLabels: DateX.jalaliWeekdaysShort,
    cells: _cells(firstDate, daysInMonth, leading),
    system: CalendarSystem.jalali,
  );
}

MonthGrid _buildGregorian(DateTime anchor) {
  final DateTime first = DateTime(anchor.year, anchor.month, 1);
  final DateTime next = DateTime(anchor.year, anchor.month + 1, 1);
  final int daysInMonth = next.difference(first).inDays;
  final int leading = first.weekday - 1; // weekday: 1 = Monday.

  return MonthGrid(
    title: DateX.monthTitle(anchor, CalendarSystem.gregorian),
    weekdayLabels: const <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    cells: _cells(first, daysInMonth, leading),
    system: CalendarSystem.gregorian,
  );
}

List<DateTime?> _cells(DateTime firstDate, int daysInMonth, int leading) {
  final List<DateTime?> cells = <DateTime?>[];
  for (int i = 0; i < leading; i++) {
    cells.add(null);
  }
  for (int d = 0; d < daysInMonth; d++) {
    cells.add(firstDate.add(Duration(days: d)));
  }
  while (cells.length % 7 != 0) {
    cells.add(null);
  }
  return cells;
}

/// Returns the anchor of the month that is [offset] months away from [base].
DateTime stepMonths(DateTime base, int offset, CalendarSystem system) {
  if (system == CalendarSystem.jalali) {
    final Jalali j = Jalali.fromDateTime(base);
    final int total = j.year * 12 + (j.month - 1) + offset;
    final int year = total ~/ 12;
    final int month = total % 12 + 1;
    return DateX.dayOnly(Jalali(year, month, 1).toDateTime());
  }
  return DateTime(base.year, base.month + offset, 1);
}

/// Inclusive-exclusive Gregorian range covering the whole visible month, with
/// a little padding so events on the leading/trailing days are fetched too.
({DateTime start, DateTime end}) visibleRange(
    DateTime anchor, CalendarSystem system) {
  final DateTime start = stepMonths(anchor, 0, system);
  final DateTime end = stepMonths(anchor, 1, system);
  return (
    start: start.subtract(const Duration(days: 7)),
    end: end.add(const Duration(days: 7)),
  );
}
