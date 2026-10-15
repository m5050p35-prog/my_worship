import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/note_dialog.dart';

class CustomTabBody extends StatefulWidget {
  final CustomTab tab;
  final VoidCallback onChanged;

  const CustomTabBody({
    super.key,
    required this.tab,
    required this.onChanged,
  });

  @override
  State<CustomTabBody> createState() => _CustomTabBodyState();
}

class _CustomTabBodyState extends State<CustomTabBody> {
  CustomTab get tab => widget.tab;

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

  void _addDay() {
    final today = DateTime.now();
    final next = tab.days.isEmpty
        ? 1
        : tab.days.map((e) => e.dayNumber).reduce((a, b) => a > b ? a : b) + 1;
    setState(() {
      tab.days.add(CustomTabDay(
        dayNumber: next,
        date: today.toIso8601String().substring(0, 10),
      ));
      tab.applySort();
    });
    widget.onChanged();
  }

  Future<void> _deleteDay(CustomTabDay d) async {
    final ok = await _confirm('حذف اليوم', 'حذف اليوم رقم ${d.dayNumber}؟');
    if (ok != true) return;
    setState(() => tab.days.remove(d));
    widget.onChanged();
  }

  Future<void> _resetAll() async {
    if (tab.days.isEmpty) return;
    final ok = await _confirm('إعادة تعيين', 'حذف جميع الأيام في "${tab.name}"؟');
    if (ok != true) return;
    setState(() => tab.days.clear());
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final done = tab.doneCount;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
          child: Row(
            children: [
              if (tab.type.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tab.type,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                '$done / ${tab.days.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              PopupMenuButton<SortMode>(
                icon: const Icon(Icons.sort),
                onSelected: (m) {
                  setState(() {
                    tab.sortMode = m;
                    tab.applySort();
                  });
                  widget.onChanged();
                },
                itemBuilder: (_) => SortMode.values
                    .map((m) => PopupMenuItem(
                          value: m,
                          child: Row(
                            children: [
                              Icon(
                                tab.sortMode == m
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
                icon: const Icon(Icons.restart_alt),
                tooltip: 'إعادة تعيين',
                onPressed: _resetAll,
              ),
            ],
          ),
        ),
        if (tab.note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tab.note,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        Expanded(
          child: tab.days.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'لا توجد أيام بعد.\nاضغط "إضافة يوم" للبدء.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: tab.days.length,
                  itemBuilder: (c, i) => _tile(tab.days[i]),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addDay,
              icon: const Icon(Icons.add),
              label: const Text('إضافة يوم'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tile(CustomTabDay d) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: d.isDone,
          onChanged: (v) {
            setState(() {
              d.isDone = v ?? false;
              tab.applySort();
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
              onPressed: () => _deleteDay(d),
            ),
          ],
        ),
      ),
    );
  }
}
