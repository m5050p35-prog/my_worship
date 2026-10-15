import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _init = false;

  static Future<void> init() async {
    if (_init) {
      return;
    }
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // fallback to default local
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (_) {},
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _init = true;
  }

  static Future<void> scheduleDaily(
    int hour,
    int minute,
    String title,
    String body,
  ) async {
    await init();
    await _plugin.cancelAll();
    await _plugin.zonedSchedule(
      0,
      title,
      body,
      _nextInstance(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily',
          'Daily Reminder',
          channelDescription: 'Daily worship reminder',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  static Future<void> showTest() async {
    await init();
    await _plugin.show(
      999,
      'اختبار',
      'هذا إشعار تجريبي',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test',
          'Test',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static tz.TZDateTime _nextInstance(int h, int m) {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
    if (d.isBefore(now)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }
}
