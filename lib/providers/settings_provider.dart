import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

class SettingsProvider extends ChangeNotifier {
  bool darkMode = false;
  String lang = 'ar';
  bool showPrayer = true;
  bool showLessons = true;
  bool showWorkout = true;
  bool showFasting = true;
  bool showDailyTasks = true;
  bool showExpenses = true;
  String sectionsTabLabel = 'الأقسام';
  bool ascendingOrder = true;
  bool notificationsEnabled = false;
  int notifyHour = 20;
  int notifyMinute = 0;
  TabViewMode tabViewMode = TabViewMode.grid;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    darkMode = sp.getBool('dark') ?? false;
    lang = sp.getString('lang') ?? 'ar';
    showPrayer = sp.getBool('showPrayer') ?? true;
    showLessons = sp.getBool('showLessons') ?? true;
    showWorkout = sp.getBool('showWorkout') ?? true;
    showFasting = sp.getBool('showFasting') ?? true;
    showDailyTasks = sp.getBool('showDailyTasks') ?? true;
    showExpenses = sp.getBool('showExpenses') ?? true;
    sectionsTabLabel =
        sp.getString('sectionsLabel') ?? (lang == 'ar' ? 'الأقسام' : 'Sections');
    ascendingOrder = sp.getBool('ascending') ?? true;
    notificationsEnabled = sp.getBool('notifEnabled') ?? false;
    notifyHour = sp.getInt('notifH') ?? 20;
    notifyMinute = sp.getInt('notifM') ?? 0;
    tabViewMode = TabViewModeExt.fromKey(sp.getString('tabViewMode'));
    notifyListeners();
  }

  Future<void> _save(String k, Object v) async {
    final sp = await SharedPreferences.getInstance();
    if (v is bool) {
      await sp.setBool(k, v);
    } else if (v is int) {
      await sp.setInt(k, v);
    } else {
      await sp.setString(k, v.toString());
    }
  }

  void setDark(bool v) { darkMode = v; _save('dark', v); notifyListeners(); }
  void setLang(String v) { lang = v; _save('lang', v); notifyListeners(); }
  void setShowPrayer(bool v) { showPrayer = v; _save('showPrayer', v); notifyListeners(); }
  void setShowLessons(bool v) { showLessons = v; _save('showLessons', v); notifyListeners(); }
  void setShowWorkout(bool v) { showWorkout = v; _save('showWorkout', v); notifyListeners(); }
  void setShowFasting(bool v) { showFasting = v; _save('showFasting', v); notifyListeners(); }
  void setShowDailyTasks(bool v) { showDailyTasks = v; _save('showDailyTasks', v); notifyListeners(); }
  void setShowExpenses(bool v) { showExpenses = v; _save('showExpenses', v); notifyListeners(); }
  void setSectionsLabel(String v) { sectionsTabLabel = v; _save('sectionsLabel', v); notifyListeners(); }
  void setAscending(bool v) { ascendingOrder = v; _save('ascending', v); notifyListeners(); }
  void setNotifEnabled(bool v) { notificationsEnabled = v; _save('notifEnabled', v); notifyListeners(); }
  void setNotifTime(int h, int m) {
    notifyHour = h;
    notifyMinute = m;
    _save('notifH', h);
    _save('notifM', m);
    notifyListeners();
  }

  void setTabViewMode(TabViewMode v) {
    tabViewMode = v;
    _save('tabViewMode', v.name);
    notifyListeners();
  }
}
