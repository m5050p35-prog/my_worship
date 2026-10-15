import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'models.dart';
import 'providers/settings_provider.dart';
import 'providers/sync_provider.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';
import 'services/sync_service.dart';
import 'storage.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (details) => Material(
        color: Colors.red[50],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'خطأ: ${details.exceptionAsString()}',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
  try {
    await SupabaseService.init();
  } catch (e) {
    debugPrint('SB init: $e');
  }
  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('Notif init: $e');
  }
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsProvider();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ProxyProvider<SyncProvider, SyncService>(
          update: (_, sync, __) => SyncService(sync),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (_, s, __) => MaterialApp(
          title: 'MyWorship',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: s.darkMode ? ThemeMode.dark : ThemeMode.light,
          locale: Locale(s.lang),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: const SplashGate(),
        ),
      ),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  UserData? _user;

  Future<String?> _onSubmit(String email) async {
    try {
      final u = await SupabaseService.loadUser(email);
      if (u != null) {
        _setUser(u);
        return null;
      }
    } catch (e) {
      debugPrint('cloud load failed: $e');
      final local = await Storage.loadUser(email);
      if (local != null) {
        _setUser(local);
        return null;
      }
      return 'تعذّر الاتصال: $e';
    }

    final local = await Storage.loadUser(email);
    if (local != null) {
      _setUser(local);
      return null;
    }

    try {
      final newUser = UserData(
        identifier: email,
        name: email.split('@').first,
      );
      final (ok, err, saved) = await SupabaseService.saveUserWithResult(newUser);
      if (!ok) {
        return 'فشل الإنشاء: $err';
      }
      await Storage.saveUser(saved!);
      _setUser(saved);
      return null;
    } catch (e) {
      return 'فشل الإنشاء: $e';
    }
  }

  void _setUser(UserData u) {
    setState(() => _user = u);
    Storage.saveUser(u);
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return LoginScreen(onSubmit: _onSubmit);
    }
    return MainShell(
      user: _user!,
      onLogout: () => setState(() => _user = null),
    );
  }
}
