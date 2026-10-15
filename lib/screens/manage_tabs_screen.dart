import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../services/sync_service.dart';

class ManageTabsScreen extends StatefulWidget {
  final UserData user;
  const ManageTabsScreen({super.key, required this.user});

  @override
  State<ManageTabsScreen> createState() => _ManageTabsScreenState();
}

class _ManageTabsScreenState extends State<ManageTabsScreen> {
  UserData get user => widget.user;

  void _changed() {
    setState(() {});
    context.read<SyncService>().schedulePush(user);
  }

  Future<bool?> _confirm(String title, String body) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التبويبات المخصصة')),
      body: user.customTabs.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'لا توجد تبويبات مخصصة بعد.\nاضغط "+" لإضافة واحد.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              itemCount: user.customTabs.length,
              itemBuilder: (c, i) => _card(user.customTabs[i]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newTab,
        icon: const Icon(Icons.add),
        label: const Text('تبويب جديد'),
      ),
    );
  }

  Widget _card(CustomTab t) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: t.enabled ? Colors.teal : Colors.grey,
          child: const Icon(Icons.bookmark, color: Colors.white, size: 20),
        ),
        title: Text(
          t.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${t.type.isNotEmpty ? "${t.type} • " : ""}'
          '${t.doneCount}/${t.days.length} يوم',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: t.enabled,
              onChanged: (v) {
                setState(() => t.enabled = v);
                _changed();
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editTab(t),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteTab(t),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _newTab() async {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '30');
    final noteCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تبويب جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'الاسم (مطلوب)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: typeCtrl,
                decoration: const InputDecoration(
                  labelText: 'النوع (ورد، صدقة، حفظ...)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: countCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'عدد الأيام',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة عامة',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (nameCtrl.text.trim().isEmpty) return;

    final n = int.tryParse(countCtrl.text) ?? 30;
    final today = DateTime.now();
    final days = List.generate(
      n,
      (i) => CustomTabDay(
        dayNumber: i + 1,
        date:
            today.add(Duration(days: i)).toIso8601String().substring(0, 10),
      ),
    );

    setState(() {
      user.customTabs.add(CustomTab(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameCtrl.text.trim(),
        type: typeCtrl.text.trim(),
        note: noteCtrl.text.trim(),
        days: days,
      ));
    });
    _changed();
  }

  Future<void> _editTab(CustomTab t) async {
    final nameCtrl = TextEditingController(text: t.name);
    final typeCtrl = TextEditingController(text: t.type);
    final noteCtrl = TextEditingController(text: t.note);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل التبويب'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: typeCtrl,
                decoration: const InputDecoration(
                  labelText: 'النوع',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      t.name = nameCtrl.text.trim().isEmpty ? t.name : nameCtrl.text.trim();
      t.type = typeCtrl.text.trim();
      t.note = noteCtrl.text.trim();
    });
    _changed();
  }

  Future<void> _deleteTab(CustomTab t) async {
    final ok = await _confirm('حذف التبويب', 'حذف "${t.name}" بكل أيامه؟');
    if (ok != true) return;
    setState(() => user.customTabs.remove(t));
    _changed();
  }
}
