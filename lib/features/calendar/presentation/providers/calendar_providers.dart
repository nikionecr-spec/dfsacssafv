import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/settings/settings_controller.dart';
import '../../../../core/utils/date_x.dart';
import '../../data/events_repository.dart';
import '../../domain/calendar_event.dart';
import '../../domain/month_grid.dart';

final eventsRepositoryProvider = Provider<EventsRepository>(
  (ref) => EventsRepository(ref.watch(databaseProvider)),
);

/// The month currently in focus (any day within it; normalised to day-only).
final focusedMonthProvider =
    StateProvider<DateTime>((ref) => DateX.dayOnly(DateTime.now()));

/// The day the user has tapped / is inspecting.
final selectedDayProvider =
    StateProvider<DateTime>((ref) => DateX.dayOnly(DateTime.now()));

/// All events within the padded range of the focused month, keyed by day for
/// fast dot lookups in the grid.
final monthEventsProvider =
    FutureProvider.autoDispose<Map<int, List<CalendarEvent>>>((ref) async {
  final DateTime anchor = ref.watch(focusedMonthProvider);
  final CalendarSystem system = ref.watch(
      settingsControllerProvider.select((AppSettings s) => s.calendarSystem));
  final ({DateTime start, DateTime end}) range = visibleRange(anchor, system);
  final List<CalendarEvent> events =
      await ref.watch(eventsRepositoryProvider).getBetween(range.start, range.end);

  final Map<int, List<CalendarEvent>> byDay = <int, List<CalendarEvent>>{};
  for (final CalendarEvent e in events) {
    (byDay[DateX.dayKey(e.start)] ??= <CalendarEvent>[]).add(e);
  }
  return byDay;
});

final eventsForDayProvider =
    FutureProvider.autoDispose.family<List<CalendarEvent>, DateTime>(
  (ref, DateTime day) => ref.watch(eventsRepositoryProvider).getForDay(day),
);

class CalendarController {
  CalendarController(this.ref);
  final Ref ref;

  EventsRepository get _repo => ref.read(eventsRepositoryProvider);
  NotificationService get _notifications => ref.read(notificationServiceProvider);

  Future<void> save(CalendarEvent event) async {
    await _repo.upsert(event);
    await _syncReminder(event);
    _invalidate();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await _notifications.cancel(NotificationService.idFrom('event:$id'));
    _invalidate();
  }

  Future<void> _syncReminder(CalendarEvent event) async {
    final int id = NotificationService.idFrom('event:${event.id}');
    await _notifications.cancel(id);
    if (!event.allDay && event.start.isAfter(DateTime.now())) {
      await _notifications.scheduleReminder(
        id: id,
        title: event.title,
        body: event.description?.isNotEmpty == true
            ? event.description!
            : 'Upcoming event',
        when: event.start,
        payload: 'event:${event.id}',
      );
    }
  }

  void _invalidate() {
    ref.invalidate(monthEventsProvider);
    // Family providers are invalidated wholesale.
    ref.invalidate(eventsForDayProvider);
  }
}

final calendarControllerProvider =
    Provider<CalendarController>((ref) => CalendarController(ref));
