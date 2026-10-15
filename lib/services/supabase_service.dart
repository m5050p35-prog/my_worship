import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';

class SupabaseService {
  // ═══════════════════════════════════════════════════════════════
  //  إعدادات Supabase
  // ═══════════════════════════════════════════════════════════════
  static const String url = 'https://sjckmzxpckrpdkirqarq.supabase.co';
  static const String publishableKey =
      'sb_publishable_-QWXHP0cozr-PeOdWPauhw_abrpBLZY';

  static SupabaseClient get client => Supabase.instance.client;

  // ═══════════════════════════════════════════════════════════════
  //  التهيئة
  // ═══════════════════════════════════════════════════════════════
  static Future<void> init() async {
    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
      debug: kDebugMode,
    );
    if (kDebugMode) {
      debugPrint('✅ Supabase initialized: $url');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  تحميل مستخدم كامل من السحابة
  // ═══════════════════════════════════════════════════════════════
  static Future<UserData?> loadUser(String identifier) async {
    try {
      final row = await client
          .from('users')
          .select()
          .eq('identifier', identifier)
          .maybeSingle();

      if (row == null) {
        return null;
      }

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

      final days = results[0] as List;
      final wEntries = results[1] as List;
      final fEntries = results[2] as List;

      return UserData(
        id: userId,
        identifier: identifier,
        name: (row['name'] ?? '') as String,
        prayerDays: days
            .map((e) => PrayerDay.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        sections: ((row['sections_data'] as List?) ?? [])
            .map((e) => Section.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        workoutEntries: wEntries
            .map((e) => WorkoutEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        workoutConfig: WorkoutConfig.fromJson(
          Map<String, dynamic>.from((row['workout_config'] as Map?) ?? {}),
        ),
        fastingEntries: fEntries
            .map((e) => FastingEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        fastingConfig: FastingConfig.fromJson(
          Map<String, dynamic>.from((row['fasting_config'] as Map?) ?? {}),
        ),
      );
    } on PostgrestException catch (e) {
      debugPrint('❌ PostgrestException in loadUser: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Error in loadUser: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  حفظ/إنشاء مستخدم + بياناته الفرعية
  // ═══════════════════════════════════════════════════════════════
  static Future<(bool, String?, UserData?)> saveUserWithResult(
    UserData u,
  ) async {
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
        if (kDebugMode) {
          debugPrint('✅ New user created: $userId');
        }
      } else {
        userId = existingId;
        await client.from('users').update(payload).eq('id', userId);
        if (kDebugMode) {
          debugPrint('✅ User updated: $userId');
        }
      }
      u.id = userId;

      final futures = <Future>[];

      if (u.prayerDays.isNotEmpty) {
        futures.add(
          client.from('prayer_days').upsert(
                u.prayerDays
                    .map((d) => {...d.toJson(), 'user_id': userId})
                    .toList(),
                onConflict: 'user_id,day_number',
              ),
        );
      }

      if (u.workoutEntries.isNotEmpty) {
        futures.add(
          client.from('workout_entries').upsert(
                u.workoutEntries
                    .map((e) => {...e.toJson(), 'user_id': userId})
                    .toList(),
                onConflict: 'user_id,entry_number',
              ),
        );
      }

      if (u.fastingEntries.isNotEmpty) {
        futures.add(
          client.from('fasting_entries').upsert(
                u.fastingEntries
                    .map((e) => {...e.toJson(), 'user_id': userId})
                    .toList(),
                onConflict: 'user_id,entry_number',
              ),
        );
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }

      return (true, null, u);
    } on PostgrestException catch (e) {
      final msg =
          'PostgREST: ${e.message}${e.code != null ? " [${e.code}]" : ""}';
      debugPrint('❌ $msg');
      return (false, msg, null);
    } catch (e) {
      final msg = 'Exception: $e';
      debugPrint('❌ $msg');
      return (false, msg, null);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  فحص الاتصال
  // ═══════════════════════════════════════════════════════════════
  static Future<(bool, String?)> ping() async {
    try {
      await client.from('users').select('id').limit(1);
      return (true, null);
    } on PostgrestException catch (e) {
      return (false, 'PostgREST: ${e.message}');
    } catch (e) {
      return (false, '$e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  حذف مستخدم (للاختبار)
  // ═══════════════════════════════════════════════════════════════
  static Future<bool> deleteUser(String identifier) async {
    try {
      await client.from('users').delete().eq('identifier', identifier);
      return true;
    } catch (e) {
      debugPrint('❌ deleteUser: $e');
      return false;
    }
  }
}
