import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_model.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final zoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();

    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleAllFromReminders(List<ReminderModel> reminders) async {
    await initialize();
    await _plugin.cancelAll();

    for (final reminder in reminders) {
      if (!reminder.isActive) continue;
      await scheduleReminder(reminder);
    }
  }

  Future<void> scheduleReminder(ReminderModel reminder) async {
    await initialize();

    if (!reminder.isActive) {
      await cancelReminder(reminder.id);
      return;
    }

    final now = DateTime.now();
    if (!reminder.time.isAfter(now)) {
      return;
    }

    final id = _notificationId(reminder.id);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'alarm_channel',
        'Alarm Reminders',
        channelDescription: 'Rings for scheduled reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        category: AndroidNotificationCategory.alarm,
      ),
      iOS: DarwinNotificationDetails(presentSound: true),
    );

    final scheduledDate = tz.TZDateTime.from(reminder.time, tz.local);

    if (reminder.repeat == 'daily') {
      await _plugin.zonedSchedule(
        id,
        'Alarm Ringing',
        reminder.title,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return;
    }

    await _plugin.zonedSchedule(
      id,
      'Alarm Ringing',
      reminder.title,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(String reminderId) async {
    await initialize();
    await _plugin.cancel(_notificationId(reminderId));
  }

  int _notificationId(String reminderId) {
    return reminderId.hashCode & 0x7fffffff;
  }
}
