// ═══════════════════════════════════════════════════════════════
//  SortMode — أوضاع الترتيب
// ═══════════════════════════════════════════════════════════════
enum SortMode { ascending, descending, incompleteFirst, completeFirst }

extension SortModeExt on SortMode {
  String get label {
    switch (this) {
      case SortMode.ascending:
        return 'تصاعدي (1 → N)';
      case SortMode.descending:
        return 'تنازلي (N → 1)';
      case SortMode.incompleteFirst:
        return 'غير المكتمل أولاً';
      case SortMode.completeFirst:
        return 'المكتمل أولاً';
    }
  }

  static SortMode fromKey(String? k) => SortMode.values.firstWhere(
        (e) => e.name == k,
        orElse: () => SortMode.incompleteFirst,
      );
}

// ═══════════════════════════════════════════════════════════════
//  PrayerDay
// ═══════════════════════════════════════════════════════════════
class PrayerDay {
  final int dayNumber;
  final String date;
  bool fajr, dhuhr, asr, maghrib, isha;

  PrayerDay({
    required this.dayNumber,
    required this.date,
    this.fajr = false,
    this.dhuhr = false,
    this.asr = false,
    this.maghrib = false,
    this.isha = false,
  });

  int get completed =>
      [fajr, dhuhr, asr, maghrib, isha].where((e) => e).length;
  bool get isComplete => completed == 5;

  Map<String, dynamic> toJson() => {
        'day_number': dayNumber,
        'date': date,
        'fajr': fajr,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
      };

  factory PrayerDay.fromJson(Map<String, dynamic> j) => PrayerDay(
        dayNumber: j['day_number'] ?? 0,
        date: j['date'] ?? '',
        fajr: j['fajr'] ?? false,
        dhuhr: j['dhuhr'] ?? false,
        asr: j['asr'] ?? false,
        maghrib: j['maghrib'] ?? false,
        isha: j['isha'] ?? false,
      );
}

// ═══════════════════════════════════════════════════════════════
//  SectionDay
// ═══════════════════════════════════════════════════════════════
class SectionDay {
  final int dayNumber;
  final String date;
  bool isDone;
  String note;

  SectionDay({
    required this.dayNumber,
    required this.date,
    this.isDone = false,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'day_number': dayNumber,
        'date': date,
        'is_done': isDone,
        'note': note,
      };

  factory SectionDay.fromJson(Map<String, dynamic> j) => SectionDay(
        dayNumber: j['day_number'] ?? 0,
        date: j['date'] ?? '',
        isDone: j['is_done'] ?? false,
        note: j['note'] ?? '',
      );
}

// ═══════════════════════════════════════════════════════════════
//  Section
// ═══════════════════════════════════════════════════════════════
class Section {
  final String id;
  String name;
  String note;
  SortMode sortMode;
  List<SectionDay> days;

  Section({
    required this.id,
    required this.name,
    this.note = '',
    this.sortMode = SortMode.incompleteFirst,
    List<SectionDay>? days,
  }) : days = days ?? [];

  void applySort() {
    switch (sortMode) {
      case SortMode.ascending:
        days.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
        break;
      case SortMode.descending:
        days.sort((a, b) => b.dayNumber.compareTo(a.dayNumber));
        break;
      case SortMode.incompleteFirst:
        days.sort((a, b) {
          if (a.isDone == b.isDone) {
            return a.dayNumber.compareTo(b.dayNumber);
          }
          return a.isDone ? 1 : -1;
        });
        break;
      case SortMode.completeFirst:
        days.sort((a, b) {
          if (a.isDone == b.isDone) {
            return a.dayNumber.compareTo(b.dayNumber);
          }
          return a.isDone ? -1 : 1;
        });
        break;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        'sort_mode': sortMode.name,
        'days': days.map((d) => d.toJson()).toList(),
      };

  factory Section.fromJson(Map<String, dynamic> j) => Section(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        note: j['note'] ?? '',
        sortMode: SortModeExt.fromKey(j['sort_mode'] as String?),
        days: (j['days'] as List? ?? [])
            .map((e) => SectionDay.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

// ═══════════════════════════════════════════════════════════════
//  CustomTab — تبويب مخصص يعمل كقسم مستقل
// ═══════════════════════════════════════════════════════════════
class CustomTabDay {
  final int dayNumber;
  final String date;
  bool isDone;
  String note;

  CustomTabDay({
    required this.dayNumber,
    required this.date,
    this.isDone = false,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'day_number': dayNumber,
        'date': date,
        'is_done': isDone,
        'note': note,
      };

  factory CustomTabDay.fromJson(Map<String, dynamic> j) => CustomTabDay(
        dayNumber: j['day_number'] ?? 0,
        date: j['date'] ?? '',
        isDone: j['is_done'] ?? false,
        note: j['note'] ?? '',
      );
}

class CustomTab {
  final String id;
  String name;
  String type; // قسم / ورد / صدقة ... حر
  String note;
  bool enabled; // يظهر في الشريط السفلي؟
  SortMode sortMode;
  List<CustomTabDay> days;

  CustomTab({
    required this.id,
    required this.name,
    this.type = '',
    this.note = '',
    this.enabled = true,
    this.sortMode = SortMode.incompleteFirst,
    List<CustomTabDay>? days,
  }) : days = days ?? [];

  int get doneCount => days.where((d) => d.isDone).length;

  void applySort() {
    switch (sortMode) {
      case SortMode.ascending:
        days.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
        break;
      case SortMode.descending:
        days.sort((a, b) => b.dayNumber.compareTo(a.dayNumber));
        break;
      case SortMode.incompleteFirst:
        days.sort((a, b) {
          if (a.isDone == b.isDone) {
            return a.dayNumber.compareTo(b.dayNumber);
          }
          return a.isDone ? 1 : -1;
        });
        break;
      case SortMode.completeFirst:
        days.sort((a, b) {
          if (a.isDone == b.isDone) {
            return a.dayNumber.compareTo(b.dayNumber);
          }
          return a.isDone ? -1 : 1;
        });
        break;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'note': note,
        'enabled': enabled,
        'sort_mode': sortMode.name,
        'days': days.map((d) => d.toJson()).toList(),
      };

  factory CustomTab.fromJson(Map<String, dynamic> j) => CustomTab(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        type: j['type'] ?? '',
        note: j['note'] ?? '',
        enabled: j['enabled'] ?? true,
        sortMode: SortModeExt.fromKey(j['sort_mode'] as String?),
        days: (j['days'] as List? ?? [])
            .map((e) => CustomTabDay.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

// ═══════════════════════════════════════════════════════════════
//  WorkoutEntry / Config
// ═══════════════════════════════════════════════════════════════
class WorkoutEntry {
  final int entryNumber;
  final String entryDate;
  bool isDone;
  final bool isRest;
  String note;

  WorkoutEntry({
    required this.entryNumber,
    required this.entryDate,
    this.isDone = false,
    this.isRest = false,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'entry_number': entryNumber,
        'entry_date': entryDate,
        'is_done': isDone,
        'is_rest': isRest,
        'note': note,
      };

  factory WorkoutEntry.fromJson(Map<String, dynamic> j) => WorkoutEntry(
        entryNumber: j['entry_number'] ?? 0,
        entryDate: j['entry_date'] ?? '',
        isDone: j['is_done'] ?? false,
        isRest: j['is_rest'] ?? false,
        note: j['note'] ?? '',
      );
}

class WorkoutConfig {
  int workoutDays;
  int restDays;

  WorkoutConfig({this.workoutDays = 3, this.restDays = 1});

  Map<String, dynamic> toJson() =>
      {'workout_days': workoutDays, 'rest_days': restDays};

  factory WorkoutConfig.fromJson(Map<String, dynamic> j) => WorkoutConfig(
        workoutDays: j['workout_days'] ?? 3,
        restDays: j['rest_days'] ?? 1,
      );
}

// ═══════════════════════════════════════════════════════════════
//  Fasting
// ═══════════════════════════════════════════════════════════════
class FastingEntry {
  final int entryNumber;
  final String entryDate;
  bool isDone;
  String note;

  FastingEntry({
    required this.entryNumber,
    required this.entryDate,
    this.isDone = false,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'entry_number': entryNumber,
        'entry_date': entryDate,
        'is_done': isDone,
        'note': note,
      };

  factory FastingEntry.fromJson(Map<String, dynamic> j) => FastingEntry(
        entryNumber: j['entry_number'] ?? 0,
        entryDate: j['entry_date'] ?? '',
        isDone: j['is_done'] ?? false,
        note: j['note'] ?? '',
      );
}

class FastingConfig {
  int totalDays;

  FastingConfig({this.totalDays = 30});

  Map<String, dynamic> toJson() => {'total_days': totalDays};

  factory FastingConfig.fromJson(Map<String, dynamic> j) =>
      FastingConfig(totalDays: j['total_days'] ?? 30);
}

// ═══════════════════════════════════════════════════════════════
//  UserData
// ═══════════════════════════════════════════════════════════════
class UserData {
  String? id;
  String identifier;
  String name;
  List<PrayerDay> prayerDays;
  List<Section> sections;
  List<CustomTab> customTabs;
  List<WorkoutEntry> workoutEntries;
  WorkoutConfig workoutConfig;
  List<FastingEntry> fastingEntries;
  FastingConfig fastingConfig;

  UserData({
    this.id,
    required this.identifier,
    this.name = '',
    List<PrayerDay>? prayerDays,
    List<Section>? sections,
    List<CustomTab>? customTabs,
    List<WorkoutEntry>? workoutEntries,
    WorkoutConfig? workoutConfig,
    List<FastingEntry>? fastingEntries,
    FastingConfig? fastingConfig,
  })  : prayerDays = prayerDays ?? [],
        sections = sections ?? [],
        customTabs = customTabs ?? [],
        workoutEntries = workoutEntries ?? [],
        workoutConfig = workoutConfig ?? WorkoutConfig(),
        fastingEntries = fastingEntries ?? [],
        fastingConfig = fastingConfig ?? FastingConfig();

  Map<String, dynamic> toJson() => {
        'id': id,
        'identifier': identifier,
        'name': name,
        'prayer_days': prayerDays.map((e) => e.toJson()).toList(),
        'sections': sections.map((e) => e.toJson()).toList(),
        'custom_tabs': customTabs.map((e) => e.toJson()).toList(),
        'workout_entries': workoutEntries.map((e) => e.toJson()).toList(),
        'workout_config': workoutConfig.toJson(),
        'fasting_entries': fastingEntries.map((e) => e.toJson()).toList(),
        'fasting_config': fastingConfig.toJson(),
      };
}
