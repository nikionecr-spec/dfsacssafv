import 'package:sqflite/sqflite.dart';

import '../domain/note.dart';

/// All persistence for notes, folders and tags lives here.
///
/// Queries are index-backed (`idx_notes_updated`, `idx_note_tags_tag`) so
/// listing and searching stay fast even with thousands of notes.
class NotesRepository {
  NotesRepository(this._db);

  final Database _db;

  Future<List<Note>> getNotes({
    String? query,
    String? tag,
    String? folderId,
    DateTime? dateLink,
    int? limit,
  }) async {
    final List<String> where = <String>[];
    final List<Object?> args = <Object?>[];

    if (query != null && query.trim().isNotEmpty) {
      where.add('(n.title LIKE ? OR n.body LIKE ?)');
      final String like = '%${query.trim()}%';
      args..add(like)..add(like);
    }
    if (folderId != null) {
      where.add('n.folder_id = ?');
      args.add(folderId);
    }
    if (dateLink != null) {
      final DateTime start = DateTime(dateLink.year, dateLink.month, dateLink.day);
      final DateTime end = start.add(const Duration(days: 1));
      where.add('n.date_link >= ? AND n.date_link < ?');
      args..add(start.millisecondsSinceEpoch)..add(end.millisecondsSinceEpoch);
    }
    if (tag != null) {
      where.add('n.id IN (SELECT note_id FROM note_tags WHERE tag = ?)');
      args.add(tag);
    }

    final String whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final String limitSql = limit == null ? '' : 'LIMIT $limit';

    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT n.* FROM notes n $whereSql '
      'ORDER BY n.pinned DESC, n.updated_at DESC $limitSql',
      args,
    );

    if (rows.isEmpty) return <Note>[];
    final Map<String, List<String>> tagsById =
        await _tagsFor(rows.map((Map<String, Object?> r) => r['id']! as String).toList());

    return rows
        .map((Map<String, Object?> r) =>
            Note.fromMap(r, tags: tagsById[r['id']] ?? const <String>[]))
        .toList(growable: false);
  }

  Future<Note?> getNote(String id) async {
    final List<Map<String, Object?>> rows =
        await _db.query('notes', where: 'id = ?', whereArgs: <Object?>[id], limit: 1);
    if (rows.isEmpty) return null;
    final Map<String, List<String>> tags = await _tagsFor(<String>[id]);
    return Note.fromMap(rows.first, tags: tags[id] ?? const <String>[]);
  }

  Future<Map<String, List<String>>> _tagsFor(List<String> ids) async {
    if (ids.isEmpty) return <String, List<String>>{};
    final String placeholders = List<String>.filled(ids.length, '?').join(',');
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT note_id, tag FROM note_tags WHERE note_id IN ($placeholders) ORDER BY tag',
      ids,
    );
    final Map<String, List<String>> result = <String, List<String>>{};
    for (final Map<String, Object?> r in rows) {
      (result[r['note_id']! as String] ??= <String>[]).add(r['tag']! as String);
    }
    return result;
  }

  Future<void> upsertNote(Note note) async {
    await _db.transaction((Transaction txn) async {
      await txn.insert('notes', note.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete('note_tags',
          where: 'note_id = ?', whereArgs: <Object?>[note.id]);
      for (final String tag in note.tags.toSet()) {
        final String clean = tag.trim();
        if (clean.isEmpty) continue;
        await txn.insert('note_tags',
            <String, Object?>{'note_id': note.id, 'tag': clean},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<void> setPinned(String id, bool pinned) async {
    await _db.update('notes', <String, Object?>{'pinned': pinned ? 1 : 0},
        where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<void> deleteNote(String id) async {
    await _db.delete('notes', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<List<TagCount>> allTags() async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT tag, COUNT(*) AS c FROM note_tags GROUP BY tag ORDER BY c DESC, tag ASC',
    );
    return rows
        .map((Map<String, Object?> r) =>
            TagCount(r['tag']! as String, r['c']! as int))
        .toList(growable: false);
  }

  // --- Folders ---------------------------------------------------------------

  Future<List<Folder>> folders() async {
    final List<Map<String, Object?>> rows =
        await _db.query('folders', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(Folder.fromMap).toList(growable: false);
  }

  Future<void> upsertFolder(Folder folder) async {
    await _db.insert('folders', folder.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteFolder(String id) async {
    await _db.delete('folders', where: 'id = ?', whereArgs: <Object?>[id]);
  }
}
