import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';

class SupabaseService {
  static const String url = 'https://sjckmzxpckrpdkirqarq.supabase.co';
  static const String publishableKey =
      'sb_publishable_-QWXHP0cozr-PeOdWPauhw_abrpBLZY';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
      debug: kDebugMode,
    );
    if (kDebugMode) debugPrint('✅ Supabase init: $url');
  }

  static Future<UserData?> loadUser(String identifier) async {
    final row = await client
        .from('users')
        .select()
        .eq('identifier', identifier)
        .maybeSingle();

    if (row == null) return null;
    final userId = row['id'] as String;

    final results = await Future.wait([
      client
          .from('prayer_days')
          .select()
          .eq('user_id', userId)
          .order('day_number'),
      client
          .from('workout_entries')
          .select()
          .eq('user_id', userId)
          .order('entry_number'),
      client
          .from('fasting_entries')
          .select()
          .eq('user_id', userId)
          .order('entry_number'),
    ]);

    final sectionsData = (row['sections_data'] as List? ?? [])
        .map((e) => Section.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    // ترتيب الأيام داخل الأقسام حسب sort_mode
    for (final s in sectionsData) {
      s.applySort();
    }

    final customTabsData = (row['custom_tabs_data'] as List? ?? [])
        .map((e) => CustomTab.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    for (final t in customTabsData) {
      t.applySort();
    }

    return UserData(
      id: userId,
      identifier: identifier,
      name: (row['name'] ?? '') as String,
      prayerSortMode: SortModeExt.fromKey(row['prayer_sort_mode'] as String?),
      workoutSortMode: SortModeExt.fromKey(row['workout_sort_mode'] as String?),
      fastingSortMode: SortModeExt.fromKey(row['fasting_sort_mode'] as String?),
      prayerDays: (results[0] as List)
          .map((e) => PrayerDay.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      sections: sectionsData,
      customTabs: customTabsData,
      workoutEntries: (results[1] as List)
          .map((e) => WorkoutEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      workoutConfig: WorkoutConfig.fromJson(
          Map<String, dynamic>.from((row['workout_config'] as Map?) ?? {})),
      fastingEntries: (results[2] as List)
          .map((e) => FastingEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      fastingConfig: FastingConfig.fromJson(
          Map<String, dynamic>.from((row['fasting_config'] as Map?) ?? {})),
    );
  }

  static Future<(bool, String?, UserData?)> saveUserWithResult(
      UserData u) async {
    try {
      final existing = await client
          .from('users')
          .select('id')
          .eq('identifier', u.identifier)
          .maybeSingle();

      final existingId = existing?['id'] as String?;
      final payload = <String, dynamic>{
        'identifier': u.identifier,
        'name': u.name,
        'workout_config': u.workoutConfig.toJson(),
        'fasting_config': u.fastingConfig.toJson(),
        'sections_data': u.sections.map((e) => e.toJson()).toList(),
        'custom_tabs_data': u.customTabs.map((e) => e.toJson()).toList(),
        'prayer_sort_mode': u.prayerSortMode.name,
        'workout_sort_mode': u.workoutSortMode.name,
        'fasting_sort_mode': u.fastingSortMode.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      final String userId;
      if (existingId == null) {
        final inserted = await client
            .from('users')
            .insert(payload)
            .select('id')
            .single();
        userId = inserted['id'] as String;
      } else {
        userId = existingId;
        await client.from('users').update(payload).eq('id', userId);
      }
      u.id = userId;

      final futures = <Future>[];
      if (u.prayerDays.isNotEmpty) {
        futures.add(client.from('prayer_days').upsert(
              u.prayerDays
                  .map((d) => {...d.toJson(), 'user_id': userId})
                  .toList(),
              onConflict: 'user_id,day_number',
            ));
      }
      if (u.workoutEntries.isNotEmpty) {
        futures.add(client.from('workout_entries').upsert(
              u.workoutEntries
                  .map((e) => {...e.toJson(), 'user_id': userId})
                  .toList(),
              onConflict: 'user_id,entry_number',
            ));
      }
      if (u.fastingEntries.isNotEmpty) {
        futures.add(client.from('fasting_entries').upsert(
              u.fastingEntries
                  .map((e) => {...e.toJson(), 'user_id': userId})
                  .toList(),
              onConflict: 'user_id,entry_number',
            ));
      }
      if (futures.isNotEmpty) await Future.wait(futures);

      return (true, null, u);
    } on PostgrestException catch (e) {
      return (false, 'PostgREST: ${e.message}', null);
    } catch (e) {
      return (false, '$e', null);
    }
  }

  static Future<(bool, String?)> ping() async {
    try {
      await client.from('users').select('id').limit(1);
      return (true, null);
    } catch (e) {
      return (false, '$e');
    }
  }
}
