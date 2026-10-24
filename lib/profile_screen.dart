import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'models.dart';
import 'providers/settings_provider.dart';

class ProfileScreen extends StatefulWidget {
  final UserData user;
  final VoidCallback onLogout;
  final VoidCallback onChanged;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 300, imageQuality: 70);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() {
      widget.user.avatarBase64 = base64Encode(bytes);
    });
    widget.onChanged();
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: widget.user.name);
    final r = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل الاسم'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (r != null && r.trim().isNotEmpty) {
      setState(() => widget.user.name = r.trim());
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = context.watch<SettingsProvider>();
    ImageProvider? avatar;
    if (widget.user.avatarBase64.isNotEmpty) {
      try {
        avatar = MemoryImage(base64Decode(widget.user.avatarBase64));
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.t('profile'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.teal.withValues(alpha: 0.2),
                  backgroundImage: avatar,
                  child: avatar == null
                      ? Text(
                          widget.user.name.isEmpty
                              ? '؟'
                              : widget.user.name[0],
                          style: const TextStyle(fontSize: 36),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.teal,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt,
                          size: 18, color: Colors.white),
                      onPressed: _pickImage,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.user.name.isEmpty ? 'مستخدم' : widget.user.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: _editName,
                ),
              ],
            ),
          ),
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
              onChanged: (v) {
                if (v != null) s.setLang(v);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(t.t('logout'),
                style: const TextStyle(color: Colors.red)),
            onTap: widget.onLogout,
          ),
        ],
      ),
    );
  }
}
