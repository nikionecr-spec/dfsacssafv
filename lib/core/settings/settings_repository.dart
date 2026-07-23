import 'package:sqflite/sqflite.dart';

import 'app_settings.dart';

/// Reads and writes [AppSettings] to the `settings` key/value table.
///
/// The current value is cached in memory so the theme can be read
/// synchronously during the first frame (no async flicker at startup).
class SettingsRepository {
  SettingsRepository(this._db, Map<String, String> initial)
      : _current = AppSettings.fromMap(initial);

  final Database _db;
  AppSettings _current;

  AppSettings get current => _current;

  /// Loads the raw key/value rows. Call once before constructing the repo.
  static Future<Map<String, String>> load(Database db) async {
    final List<Map<String, Object?>> rows =
        await db.query('settings', columns: <String>['key', 'value']);
    return <String, String>{
      for (final Map<String, Object?> r in rows)
        r['key']! as String: r['value']! as String,
    };
  }

  Future<void> save(AppSettings settings) async {
    _current = settings;
    final Batch batch = _db.batch();
    settings.toMap().forEach((String key, String value) {
      batch.insert(
        'settings',
        <String, Object?>{'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    await batch.commit(noResult: true);
  }
}
