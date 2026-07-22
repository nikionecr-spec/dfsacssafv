import 'package:sqflite/sqflite.dart';

import '../domain/calendar_event.dart';

class EventsRepository {
  EventsRepository(this._db);

  final Database _db;

  Future<List<CalendarEvent>> getBetween(DateTime start, DateTime end) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'events',
      where: 'start >= ? AND start < ?',
      whereArgs: <Object?>[
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'start ASC',
    );
    return rows.map(CalendarEvent.fromMap).toList(growable: false);
  }

  Future<List<CalendarEvent>> getForDay(DateTime day) {
    final DateTime start = DateTime(day.year, day.month, day.day);
    return getBetween(start, start.add(const Duration(days: 1)));
  }

  Future<CalendarEvent?> getEvent(String id) async {
    final List<Map<String, Object?>> rows = await _db
        .query('events', where: 'id = ?', whereArgs: <Object?>[id], limit: 1);
    if (rows.isEmpty) return null;
    return CalendarEvent.fromMap(rows.first);
  }

  Future<void> upsert(CalendarEvent event) async {
    await _db.insert('events', event.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    await _db.delete('events', where: 'id = ?', whereArgs: <Object?>[id]);
  }
}
