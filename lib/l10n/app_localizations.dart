import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext c) =>
      Localizations.of<AppLocalizations>(c, AppLocalizations)!;

  static const supportedLocales = [Locale('ar'), Locale('en')];
  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    _Delegate(),
    DefaultMaterialLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
  ];

  bool get isAr => locale.languageCode == 'ar';

  String t(String key) => (isAr ? _ar : _en)[key] ?? key;

  static const _ar = {
    'app_name': 'الاتزان',
    'login': 'تسجيل الدخول',
    'signup': 'إنشاء حساب',
    'email': 'البريد الإلكتروني',
    'name': 'الاسم',
    'enter': 'دخول',
    'create': 'إنشاء',
    'create_new_account': 'إنشاء حساب جديد',
    'already_have': 'لدي حساب بالفعل',
    'gmail_only': 'يُقبل فقط بريد @gmail.com',
    'prayer': 'صلاتك',
    'sections': 'الأقسام',
    'lessons': 'الدروس',
    'workout': 'التمارين',
    'fasting': 'الصوم',
    'settings': 'الإعدادات',
    'profile': 'الملف الشخصي',
    'dark_mode': 'الوضع الليلي',
    'language': 'اللغة',
    'notifications': 'الإشعارات',
    'sync_now': 'مزامنة الآن',
    'sync_ok': 'تمت المزامنة',
    'sync_fail': 'فشلت المزامنة',
    'sync_offline': 'غير متصل',
    'fajr': 'فجر',
    'dhuhr': 'ظهر',
    'asr': 'عصر',
    'maghrib': 'مغرب',
    'isha': 'عشاء',
    'complete_day': 'اكتمل اليوم',
    'add_day': 'إضافة يوم',
    'new_section': 'قسم جديد',
    'section_name': 'اسم القسم',
    'days_count': 'عدد الأيام',
    'note': 'ملاحظة',
    'save': 'حفظ',
    'cancel': 'إلغاء',
    'logout': 'خروج',
    'duration': 'المدة',
    'one_day': 'يوم واحد',
    'week': 'أسبوع',
    'month': 'شهر',
    'year': 'سنة',
    'custom': 'مخصص',
    'reset': 'إعادة تعيين',
    'edit_pattern': 'تعديل النمط',
    'start': 'ابدأ',
    'select_duration': 'اختر المدة',
  };

  static const _en = {
    'app_name': 'Al-Etizan',
    'login': 'Login',
    'signup': 'Sign Up',
    'email': 'Email',
    'name': 'Name',
    'enter': 'Enter',
    'create': 'Create',
    'create_new_account': 'Create a new account',
    'already_have': 'I already have an account',
    'gmail_only': 'Only @gmail.com is accepted',
    'prayer': 'Prayer',
    'sections': 'Sections',
    'lessons': 'Lessons',
    'workout': 'Workout',
    'fasting': 'Fasting',
    'settings': 'Settings',
    'profile': 'Profile',
    'dark_mode': 'Dark Mode',
    'language': 'Language',
    'notifications': 'Notifications',
    'sync_now': 'Sync now',
    'sync_ok': 'Synced',
    'sync_fail': 'Sync failed',
    'sync_offline': 'Offline',
    'fajr': 'Fajr',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
    'complete_day': 'Complete day',
    'add_day': 'Add day',
    'new_section': 'New section',
    'section_name': 'Section name',
    'days_count': 'Days count',
    'note': 'Note',
    'save': 'Save',
    'cancel': 'Cancel',
    'logout': 'Logout',
    'duration': 'Duration',
    'one_day': 'One day',
    'week': 'Week',
    'month': 'Month',
    'year': 'Year',
    'custom': 'Custom',
    'reset': 'Reset',
    'edit_pattern': 'Edit pattern',
    'start': 'Start',
    'select_duration': 'Select duration',
  };
}

class _Delegate extends LocalizationsDelegate<AppLocalizations> {
  const _Delegate();
  @override
  bool isSupported(Locale l) => ['ar', 'en'].contains(l.languageCode);
  @override
  Future<AppLocalizations> load(Locale l) async => AppLocalizations(l);
  @override
  bool shouldReload(_) => false;
}
