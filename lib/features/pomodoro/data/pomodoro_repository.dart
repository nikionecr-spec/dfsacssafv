import 'package:sqflite/sqflite.dart';

import '../domain/pomodoro.dart';

class PomodoroRepository {
  PomodoroRepository(this._db);

  final Database _db;

  Future<void> insertSession(PomodoroSession session) async {
    await _db.insert('pomodoro_sessions', session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<PomodoroStats> stats() async {
    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    final DateTime weekStart = todayStart.subtract(const Duration(days: 6));

    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT start, focus_seconds FROM pomodoro_sessions WHERE start >= ?',
      <Object?>[weekStart.millisecondsSinceEpoch],
    );

    final List<int> week = List<int>.filled(7, 0);
    int todayMinutes = 0;
    int todaySessions = 0;

    for (final Map<String, Object?> r in rows) {
      final DateTime start =
          DateTime.fromMillisecondsSinceEpoch(r['start']! as int);
      final int minutes = ((r['focus_seconds']! as int) / 60).round();
      final int dayIndex =
          DateTime(start.year, start.month, start.day).difference(weekStart).inDays;
      if (dayIndex >= 0 && dayIndex < 7) week[dayIndex] += minutes;
      if (!start.isBefore(todayStart)) {
        todayMinutes += minutes;
        todaySessions += 1;
      }
    }

    return PomodoroStats(
      todayMinutes: todayMinutes,
      todaySessions: todaySessions,
      weekMinutes: week,
    );
  }
}
