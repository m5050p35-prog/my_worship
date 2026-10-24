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
import 'screens/custom_tab_body.dart';
import 'screens/lessons_body.dart';
import 'screens/daily_tasks_body.dart';
import 'duration_screen.dart';

class MainShell extends StatefulWidget {
  final UserData user;
  final VoidCallback onLogout;

  const MainShell({super.key, required this.user, required this.onLogout});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  UserData get user => widget.user;

  void _changed() {
    setState(() {});
    context.read<SyncService>().schedulePush(user);
  }

  void _selectTab(int i) {
    if (i < 0) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = context.watch<SettingsProvider>();
    final sync = context.watch<SyncProvider>();

    // ═══════════════════════════════════════════════════════════════
    //  ترتيب التبويبات:
    //  1. الأقسام
    //  2. الدروس
    //  3. المهام اليومية
    //  4. التمارين
    //  5. التبويبات المخصصة
    //  6. الصلاة (قبل الأخير)
    //  7. الصوم (الأخير)
    // ═══════════════════════════════════════════════════════════════
    final tabs = <_Tab>[
      if (s.showSections)
        _Tab(s.sectionsTabLabel, Icons.list_alt, _sections()),
      if (s.showLessons) _Tab('الدروس', Icons.menu_book, _lessons()),
      if (s.showDailyTasks)
        _Tab('المهام اليومية', Icons.task_alt, _dailyTasks()),
      if (s.showWorkout)
        _Tab(t.t('workout'), Icons.fitness_center, _workout()),
      for (final ct in user.customTabs.where((e) => e.enabled))
        _Tab(
          ct.name,
          Icons.bookmark_outline,
          CustomTabBody(tab: ct, onChanged: _changed),
        ),
      if (s.showPrayer) _Tab(t.t('prayer'), Icons.mosque, _prayer()),
      if (s.showFasting)
        _Tab(t.t('fasting'), Icons.nights_stay, _fasting()),
    ];

    if (tabs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(t.t('app_name'))),
        body: const Center(child: Text('لا توجد تبويبات مفعّلة')),
      );
    }

    if (_index >= tabs.length) _index = 0;

    // ✅ بدون default — كل الحالات مغطاة
    switch (s.tabViewMode) {
      case TabViewMode.topTabs:
        return _buildTopTabs(tabs, sync);
      case TabViewMode.grid:
        return _buildGrid(tabs, sync);
      case TabViewMode.bottomBar:
        return _buildBottomBar(tabs, sync);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  نمط 1: شريط سفلي
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBottomBar(List<_Tab> tabs, SyncProvider sync) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[_index].label),
        actions: [
          IconButton(
            icon: Icon(_syncIcon(sync.status)),
            tooltip: 'مزامنة الآن',
            onPressed: () => context.read<SyncService>().pushNow(user),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: AppDrawer(user: user, onLogout: widget.onLogout),
      body: IndexedStack(
        index: _index,
        children: tabs.map((t) => t.body).toList(),
      ),
      bottomNavigationBar: _CustomBottomBar(
        tabs: tabs,
        current: _index,
        onSelect: _selectTab,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  نمط 2: شبكة عائمة (الافتراضي الآن)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildGrid(List<_Tab> tabs, SyncProvider sync) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[_index].label),
        actions: [
          IconButton(
            icon: Icon(_syncIcon(sync.status)),
            tooltip: 'مزامنة الآن',
            onPressed: () => context.read<SyncService>().pushNow(user),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: AppDrawer(user: user, onLogout: widget.onLogout),
      body: IndexedStack(
        index: _index,
        children: tabs.map((t) => t.body).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        tooltip: 'اختر التبويب',
        onPressed: () => _showGridSheet(tabs),
        child: const Icon(Icons.apps, color: Colors.white),
      ),
    );
  }

  void _showGridSheet(List<_Tab> tabs) {
    final primary = Theme.of(context).colorScheme.primary;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'اختر التبويب',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: tabs.length,
                  itemBuilder: (_, i) {
                    final selected = i == _index;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pop(context);
                        _selectTab(i);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? primary.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tabs[i].icon,
                              size: 36,
                              color: selected ? primary : Colors.grey[700],
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                tabs[i].label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: selected ? primary : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  نمط 3: تبويبات أعلى
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTopTabs(List<_Tab> tabs, SyncProvider sync) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[_index].label),
        actions: [
          IconButton(
            icon: Icon(_syncIcon(sync.status)),
            tooltip: 'مزامنة الآن',
            onPressed: () => context.read<SyncService>().pushNow(user),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: tabs.length,
              itemBuilder: (_, i) {
                final selected = i == _index;
                return GestureDetector(
                  onTap: () => _selectTab(i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? primary
                          : Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          tabs[i].icon,
                          size: 16,
                          color: selected ? Colors.white : Colors.grey[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tabs[i].label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color:
                                selected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      drawer: AppDrawer(user: user, onLogout: widget.onLogout),
      body: IndexedStack(
        index: _index,
        children: tabs.map((t) => t.body).toList(),
      ),
    );
  }

  IconData _syncIcon(SyncStatus s) {
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

  // ═══════════════════════════════════════════════════════════════
  Widget _prayer() => PrayerBody(
        days: user.prayerDays,
        sortMode: user.prayerSortMode,
        onSortChanged: (m) {
          user.prayerSortMode = m;
          _changed();
        },
        onChanged: _changed,
        onAddDay: () async {
          final d = await showDurationScreen(context);
          if (d == null) return;
          final start = user.prayerDays.isEmpty
              ? 0
              : user.prayerDays
                  .map((e) => e.dayNumber)
                  .reduce((a, b) => a > b ? a : b);
          final today = DateTime.now();
          for (var i = 0; i < d; i++) {
            user.prayerDays.add(PrayerDay(
              dayNumber: start + i + 1,
              date: today
                  .add(Duration(days: start + i))
                  .toIso8601String()
                  .substring(0, 10),
            ));
          }
          _changed();
        },
      );

  Widget _sections() =>
      SectionsBody(sections: user.sections, onChanged: _changed);

  Widget _lessons() =>
      LessonsBody(lessonDays: user.lessonDays, onChanged: _changed);

  Widget _dailyTasks() =>
      DailyTasksBody(user: user, onChanged: _changed);

  Widget _workout() => WorkoutBody(
        entries: user.workoutEntries,
        config: user.workoutConfig,
        sortMode: user.workoutSortMode,
        onSortChanged: (m) {
          user.workoutSortMode = m;
          _changed();
        },
        onChanged: _changed,
        onConfigChanged: (cfg) {
          user.workoutConfig = cfg;
          user.workoutEntries.clear();
          _generateWorkout();
          _changed();
        },
        onReset: () {
          user.workoutEntries.clear();
          _generateWorkout();
          _changed();
        },
      );

  Widget _fasting() => FastingBody(
        entries: user.fastingEntries,
        sortMode: user.fastingSortMode,
        onSortChanged: (m) {
          user.fastingSortMode = m;
          _changed();
        },
        onChanged: _changed,
        onSetup: (n) {
          user.fastingEntries.clear();
          final today = DateTime.now();
          for (var i = 0; i < n; i++) {
            user.fastingEntries.add(FastingEntry(
              entryNumber: i + 1,
              entryDate: today
                  .add(Duration(days: i))
                  .toIso8601String()
                  .substring(0, 10),
            ));
          }
          _changed();
        },
      );

  void _generateWorkout() {
    final cfg = user.workoutConfig;
    if (cfg.workoutDays <= 0) return;
    final today = DateTime.now();
    var isRest = false;
    var count = 0;
    for (var i = 0; i < 60; i++) {
      if (!isRest && count >= cfg.workoutDays) {
        isRest = true;
        count = 0;
      } else if (isRest && count >= cfg.restDays) {
        isRest = false;
        count = 0;
      }
      user.workoutEntries.add(WorkoutEntry(
        entryNumber: i + 1,
        entryDate:
            today.add(Duration(days: i)).toIso8601String().substring(0, 10),
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

// شريط سفلي قابل للتمرير
class _CustomBottomBar extends StatelessWidget {
  final List<_Tab> tabs;
  final int current;
  final void Function(int) onSelect;

  const _CustomBottomBar({
    required this.tabs,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: tabs.length,
            itemBuilder: (_, i) {
              final selected = i == current;
              return InkWell(
                onTap: () => onSelect(i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tabs[i].icon,
                        size: 22,
                        color: selected ? primary : Colors.grey,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tabs[i].label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                          color: selected ? primary : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
