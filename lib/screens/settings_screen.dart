import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../providers/sync_provider.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import 'supabase_debug_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = context.watch<SettingsProvider>();
    final sync = context.watch<SyncProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(t.t('settings'))),
      body: ListView(
        children: [
          const _Header('المظهر'),
          SwitchListTile(
            title: Text(t.t('dark_mode')),
            value: s.darkMode,
            onChanged: s.setDark,
            secondary: const Icon(Icons.dark_mode),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(t.t('language')),
            trailing: DropdownButton<String>(
              value: s.lang,
              items: const [
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (v) {
                if (v != null) {
                  s.setLang(v);
                }
              },
            ),
          ),
          const Divider(),
          const _Header('التبويبات'),
          SwitchListTile(
            title: Text(t.t('prayer')),
            value: s.showPrayer,
            onChanged: s.setShowPrayer,
          ),
          SwitchListTile(
            title: Text(t.t('sections')),
            value: s.showSections,
            onChanged: s.setShowSections,
          ),
          SwitchListTile(
            title: Text(t.t('workout')),
            value: s.showWorkout,
            onChanged: s.setShowWorkout,
          ),
          SwitchListTile(
            title: Text(t.t('fasting')),
            value: s.showFasting,
            onChanged: s.setShowFasting,
          ),
          ListTile(
            title: const Text('اسم تبويب الأقسام'),
            subtitle: Text(s.sectionsTabLabel),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final c = TextEditingController(text: s.sectionsTabLabel);
              final r = await showDialog<String>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('اسم التبويب'),
                  content: TextField(controller: c),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, c.text),
                      child: const Text('حفظ'),
                    ),
                  ],
                ),
              );
              if (r != null && r.trim().isNotEmpty) {
                s.setSectionsLabel(r.trim());
              }
            },
          ),
          SwitchListTile(
            title: const Text('ترتيب الأيام (تصاعدي)'),
            value: s.ascendingOrder,
            onChanged: s.setAscending,
          ),
          const Divider(),
          const _Header('الإشعارات'),
          SwitchListTile(
            title: Text(t.t('notifications')),
            value: s.notificationsEnabled,
            onChanged: (v) async {
              s.setNotifEnabled(v);
              if (v) {
                await NotificationService.scheduleDaily(
                  s.notifyHour,
                  s.notifyMinute,
                  'تذكير',
                  'لا تنسَ متابعة عباداتك',
                );
              } else {
                await NotificationService.cancelAll();
              }
            },
          ),
          ListTile(
            title: const Text('وقت الإشعار'),
            subtitle: Text(
              '${s.notifyHour.toString().padLeft(2, '0')}:${s.notifyMinute.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final r = await showTimePicker(
                context: context,
                initialTime:
                    TimeOfDay(hour: s.notifyHour, minute: s.notifyMinute),
              );
              if (r != null) {
                s.setNotifTime(r.hour, r.minute);
                if (s.notificationsEnabled) {
                  await NotificationService.scheduleDaily(
                    r.hour,
                    r.minute,
                    'تذكير',
                    'حان وقت العبادات',
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('اختبار إشعار'),
            onTap: () => NotificationService.showTest(),
          ),
          const Divider(),
          const _Header('المزامنة'),
          ListTile(
            leading: Icon(_iconFor(sync.status)),
            title: const Text('الحالة'),
            subtitle: Text(sync.lastError ?? sync.status.name),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('فحص الاتصال بـ Supabase'),
            onTap: () async {
              final (ok, err) = await SupabaseService.ping();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? '✅ الاتصال ناجح' : '❌ $err')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('فحص مفصل'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupabaseDebugScreen()),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(SyncStatus s) {
    switch (s) {
      case SyncStatus.ok:
        return Icons.cloud_done;
      case SyncStatus.syncing:
        return Icons.cloud_sync;
      case SyncStatus.fail:
        return Icons.cloud_off;
      default:
        return Icons.cloud_queue;
    }
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext c) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
      );
}
