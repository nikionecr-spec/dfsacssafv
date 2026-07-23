import 'package:sqflite/sqflite.dart';

import '../domain/task.dart';

class TasksRepository {
  TasksRepository(this._db);

  final Database _db;

  Future<List<Task>> getTasks({bool includeDone = true}) async {
    final String where = includeDone ? '' : 'WHERE status != ${TaskStatus.done.code}';
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT * FROM tasks $where '
      'ORDER BY status ASC, '
      '(deadline IS NULL) ASC, deadline ASC, priority DESC, updated_at DESC',
    );
    return _attachItems(rows);
  }

  Future<List<Task>> getTasksForDay(DateTime day) async {
    final DateTime start = DateTime(day.year, day.month, day.day);
    final DateTime end = start.add(const Duration(days: 1));
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT * FROM tasks WHERE deadline >= ? AND deadline < ? '
      'ORDER BY priority DESC, deadline ASC',
      <Object?>[start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return _attachItems(rows);
  }

  /// Open tasks that are due today or already overdue — the "daily plan".
  Future<List<Task>> getTodayPlan() async {
    final DateTime now = DateTime.now();
    final DateTime endExclusive =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT * FROM tasks WHERE status != ${TaskStatus.done.code} '
      'AND deadline IS NOT NULL AND deadline < ? '
      'ORDER BY deadline ASC, priority DESC',
      <Object?>[endExclusive.millisecondsSinceEpoch],
    );
    return _attachItems(rows);
  }

  Future<Task?> getTask(String id) async {
    final List<Map<String, Object?>> rows = await _db
        .query('tasks', where: 'id = ?', whereArgs: <Object?>[id], limit: 1);
    if (rows.isEmpty) return null;
    return (await _attachItems(rows)).first;
  }

  Future<List<Task>> _attachItems(List<Map<String, Object?>> taskRows) async {
    if (taskRows.isEmpty) return <Task>[];
    final List<String> ids =
        taskRows.map((Map<String, Object?> r) => r['id']! as String).toList();
    final String placeholders = List<String>.filled(ids.length, '?').join(',');
    final List<Map<String, Object?>> itemRows = await _db.rawQuery(
      'SELECT * FROM checklist_items WHERE task_id IN ($placeholders) '
      'ORDER BY position ASC',
      ids,
    );
    final Map<String, List<ChecklistItem>> byTask = <String, List<ChecklistItem>>{};
    for (final Map<String, Object?> r in itemRows) {
      (byTask[r['task_id']! as String] ??= <ChecklistItem>[])
          .add(ChecklistItem.fromMap(r));
    }
    return taskRows
        .map((Map<String, Object?> r) => Task.fromMap(r,
            items: byTask[r['id']] ?? const <ChecklistItem>[]))
        .toList(growable: false);
  }

  Future<void> upsertTask(Task task) async {
    await _db.transaction((Transaction txn) async {
      await txn.insert('tasks', task.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete('checklist_items',
          where: 'task_id = ?', whereArgs: <Object?>[task.id]);
      for (int i = 0; i < task.items.length; i++) {
        await txn.insert(
          'checklist_items',
          task.items[i].copyWith(position: i).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> setStatus(String id, TaskStatus status) async {
    await _db.update(
      'tasks',
      <String, Object?>{
        'status': status.code,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> toggleItem(String itemId, bool done) async {
    await _db.update('checklist_items', <String, Object?>{'done': done ? 1 : 0},
        where: 'id = ?', whereArgs: <Object?>[itemId]);
  }

  Future<void> deleteTask(String id) async {
    await _db.delete('tasks', where: 'id = ?', whereArgs: <Object?>[id]);
  }
}
