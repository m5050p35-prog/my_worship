import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _init = false;

  static Future<void> init() async {
    if (_init) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {}

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
      int hour, int minute, String title, String body) async {
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

  static Future<void> scheduleSectionReminder({
    required String key,
    required String title,
    required ReminderConfig cfg,
  }) async {
    await init();
    await cancelSectionReminders(key);
    if (!cfg.enabled) return;

    final baseId = key.hashCode.abs() % 1000 * 100;
    final now = tz.TZDateTime.now(tz.local);
    var baseTime = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, cfg.hour, cfg.minute);
    if (baseTime.isBefore(now)) {
      baseTime = baseTime.add(const Duration(days: 1));
    }

    for (int i = 0; i < 30; i++) {
      final targetDate = baseTime.add(Duration(days: i));
      bool shouldSchedule = false;
      switch (cfg.freq) {
        case ReminderFrequency.daily:
          shouldSchedule = true;
          break;
        case ReminderFrequency.alternate:
          shouldSchedule = i % 2 == 0;
          break;
        case ReminderFrequency.weekdays:
          shouldSchedule = targetDate.weekday >= 1 && targetDate.weekday <= 5;
          break;
        case ReminderFrequency.weekends:
          shouldSchedule = targetDate.weekday == 6 || targetDate.weekday == 7;
          break;
        case ReminderFrequency.off:
          break;
      }
      if (shouldSchedule) {
        await _plugin.zonedSchedule(
          baseId + i,
          'تذكير: $title',
          'حان وقت $title الآن',
          targetDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'section_reminders',
              'Section Reminders',
              channelDescription: 'Reminders for specific sections',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  static Future<void> cancelSectionReminders(String key) async {
    await init();
    final baseId = key.hashCode.abs() % 1000 * 100;
    for (int i = 0; i < 30; i++) {
      await _plugin.cancel(baseId + i);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  تذكير المصرف اليومي (9 مساءً)
  // ═══════════════════════════════════════════════════════════════
  static Future<void> scheduleExpenseDaily(bool enabled) async {
    await init();
    await _plugin.cancel(800);
    if (!enabled) return;

    await _plugin.zonedSchedule(
      800,
      'تذكير المصرف اليومي',
      'لا تنسَ تسجيل مصاريف اليوم',
      _nextInstance(21, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'expense_daily',
          'تذكير المصرف',
          channelDescription: 'تذكير يومي بتسجيل المصاريف عند 9 مساءً',
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
    if (d.isBefore(now)) d = d.add(const Duration(days: 1));
    return d;
  }
}
