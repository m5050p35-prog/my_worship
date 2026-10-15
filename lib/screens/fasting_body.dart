import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/note_dialog.dart';

class FastingBody extends StatefulWidget {
  final List<FastingEntry> entries;
  final SortMode sortMode;
  final void Function(SortMode) onSortChanged;
  final VoidCallback onChanged;
  final void Function(int) onSetup;

  const FastingBody({
    super.key,
    required this.entries,
    required this.sortMode,
    required this.onSortChanged,
    required this.onChanged,
    required this.onSetup,
  });

  @override
  State<FastingBody> createState() => _FastingBodyState();
}

class _FastingBodyState extends State<FastingBody> {
  @override
  void initState() {
    super.initState();
    _applySort(widget.sortMode);
  }

  void _applySort(SortMode m) {
    switch (m) {
      case SortMode.ascending:
        widget.entries
            .sort((a, b) => a.entryNumber.compareTo(b.entryNumber));
        break;
      case SortMode.descending:
        widget.entries
            .sort((a, b) => b.entryNumber.compareTo(a.entryNumber));
        break;
      case SortMode.incompleteFirst:
        widget.entries.sort((a, b) {
          if (a.isDone == b.isDone) {
            return a.entryNumber.compareTo(b.entryNumber);
          }
          return a.isDone ? 1 : -1;
        });
        break;
      case SortMode.completeFirst:
        widget.entries.sort((a, b) {
          if (a.isDone == b.isDone) {
            return a.entryNumber.compareTo(b.entryNumber);
          }
          return a.isDone ? -1 : 1;
        });
        break;
    }
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

  Future<void> _addDay() async {
    final today = DateTime.now();
    final n = widget.entries.length;
    setState(() {
      widget.entries.add(FastingEntry(
        entryNumber: n + 1,
        entryDate: today
            .add(Duration(days: n))
            .toIso8601String()
            .substring(0, 10),
      ));
      _applySort(widget.sortMode);
    });
    widget.onChanged();
  }

  Future<void> _deleteDay(FastingEntry e) async {
    final ok = await _confirm('حذف اليوم', 'حذف اليوم رقم ${e.entryNumber}؟');
    if (ok != true) return;
    setState(() => widget.entries.remove(e));
    widget.onChanged();
  }

  Future<void> _resetAll() async {
    final ok = await _confirm('إعادة تعيين', 'حذف جميع أيام الصوم والبدء من جديد؟');
    if (ok != true) return;
    setState(() => widget.entries.clear());
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) return _setup();

    final done = widget.entries.where((e) => e.isDone).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
          child: Row(
            children: [
              Text(
                'الصيام: $done / ${widget.entries.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              PopupMenuButton<SortMode>(
                icon: const Icon(Icons.sort),
                tooltip: 'ترتيب القائمة',
                onSelected: (m) {
                  widget.onSortChanged(m);
                  setState(() => _applySort(m));
                },
                itemBuilder: (_) => SortMode.values
                    .map((m) => PopupMenuItem(
                          value: m,
                          child: Row(
                            children: [
                              Icon(
                                widget.sortMode == m
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
        Expanded(
          child: ListView.builder(
            itemCount: widget.entries.length,
            itemBuilder: (c, i) => _tile(widget.entries[i]),
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

  Widget _setup() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.nights_stay, size: 64, color: Colors.indigo),
            const SizedBox(height: 16),
            const Text('اختر مدة الصوم',
                style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(
                  onPressed: () => widget.onSetup(1),
                  child: const Text('يوم'),
                ),
                FilledButton(
                  onPressed: () => widget.onSetup(7),
                  child: const Text('أسبوع'),
                ),
                FilledButton(
                  onPressed: () => widget.onSetup(30),
                  child: const Text('شهر'),
                ),
                FilledButton(
                  onPressed: () => widget.onSetup(365),
                  child: const Text('سنة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(FastingEntry e) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: e.isDone,
          onChanged: (v) {
            setState(() {
              e.isDone = v ?? false;
              if (widget.sortMode == SortMode.incompleteFirst ||
                  widget.sortMode == SortMode.completeFirst) {
                _applySort(widget.sortMode);
              }
            });
            widget.onChanged();
          },
        ),
        title: Text(
          'اليوم ${e.entryNumber}',
          style: TextStyle(
            decoration: e.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: e.note.isEmpty ? null : Text(e.note),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: 'ملاحظة',
              onPressed: () async {
                final r = await showNoteDialog(context, e.note);
                if (r != null) {
                  setState(() => e.note = r);
                  widget.onChanged();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Colors.red),
              tooltip: 'حذف اليوم',
              onPressed: () => _deleteDay(e),
            ),
          ],
        ),
      ),
    );
  }
}
