import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../profile_screen.dart';
import '../screens/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  final UserData user;
  final VoidCallback onLogout;
  final VoidCallback onChanged;

  const AppDrawer({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    ImageProvider? avatar;
    if (user.avatarBase64.isNotEmpty) {
      try {
        avatar = MemoryImage(base64Decode(user.avatarBase64));
      } catch (_) {}
    }

    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user.name.isEmpty ? 'مستخدم' : user.name),
            accountEmail: Text(user.identifier),
            currentAccountPicture: CircleAvatar(
              backgroundImage: avatar,
              child: avatar == null
                  ? Text(
                      user.name.isEmpty ? '؟' : user.name[0],
                      style: const TextStyle(fontSize: 24),
                    )
                  : null,
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
                  builder: (_) => ProfileScreen(
                    user: user,
                    onLogout: onLogout,
                    onChanged: onChanged,
                  ),
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
