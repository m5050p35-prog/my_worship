import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/note_dialog.dart';

class WorkoutBody extends StatefulWidget {
  final List<WorkoutEntry> entries;
  final WorkoutConfig config;
  final SortMode sortMode;
  final void Function(SortMode) onSortChanged;
  final VoidCallback onChanged;
  final void Function(WorkoutConfig) onConfigChanged;
  final VoidCallback onReset;

  const WorkoutBody({
    super.key,
    required this.entries,
    required this.config,
    required this.sortMode,
    required this.onSortChanged,
    required this.onChanged,
    required this.onConfigChanged,
    required this.onReset,
  });

  @override
  State<WorkoutBody> createState() => _WorkoutBodyState();
}

class _WorkoutBodyState extends State<WorkoutBody> {
  @override
  void initState() {
    super.initState();
    _applySort(widget.sortMode);
  }

  bool _isRestAt(int index) {
    final cycle = widget.config.workoutDays + widget.config.restDays;
    if (cycle <= 0) return false;
    return (index % cycle) >= widget.config.workoutDays;
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
          final aDone = a.isDone && !a.isRest;
          final bDone = b.isDone && !b.isRest;
          if (aDone == bDone) {
            return a.entryNumber.compareTo(b.entryNumber);
          }
          return aDone ? 1 : -1;
        });
        break;
      case SortMode.completeFirst:
        widget.entries.sort((a, b) {
          final aDone = a.isDone && !a.isRest;
          final bDone = b.isDone && !b.isRest;
          if (aDone == bDone) {
            return a.entryNumber.compareTo(b.entryNumber);
          }
          return aDone ? -1 : 1;
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
      widget.entries.add(WorkoutEntry(
        entryNumber: n + 1,
        entryDate: today
            .add(Duration(days: n))
            .toIso8601String()
            .substring(0, 10),
        isRest: _isRestAt(n),
      ));
      _applySort(widget.sortMode);
    });
    widget.onChanged();
  }

  Future<void> _deleteDay(WorkoutEntry e) async {
    final ok = await _confirm('حذف اليوم', 'حذف اليوم رقم ${e.entryNumber}؟');
    if (ok != true) return;
    setState(() => widget.entries.remove(e));
    widget.onChanged();
  }

  Future<void> _resetAll() async {
    final ok = await _confirm('إعادة تعيين', 'حذف جميع الأيام والبدء من جديد؟');
    if (ok != true) return;
    widget.onReset();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) return _onboarding();

    final done =
        widget.entries.where((e) => e.isDone && !e.isRest).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
          child: Row(
            children: [
              Text(
                '${widget.config.workoutDays} تمرين / ${widget.config.restDays} راحة',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Text(
                '$done منجز',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                icon: const Icon(Icons.edit),
                tooltip: 'تعديل النمط',
                onPressed: _editPattern,
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

  Widget _onboarding() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center, size: 64, color: Colors.teal),
            const SizedBox(height: 16),
            const Text('اختر نمط التمرين',
                style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _editPattern,
              child: const Text('ابدأ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(WorkoutEntry e) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: e.isRest
              ? Colors.grey[400]
              : (e.isDone ? Colors.teal : Colors.orange[200]),
          child: Icon(
            e.isRest
                ? Icons.bed
                : (e.isDone ? Icons.check : Icons.fitness_center),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          'اليوم ${e.entryNumber} - ${e.isRest ? "راحة" : "تمرين"}',
          style: TextStyle(
            decoration:
                (!e.isRest && e.isDone) ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: e.note.isEmpty ? null : Text(e.note),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!e.isRest)
              Checkbox(
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

  Future<void> _editPattern() async {
    final w =
        TextEditingController(text: widget.config.workoutDays.toString());
    final r =
        TextEditingController(text: widget.config.restDays.toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('نمط التمرين'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: w,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'أيام التمرين',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: r,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'أيام الراحة',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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

    final cfg = WorkoutConfig(
      workoutDays: int.tryParse(w.text) ?? 3,
      restDays: int.tryParse(r.text) ?? 1,
    );
    widget.onConfigChanged(cfg);
    setState(() {});
  }
}
