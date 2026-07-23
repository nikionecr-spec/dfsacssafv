import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Entry point invoked when a notification action is tapped while the app is
/// in the background. Must be a top-level, vm-entry-point function.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Foreground handling is done via [NotificationService.onAction]; for the
  // background isolate we simply no-op (the OS keeps the timer state).
}

/// Wraps `flutter_local_notifications` behind a small, intention-revealing API.
///
/// Two channels are used:
///  * `reminders`  — high-importance, one-shot task/event reminders.
///  * `pomodoro`   — low-importance ongoing notification that mirrors the
///    running focus timer and exposes pause / skip / stop actions.
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Called (on the foreground isolate) with the action id when the user taps
  /// a Pomodoro notification button. The Pomodoro controller subscribes to it.
  ValueChanged<String>? onAction;

  static const String reminderChannelId = 'reminders';
  static const String pomodoroChannelId = 'pomodoro';
  static const int pomodoroNotificationId = 1001;

  static const String actionPause = 'pomodoro_pause';
  static const String actionResume = 'pomodoro_resume';
  static const String actionSkip = 'pomodoro_skip';
  static const String actionStop = 'pomodoro_stop';

  bool _initialised = false;

  Future<void> init() async {
    if (_initialised) return;
    tzdata.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@drawable/app_icon');
    const InitializationSettings settings =
        InitializationSettings(android: androidInit);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        final String? actionId = r.actionId;
        if (actionId != null && actionId.isNotEmpty) {
          onAction?.call(actionId);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(const AndroidNotificationChannel(
        reminderChannelId,
        'Reminders',
        description: 'Task and event reminders',
        importance: Importance.high,
      ));
      await android.createNotificationChannel(const AndroidNotificationChannel(
        pomodoroChannelId,
        'Focus timer',
        description: 'Ongoing Pomodoro session',
        importance: Importance.low,
        playSound: false,
      ));
    }
    _initialised = true;
  }

  /// Requests runtime permissions (Android 13+ notifications, exact alarms).
  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  /// Schedules a one-shot reminder at [when]. We schedule against an absolute
  /// UTC instant, which fires at the correct wall-clock moment without needing
  /// the device's IANA timezone name.
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {
    if (when.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when.toUtc(), tz.UTC),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          reminderChannelId,
          'Reminders',
          channelDescription: 'Task and event reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Shows / updates the ongoing Pomodoro notification.
  Future<void> showPomodoro({
    required String title,
    required String body,
    required bool isRunning,
  }) async {
    final List<AndroidNotificationAction> actions = <AndroidNotificationAction>[
      if (isRunning)
        const AndroidNotificationAction(actionPause, 'Pause')
      else
        const AndroidNotificationAction(actionResume, 'Resume'),
      const AndroidNotificationAction(actionSkip, 'Skip'),
      const AndroidNotificationAction(actionStop, 'Stop'),
    ];

    final AndroidNotificationDetails android = AndroidNotificationDetails(
      pomodoroChannelId,
      'Focus timer',
      channelDescription: 'Ongoing Pomodoro session',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      playSound: false,
      actions: actions,
    );

    await _plugin.show(
      pomodoroNotificationId,
      title,
      body,
      NotificationDetails(android: android),
    );
  }

  Future<void> cancelPomodoro() =>
      _plugin.cancel(pomodoroNotificationId);

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();

  /// Stable positive 31-bit notification id derived from an entity id.
  static int idFrom(String entityId) => entityId.hashCode & 0x7fffffff;
}
