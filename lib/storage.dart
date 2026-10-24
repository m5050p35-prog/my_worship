import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class Storage {
  static const _kUsers = 'users_store';
  static const _kSession = 'current_user_email';

  static Future<void> saveSession(String email) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kSession, email);
  }

  static Future<String?> loadSession() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kSession);
  }

  static Future<void> clearSession() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kSession);
  }

  static Future<Map<String, dynamic>> _readAll() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_kUsers);
    if (s == null || s.isEmpty) return {};
    return Map<String, dynamic>.from(jsonDecode(s));
  }

  static Future<void> saveUser(UserData u) async {
    final all = await _readAll();
    all[u.identifier] = u.toJson();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUsers, jsonEncode(all));
  }

  static Future<UserData?> loadUser(String email) async {
    final all = await _readAll();
    final j = all[email];
    if (j == null) return null;
    return _fromJson(Map<String, dynamic>.from(j));
  }

  static UserData _fromJson(Map<String, dynamic> j) {
    final rawLessons = (j['lesson_days'] as List? ?? [])
        .map((e) => LessonDay.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final rawDaily = (j['daily_task_days'] as List? ?? [])
        .map((e) => DailyTaskDay.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return UserData(
      id: j['id'],
      identifier: j['identifier'] ?? '',
      name: j['name'] ?? '',
      prayerSortMode: SortModeExt.fromKey(j['prayer_sort_mode'] as String?),
      workoutSortMode: SortModeExt.fromKey(j['workout_sort_mode'] as String?),
      fastingSortMode: SortModeExt.fromKey(j['fasting_sort_mode'] as String?),
      dailyTasksStartDate: j['daily_tasks_start_date'] ?? '',
      dailyTaskDays: rawDaily,
      prayerDays: (j['prayer_days'] as List? ?? [])
          .map((e) => PrayerDay.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      sections: (j['sections'] as List? ?? [])
          .map((e) => Section.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      customTabs: (j['custom_tabs'] as List? ?? [])
          .map((e) => CustomTab.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      lessonDays: UserData.normalizeWeek(rawLessons),
      workoutEntries: (j['workout_entries'] as List? ?? [])
          .map((e) => WorkoutEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      workoutConfig: WorkoutConfig.fromJson(
          Map<String, dynamic>.from(j['workout_config'] ?? {})),
      fastingEntries: (j['fasting_entries'] as List? ?? [])
          .map((e) => FastingEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      fastingConfig: FastingConfig.fromJson(
          Map<String, dynamic>.from(j['fasting_config'] ?? {})),
    );
  }
}
