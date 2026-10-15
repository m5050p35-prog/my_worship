import 'dart:async';
import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/note_dialog.dart';

class FastingBody extends StatefulWidget {
  final List<FastingEntry> entries;
  final VoidCallback onChanged;
  final void Function(int) onSetup;

  const FastingBody({
    super.key,
    required this.entries,
    required this.onChanged,
    required this.onSetup,
  });

  @override
  State<FastingBody> createState() => _FastingBodyState();
}

class _FastingBodyState extends State<FastingBody> {
  Timer? _sortTimer;

  @override
  void dispose() {
    _sortTimer?.cancel();
    super.dispose();
  }

  void _scheduleResort() {
    _sortTimer?.cancel();
    _sortTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        final incomplete =
            widget.entries.where((e) => !e.isDone).toList();
        final complete =
            widget.entries.where((e) => e.isDone).toList();
        widget.entries
          ..clear()
          ..addAll(incomplete)
          ..addAll(complete);
      });
      widget.onChanged();
    });
  }

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
    });
    widget.onChanged();
  }

  Future<void> _deleteDay(FastingEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف اليوم'),
        content: Text('هل تريد حذف اليوم رقم ${e.entryNumber}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => widget.entries.remove(e));
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) return _setup();

    final done = widget.entries.where((e) => e.isDone).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                'الصيام: $done / ${widget.entries.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
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
            const Text(
              'اختر مدة الصوم',
              style: TextStyle(fontSize: 20),
            ),
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
            setState(() => e.isDone = v ?? false);
            widget.onChanged();
            if (e.isDone) _scheduleResort();
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
