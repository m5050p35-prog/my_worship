import 'package:flutter/material.dart';
import '../models.dart';

class DailyTasksBody extends StatefulWidget {
  final UserData user;
  final VoidCallback onChanged;

  const DailyTasksBody({
    super.key,
    required this.user,
    required this.onChanged,
  });

  @override
  State<DailyTasksBody> createState() => _DailyTasksBodyState();
}

class _DailyTasksBodyState extends State<DailyTasksBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncDays());
  }

  // ═══ إنشاء الأيام من تاريخ البداية حتى اليوم ═══
  void _syncDays() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (widget.user.dailyTasksStartDate.isEmpty) {
      widget.user.dailyTasksStartDate =
          todayDate.toIso8601String().substring(0, 10);
    }

    final start = DateTime.parse(widget.user.dailyTasksStartDate);
    final startDate = DateTime(start.year, start.month, start.day);
    final diff = todayDate.difference(startDate).inDays;

    if (diff < 0) return;

    final existingIndices =
        widget.user.dailyTaskDays.map((d) => d.dayIndex).toSet();

    var added = false;
    for (var i = 0; i <= diff; i++) {
      final dayIndex = i + 1;
      if (existingIndices.contains(dayIndex)) continue;
      final date = startDate.add(Duration(days: i));
      widget.user.dailyTaskDays.add(DailyTaskDay(
        dayIndex: dayIndex,
        date: date.toIso8601String().substring(0, 10),
      ));
      added = true;
    }

    // ترتيب تنازلي: الأحدث فوق
    widget.user.dailyTaskDays
        .sort((a, b) => b.dayIndex.compareTo(a.dayIndex));

    if (added) widget.onChanged();
    if (mounted) setState(() {});
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

  // ═══ إضافة مهمة واحدة ═══
  Future<void> _addTask(DailyTaskDay day) async {
    final titleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('مهمة جديدة - اليوم ${day.dayIndex}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'عنوان المهمة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة (اختياري)',
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
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (titleCtrl.text.trim().isEmpty) return;

    setState(() {
      day.tasks.add(DailyTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: titleCtrl.text.trim(),
        note: noteCtrl.text.trim(),
      ));
    });
    widget.onChanged();
  }

  // ═══ إضافة مهام متعددة ═══
  Future<void> _addMultipleTasks(DailyTaskDay day) async {
    final items = <String>[];

    Future<String?> promptLine() async {
      final ctrl = TextEditingController();
      return showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('عنوان المهمة'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'اكتب المهمة',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text('أضف'),
            ),
          ],
        ),
      );
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('مهام جديدة - اليوم ${day.dayIndex}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'لم تُضف أي مهمة بعد.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (_, i) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.check_circle_outline,
                            color: Colors.teal),
                        title: Text(items[i]),
                        trailing: IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.red, size: 20),
                          onPressed: () {
                            setS(() => items.removeAt(i));
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                final txt = await promptLine();
                if (txt != null && txt.trim().isNotEmpty) {
                  setS(() => items.add(txt.trim()));
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('أضف مهمة'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('حفظ (${items.length})'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || items.isEmpty) return;

    final baseTime = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      for (var i = 0; i < items.length; i++) {
        day.tasks.add(DailyTask(
          id: '${baseTime}_$i',
          title: items[i],
        ));
      }
    });
    widget.onChanged();
  }

  // ═══ نسخ مهام اليوم السابق ═══
  Future<void> _copyPreviousDay(DailyTaskDay day) async {
    if (day.dayIndex <= 1) {
      _snack('اليوم الأول — لا يوجد يوم سابق');
      return;
    }
    final prev = widget.user.dailyTaskDays
        .where((d) => d.dayIndex == day.dayIndex - 1)
        .toList();
    if (prev.isEmpty) {
      _snack('اليوم السابق غير موجود');
      return;
    }
    final prevDay = prev.first;
    if (prevDay.tasks.isEmpty) {
      _snack('لا توجد مهام في اليوم السابق');
      return;
    }

    final selected = <String>{};
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('مهام اليوم ${prevDay.dayIndex}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: prevDay.tasks.length,
              itemBuilder: (_, i) {
                final t = prevDay.tasks[i];
                return CheckboxListTile(
                  value: selected.contains(t.id),
                  onChanged: (v) {
                    setS(() {
                      if (v == true) {
                        selected.add(t.id);
                      } else {
                        selected.remove(t.id);
                      }
                    });
                  },
                  title: Text(t.title),
                  subtitle: t.isDone
                      ? const Text('✓ مكتملة',
                          style: TextStyle(color: Colors.green))
                      : (t.isFailed
                          ? const Text('✗ فاشلة',
                              style: TextStyle(color: Colors.red))
                          : null),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('نسخ المحدد'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || selected.isEmpty) return;

    final baseTime = DateTime.now().millisecondsSinceEpoch;
    final toCopy =
        prevDay.tasks.where((t) => selected.contains(t.id)).toList();
    setState(() {
      for (var i = 0; i < toCopy.length; i++) {
        day.tasks.add(DailyTask(
          id: '${baseTime}_$i',
          title: toCopy[i].title,
          note: toCopy[i].note,
        ));
      }
    });
    widget.onChanged();
  }

  // ═══ تعديل مهمة ═══
  Future<void> _editTask(DailyTask t) async {
    final titleCtrl = TextEditingController(text: t.title);
    final noteCtrl = TextEditingController(text: t.note);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل المهمة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
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
      t.title =
          titleCtrl.text.trim().isEmpty ? t.title : titleCtrl.text.trim();
      t.note = noteCtrl.text.trim();
    });
    widget.onChanged();
  }

  Future<void> _deleteTask(DailyTaskDay day, DailyTask t) async {
    final ok = await _confirm('حذف المهمة', 'حذف "${t.title}"؟');
    if (ok != true) return;
    setState(() => day.tasks.remove(t));
    widget.onChanged();
  }

  void _setStatus(DailyTask t, int status) {
    setState(() {
      t.status = t.status == status ? 0 : status;
    });
    widget.onChanged();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.user.dailyTaskDays;
    final totalDone = days.fold<int>(0, (s, d) => s + d.doneCount);
    final totalTasks = days.fold<int>(0, (s, d) => s + d.total);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
          child: Row(
            children: [
              const Icon(Icons.task_alt, size: 18, color: Colors.teal),
              const SizedBox(width: 6),
              Text(
                'المجموع: $totalDone / $totalTasks',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Text(
                '${days.length} يوم',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: days.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'جارٍ تهيئة الأيام...',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: days.length,
                  itemBuilder: (_, i) => _dayCard(days[i]),
                ),
        ),
      ],
    );
  }

  Widget _dayCard(DailyTaskDay day) {
    final isToday = day.dayIndex == widget.user.dailyTaskDays.length;
    final done = day.doneCount;
    final failed = day.failedCount;
    final pending = day.pendingCount;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        leading: null,
        title: Row(
          children: [
            if (isToday)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'اليوم',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اليوم ${day.dayIndex} • ${day.weekdayName}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    day.date,
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              _badge('✓', done, Colors.green),
              const SizedBox(width: 6),
              _badge('✗', failed, Colors.red),
              const SizedBox(width: 6),
              _badge('⏳', pending, Colors.orange),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'خيارات',
          onSelected: (v) {
            if (v == 'add') {
              _addTask(day);
            } else if (v == 'multi') {
              _addMultipleTasks(day);
            } else if (v == 'copy') {
              _copyPreviousDay(day);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'add',
              child: ListTile(
                leading: Icon(Icons.add_task),
                title: Text('إضافة مهمة'),
              ),
            ),
            PopupMenuItem(
              value: 'multi',
              child: ListTile(
                leading: Icon(Icons.playlist_add),
                title: Text('إضافة مهام متعددة'),
              ),
            ),
            PopupMenuItem(
              value: 'copy',
              child: ListTile(
                leading: Icon(Icons.copy_all),
                title: Text('مهام اليوم السابق'),
              ),
            ),
          ],
        ),
        children: [
          if (day.tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('لا توجد مهام بعد.',
                  style: TextStyle(color: Colors.grey)),
            )
          else
            ...day.tasks.map((t) => _taskTile(day, t)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addTask(day),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('إضافة مهمة'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addMultipleTasks(day),
                    icon: const Icon(Icons.playlist_add, size: 18),
                    label: const Text('متعددة'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _taskTile(DailyTaskDay day, DailyTask t) {
    Color dotColor;
    IconData dotIcon;
    if (t.isDone) {
      dotColor = Colors.green;
      dotIcon = Icons.check;
    } else if (t.isFailed) {
      dotColor = Colors.red;
      dotIcon = Icons.close;
    } else {
      dotColor = Colors.orange;
      dotIcon = Icons.schedule;
    }

    return ListTile(
      leading: InkWell(
        onTap: () => _editTask(t),
        borderRadius: BorderRadius.circular(20),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: dotColor.withValues(alpha: 0.15),
          child: Icon(dotIcon, color: dotColor, size: 18),
        ),
      ),
      title: Text(
        t.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          decoration: t.isDone ? TextDecoration.lineThrough : null,
          color: t.isDone ? Colors.grey : null,
        ),
      ),
      subtitle: t.note.isEmpty ? null : Text(t.note),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'تم',
            icon: Icon(
              Icons.check_circle,
              color: t.isDone ? Colors.green : Colors.grey[400],
            ),
            onPressed: () => _setStatus(t, 1),
          ),
          IconButton(
            tooltip: 'فشل',
            icon: Icon(
              Icons.cancel,
              color: t.isFailed ? Colors.red : Colors.grey[400],
            ),
            onPressed: () => _setStatus(t, 2),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: Colors.grey),
            onPressed: () => _deleteTask(day, t),
          ),
        ],
      ),
    );
  }
}
