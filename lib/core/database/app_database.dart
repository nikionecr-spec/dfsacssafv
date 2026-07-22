import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the single [Database] connection and its schema.
///
/// We use raw `sqflite` rather than a code-generated ORM: it keeps the build
/// step trivial (`flutter pub get` and go — no `build_runner`), keeps the app
/// light, and gives us full control over indexes and query plans, which is
/// what actually makes reads feel instant.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const String fileName = 'aura.db';
  static const int schemaVersion = 1;

  /// Opens (creating if necessary) the database in the platform's default
  /// databases directory.
  static Future<AppDatabase> open() async {
    final String dir = await getDatabasesPath();
    final String path = p.join(dir, fileName);
    final Database db = await openDatabase(
      path,
      version: schemaVersion,
      onConfigure: (Database db) async {
        // Enforce relationships and use WAL for smoother concurrent reads.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) async {
        final Batch batch = db.batch();
        for (final String stmt in _ddl) {
          batch.execute(stmt);
        }
        await batch.commit(noResult: true);
      },
    );
    // WAL cannot run inside a transaction; set it after opening.
    await db.rawQuery('PRAGMA journal_mode=WAL');
    return AppDatabase._(db);
  }

  Future<void> close() => db.close();

  static const List<String> _ddl = <String>[
    '''
    CREATE TABLE folders(
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      created_at INTEGER NOT NULL
    )''',
    '''
    CREATE TABLE notes(
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      folder_id TEXT,
      pinned INTEGER NOT NULL DEFAULT 0,
      color INTEGER,
      date_link INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY(folder_id) REFERENCES folders(id) ON DELETE SET NULL
    )''',
    '''
    CREATE TABLE note_tags(
      note_id TEXT NOT NULL,
      tag TEXT NOT NULL,
      PRIMARY KEY(note_id, tag),
      FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE
    )''',
    '''
    CREATE TABLE tasks(
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      notes TEXT,
      priority INTEGER NOT NULL DEFAULT 1,
      status INTEGER NOT NULL DEFAULT 0,
      deadline INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )''',
    '''
    CREATE TABLE checklist_items(
      id TEXT PRIMARY KEY,
      task_id TEXT NOT NULL,
      text TEXT NOT NULL,
      done INTEGER NOT NULL DEFAULT 0,
      position INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE
    )''',
    '''
    CREATE TABLE events(
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      start INTEGER NOT NULL,
      end INTEGER NOT NULL,
      all_day INTEGER NOT NULL DEFAULT 0,
      color INTEGER,
      note_id TEXT,
      task_id TEXT,
      FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE SET NULL,
      FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE SET NULL
    )''',
    '''
    CREATE TABLE pomodoro_sessions(
      id TEXT PRIMARY KEY,
      start INTEGER NOT NULL,
      end INTEGER NOT NULL,
      focus_seconds INTEGER NOT NULL,
      completed INTEGER NOT NULL DEFAULT 1
    )''',
    '''
    CREATE TABLE settings(
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )''',
    'CREATE INDEX idx_notes_updated ON notes(updated_at DESC)',
    'CREATE INDEX idx_notes_pinned ON notes(pinned)',
    'CREATE INDEX idx_notes_datelink ON notes(date_link)',
    'CREATE INDEX idx_note_tags_tag ON note_tags(tag)',
    'CREATE INDEX idx_tasks_status ON tasks(status)',
    'CREATE INDEX idx_tasks_deadline ON tasks(deadline)',
    'CREATE INDEX idx_checklist_task ON checklist_items(task_id)',
    'CREATE INDEX idx_events_start ON events(start)',
    'CREATE INDEX idx_pomodoro_start ON pomodoro_sessions(start)',
  ];
}
