import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'models.dart';
import 'providers/settings_provider.dart';

class ProfileScreen extends StatelessWidget {
  final UserData user;
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(t.t('profile'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        CircleAvatar(radius: 40, child: Text(user.name.isEmpty ? '؟' : user.name[0],
          style: const TextStyle(fontSize: 32))),
        const SizedBox(height: 12),
        Center(child: Text(user.name.isEmpty ? 'مستخدم' : user.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        Center(child: Text(user.identifier, style: TextStyle(color: Colors.grey[600]))),
        const SizedBox(height: 24),
        ListTile(
          leading: Icon(s.darkMode ? Icons.dark_mode : Icons.light_mode),
          title: Text(t.t('dark_mode')),
          trailing: Switch(value: s.darkMode, onChanged: s.setDark),
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
            onChanged: (v) { if (v != null) s.setLang(v); },
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: Text(t.t('logout'), style: const TextStyle(color: Colors.red)),
          onTap: onLogout,
        ),
      ]),
    );
  }
}
