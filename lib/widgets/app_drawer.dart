import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../profile_screen.dart';
import '../screens/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  final UserData user;
  final VoidCallback onLogout;

  const AppDrawer({super.key, required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user.name.isEmpty ? 'مستخدم' : user.name),
            accountEmail: Text(user.identifier),
            currentAccountPicture: CircleAvatar(
              child: Text(
                user.name.isEmpty ? '؟' : user.name[0],
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(t.t('profile')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProfileScreen(user: user, onLogout: onLogout),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(t.t('settings')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(user: user),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(t.t('logout'),
                style: const TextStyle(color: Colors.red)),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}
