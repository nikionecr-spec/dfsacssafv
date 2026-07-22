import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../notifications/notification_service.dart';
import '../settings/settings_repository.dart';

/// The opened database. Overridden in `main()` with the real instance so the
/// rest of the app can read it synchronously.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);

/// Convenience accessor for the raw sqflite [Database].
final databaseProvider = Provider<Database>(
  (ref) => ref.watch(appDatabaseProvider).db,
);

/// The initialised notification service. Overridden in `main()`.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) =>
      throw UnimplementedError('notificationServiceProvider must be overridden'),
);

/// The settings repository (seeded with values loaded at startup). Overridden
/// in `main()`.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw UnimplementedError(
      'settingsRepositoryProvider must be overridden'),
);
