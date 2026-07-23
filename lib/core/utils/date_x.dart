import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';

import 'persian_digits.dart';

/// The two calendar systems the app can display dates in.
enum CalendarSystem { jalali, gregorian }

/// Date helpers shared across the app.
///
/// All conversions between the Gregorian world of [DateTime] and the Jalali
/// world go through [shamsi_date], which is battle-tested — we never roll our
/// own calendar arithmetic.
class DateX {
  const DateX._();

  /// A [DateTime] truncated to midnight (local). Useful as a stable "day key".
  static DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Epoch-millis key for the day a [DateTime] falls on.
  static int dayKey(DateTime d) => dayOnly(d).millisecondsSinceEpoch;

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime d) => isSameDay(d, DateTime.now());

  static Jalali toJalali(DateTime d) => Jalali.fromDateTime(d);

  /// Jalali month names in Persian.
  static const List<String> jalaliMonths = <String>[
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];

  /// Persian weekday labels, ordered Saturday -> Friday (shamsi week order).
  static const List<String> jalaliWeekdaysShort = <String>[
    'ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج',
  ];

  /// Formats a date as "۲ فروردین ۱۴۰۳".
  static String formatJalali(DateTime d) {
    final Jalali j = toJalali(d);
    final String s = '${j.day} ${jalaliMonths[j.month - 1]} ${j.year}';
    return s.toPersianDigits();
  }

  /// Formats a date as "Mar 22, 2024".
  static String formatGregorian(DateTime d) => DateFormat('MMM d, y').format(d);

  /// A one-line dual label, e.g. "۲ فروردین ۱۴۰۳ · Mar 22, 2024".
  static String dual(DateTime d) => '${formatJalali(d)} · ${formatGregorian(d)}';

  /// Formats a date according to the active [system].
  static String format(DateTime d, CalendarSystem system) =>
      system == CalendarSystem.jalali ? formatJalali(d) : formatGregorian(d);

  /// The visible month title, e.g. "فروردین ۱۴۰۳" or "March 2024".
  static String monthTitle(DateTime monthAnchor, CalendarSystem system) {
    if (system == CalendarSystem.jalali) {
      final Jalali j = toJalali(monthAnchor);
      return '${jalaliMonths[j.month - 1]} ${j.year}'.toPersianDigits();
    }
    return DateFormat('MMMM y').format(monthAnchor);
  }

  static String timeOfDay(DateTime d) => DateFormat('HH:mm').format(d);

  /// A short human relative label ("Today", "Yesterday", or a date).
  static String relativeDay(DateTime d, CalendarSystem system) {
    final DateTime now = DateTime.now();
    final DateTime target = dayOnly(d);
    final int diff = target.difference(dayOnly(now)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return format(d, system);
  }
}
