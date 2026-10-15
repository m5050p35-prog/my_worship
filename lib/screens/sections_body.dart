import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/note_dialog.dart';

class SectionsBody extends StatefulWidget {
  final List<Section> sections;
  final VoidCallback onChanged;

  const SectionsBody({
    super.key,
    required this.sections,
    required this.onChanged,
  });

  @override
  State<SectionsBody> createState() => _SectionsBodyState();
}

class _SectionsBodyState extends State<SectionsBody> {
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

  Future<void> _resetAll() async {
    if (widget.sections.isEmpty) return;
    final ok = await _confirm('حذف كل الأقسام', 'هل تريد حذف جميع الأقسام بكل أيامها؟');
    if (ok != true) return;
    setState(() => widget.sections.clear());
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            child: Row(
              children: [
                Text(
                  'الأقسام: ${widget.sections.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.restart_alt),
                  tooltip: 'حذف كل الأقسام',
                  onPressed: _resetAll,
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.sections.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'لا توجد أقسام بعد.\nاضغط "قسم جديد" للبدء.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.sections.length,
                    itemBuilder: (c, i) =>
                        _sectionCard(widget.sections[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newSection,
        icon: const Icon(Icons.add),
        label: const Text('قسم جديد'),
      ),
    );
  }

  Widget _sectionCard(Section s) {
    final done = s.days.where((d) => d.isDone).length;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        title: Text(
          s.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$done / ${s.days.length}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ═══ قائمة الترتيب ═══
            PopupMenuButton<SortMode>(
              icon: const Icon(Icons.sort),
              tooltip: 'ترتيب الأيام',
              onSelected: (m) {
                setState(() {
                  s.sortMode = m;
                  s.applySort();
                });
                widget.onChanged();
              },
              itemBuilder: (_) => SortMode.values
                  .map((m) => PopupMenuItem(
                        value: m,
                        child: Row(
                          children: [
                            Icon(
                              s.sortMode == m
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 18,
                              color: Colors.teal,
                            ),
                            const SizedBox(width: 8),
                            Text(m.label),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'حذف القسم',
              onPressed: () => _deleteSection(s),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          ...s.days.map((d) => _dayTile(s, d)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _addDay(s),
                icon: const Icon(Icons.add),
                label: const Text('إضافة يوم'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayTile(Section s, SectionDay d) {
    return ListTile(
      leading: Checkbox(
        value: d.isDone,
        onChanged: (v) {
          setState(() {
            d.isDone = v ?? false;
            s.applySort();
          });
          widget.onChanged();
        },
      ),
      title: Text(
        'اليوم ${d.dayNumber}',
        style: TextStyle(
          decoration: d.isDone ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: d.note.isEmpty ? null : Text(d.note),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () async {
              final r = await showNoteDialog(context, d.note);
              if (r != null) {
                setState(() => d.note = r);
                widget.onChanged();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.red),
            onPressed: () => _deleteDay(s, d),
          ),
        ],
      ),
    );
  }

  void _addDay(Section s) {
    final today = DateTime.now();
    final next = s.days.isEmpty
        ? 1
        : s.days.map((e) => e.dayNumber).reduce((a, b) => a > b ? a : b) + 1;
    setState(() {
      s.days.add(SectionDay(
        dayNumber: next,
        date: today.toIso8601String().substring(0, 10),
      ));
      s.applySort();
    });
    widget.onChanged();
  }

  Future<void> _deleteDay(Section s, SectionDay d) async {
    final ok = await _confirm('حذف اليوم', 'هل تريد حذف اليوم رقم ${d.dayNumber}؟');
    if (ok != true) return;
    setState(() => s.days.remove(d));
    widget.onChanged();
  }

  Future<void> _deleteSection(Section s) async {
    final ok = await _confirm('حذف القسم', 'هل تريد حذف "${s.name}" بكل أيامه؟');
    if (ok != true) return;
    setState(() => widget.sections.remove(s));
    widget.onChanged();
  }

  Future<void> _newSection() async {
    final nameCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '30');
    final noteCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('قسم جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
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

    final n = int.tryParse(countCtrl.text) ?? 30;
    final today = DateTime.now();
    final days = List.generate(
      n,
      (i) => SectionDay(
        dayNumber: i + 1,
        date:
            today.add(Duration(days: i)).toIso8601String().substring(0, 10),
      ),
    );

    setState(() {
      widget.sections.add(Section(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameCtrl.text.trim().isEmpty ? 'قسم' : nameCtrl.text.trim(),
        note: noteCtrl.text.trim(),
        days: days,
      ));
    });
    widget.onChanged();
  }
}
