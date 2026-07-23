import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers/providers.dart';
import 'core/settings/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Opt into the highest available refresh rate (90/120 Hz) on Android.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {
      // Device does not support mode switching; ignore.
    }
  }

  final AppDatabase database = await AppDatabase.open();

  final NotificationService notifications = NotificationService();
  await notifications.init();

  final Map<String, String> rawSettings =
      await SettingsRepository.load(database.db);
  final SettingsRepository settingsRepository =
      SettingsRepository(database.db, rawSettings);

  runApp(
    ProviderScope(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(database),
        notificationServiceProvider.overrideWithValue(notifications),
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
      child: const AuraApp(),
    ),
  );
}
