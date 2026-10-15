import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/note_dialog.dart';

class SectionsBody extends StatefulWidget {
  final List<Section> sections;
  final VoidCallback onChanged;
  const SectionsBody({super.key, required this.sections, required this.onChanged});
  @override
  State<SectionsBody> createState() => _S();
}

class _S extends State<SectionsBody> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: widget.sections.isEmpty
        ? const Center(child: Text('لا توجد أقسام. اضغط "قسم جديد" للبدء'))
        : ListView.builder(
            itemCount: widget.sections.length,
            itemBuilder: (c, i) => _sectionCard(widget.sections[i]),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newSection,
        icon: const Icon(Icons.add),
        label: const Text('قسم جديد'),
      ),
    );
  }

  Widget _sectionCard(Section s) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${s.days.where((d) => d.isDone).length}/${s.days.length}'),
        trailing: IconButton(icon: const Icon(Icons.delete_outline),
          onPressed: () { widget.sections.remove(s); widget.onChanged(); setState(() {}); }),
        children: s.days.map((d) => ListTile(
          leading: Checkbox(
            value: d.isDone,
            onChanged: (v) { d.isDone = v ?? false; widget.onChanged(); setState(() {}); },
          ),
          title: Text('اليوم ${d.dayNumber}'),
          subtitle: d.note.isEmpty ? null : Text(d.note),
          trailing: IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () async {
              final r = await showNoteDialog(context, d.note);
              if (r != null) { d.note = r; widget.onChanged(); setState(() {}); }
            },
          ),
        )).toList(),
      ),
    );
  }

  Future<void> _newSection() async {
    final nameCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '30');
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('قسم جديد'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم')),
          TextField(controller: countCtrl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'عدد الأيام')),
          TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'ملاحظة')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (ok != true) return;
    final n = int.tryParse(countCtrl.text) ?? 30;
    final today = DateTime.now();
    final days = List.generate(n, (i) => SectionDay(
      dayNumber: i + 1,
      date: today.add(Duration(days: i)).toIso8601String().substring(0, 10),
    ));
    widget.sections.add(Section(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameCtrl.text.trim().isEmpty ? 'قسم' : nameCtrl.text.trim(),
      note: noteCtrl.text.trim(),
      days: days,
    ));
    widget.onChanged();
    setState(() {});
  }
}
