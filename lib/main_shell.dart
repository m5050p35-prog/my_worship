import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'models.dart';
import 'providers/settings_provider.dart';
import 'providers/sync_provider.dart';
import 'services/sync_service.dart';
import 'widgets/app_drawer.dart';
import 'screens/prayer_body.dart';
import 'screens/sections_body.dart';
import 'screens/workout_body.dart';
import 'screens/fasting_body.dart';
import 'duration_screen.dart';

class MainShell extends StatefulWidget {
  final UserData user;
  final VoidCallback onLogout;
  const MainShell({super.key, required this.user, required this.onLogout});
  @override
  State<MainShell> createState() => _S();
}

class _S extends State<MainShell> {
  int _index = 0;

  UserData get user => widget.user;

  void _changed() {
    setState(() {});
    context.read<SyncService>().schedulePush(user);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = context.watch<SettingsProvider>();
    final sync = context.watch<SyncProvider>();

    final tabs = <_Tab>[
      if (s.showPrayer) _Tab(t.t('prayer'), Icons.mosque, _prayer()),
      if (s.showSections) _Tab(s.sectionsTabLabel, Icons.list_alt, _sections()),
      if (s.showWorkout) _Tab(t.t('workout'), Icons.fitness_center, _workout()),
      if (s.showFasting) _Tab(t.t('fasting'), Icons.nights_stay, _fasting()),
    ];

    if (tabs.isEmpty) {
      return Scaffold(appBar: AppBar(title: Text(t.t('app_name'))),
        body: const Center(child: Text('لا توجد تبويبات مفعّلة')));
    }

    if (_index >= tabs.length) _index = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[_index].label),
        actions: [
          IconButton(icon: Icon(_syncIcon(sync.status)),
            onPressed: () => context.read<SyncService>().pushNow(user)),
          const SizedBox(width: 8),
        ],
      ),
      drawer: AppDrawer(user: user, onLogout: widget.onLogout),
      body: tabs[_index].body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: [for (final tab in tabs)
          BottomNavigationBarItem(icon: Icon(tab.icon), label: tab.label)],
      ),
    );
  }

  IconData _syncIcon(SyncStatus s) {
    switch (s) {
      case SyncStatus.ok: return Icons.cloud_done;
      case SyncStatus.syncing: return Icons.cloud_sync;
      case SyncStatus.fail: return Icons.cloud_off;
      default: return Icons.cloud_queue;
    }
  }

  Widget _prayer() => PrayerBody(
    days: user.prayerDays, onChanged: _changed,
    onAddDay: () async {
      final d = await showDurationScreen(context);
      if (d == null) return;
      final start = user.prayerDays.isEmpty ? 0 : user.prayerDays.length;
      final today = DateTime.now();
      for (var i = 0; i < d; i++) {
        user.prayerDays.add(PrayerDay(
          dayNumber: start + i + 1,
          date: today.add(Duration(days: start + i)).toIso8601String().substring(0, 10),
        ));
      }
      _changed();
    });

  Widget _sections() => SectionsBody(sections: user.sections, onChanged: _changed);

  Widget _workout() => WorkoutBody(
    entries: user.workoutEntries, config: user.workoutConfig, onChanged: _changed,
    onConfigChanged: (cfg) {
      user.workoutConfig = cfg;
      user.workoutEntries.clear();
      _generateWorkout();
      _changed();
    },
    onReset: () { user.workoutEntries.clear(); _generateWorkout(); _changed(); },
  );

  Widget _fasting() => FastingBody(
    entries: user.fastingEntries, onChanged: _changed,
    onSetup: (n) {
      user.fastingEntries.clear();
      final today = DateTime.now();
      for (var i = 0; i < n; i++) {
        user.fastingEntries.add(FastingEntry(
          entryNumber: i + 1,
          entryDate: today.add(Duration(days: i)).toIso8601String().substring(0, 10),
        ));
      }
      _changed();
    });

  void _generateWorkout() {
    final cfg = user.workoutConfig;
    if (cfg.workoutDays <= 0) return;
    final today = DateTime.now();
    var isRest = false;
    var count = 0;
    for (var i = 0; i < 60; i++) {
      if (!isRest && count >= cfg.workoutDays) { isRest = true; count = 0; }
      else if (isRest && count >= cfg.restDays) { isRest = false; count = 0; }
      user.workoutEntries.add(WorkoutEntry(
        entryNumber: i + 1,
        entryDate: today.add(Duration(days: i)).toIso8601String().substring(0, 10),
        isRest: isRest,
      ));
      count++;
    }
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final Widget body;
  _Tab(this.label, this.icon, this.body);
}
