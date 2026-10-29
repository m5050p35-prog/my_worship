import 'package:flutter/material.dart';
import '../models.dart';

class LessonsBody extends StatefulWidget {
  final List<LessonDay> lessonDays;
  final int initialDay; // -1 = today
  final void Function(int)? onDayChanged;
  final VoidCallback onChanged;

  const LessonsBody({
    super.key,
    required this.lessonDays,
    this.initialDay = -1,
    this.onDayChanged,
    required this.onChanged,
  });

  @override
  State<LessonsBody> createState() => _LessonsBodyState();
}

class _LessonsBodyState extends State<LessonsBody> {
  int _selectedDay = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialDay >= 0 && widget.initialDay <= 6) {
      _selectedDay = widget.initialDay;
    } else {
      _selectedDay = DateTime.now().weekday % 7;
    }
  }

  LessonDay get current => widget.lessonDays[_selectedDay];

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

  // ═══ إضافة درس جديد ═══
  Future<void> _addLesson() async {
    final titleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('درس جديد - ${current.dayName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'عنوان الدرس (مثال: أحياء - الوحدة 1)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
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
      current.lessons.add(Lesson(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: titleCtrl.text.trim(),
        note: noteCtrl.text.trim(),
      ));
    });
    widget.onChanged();
  }

  // ═══ تعديل درس ═══
  Future<void> _editLesson(Lesson l) async {
    final titleCtrl = TextEditingController(text: l.title);
    final noteCtrl = TextEditingController(text: l.note);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل الدرس'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
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
      l.title = titleCtrl.text.trim().isEmpty
          ? l.title
          : titleCtrl.text.trim();
      l.note = noteCtrl.text.trim();
    });
    widget.onChanged();
  }

  // ═══ حذف درس ═══
  Future<void> _deleteLesson(Lesson l) async {
    final ok = await _confirm('حذف الدرس', 'حذف "${l.title}"؟');
    if (ok != true) return;
    setState(() => current.lessons.remove(l));
    widget.onChanged();
  }

  // ═══ مسح كل دروس اليوم ═══
  Future<void> _clearDay() async {
    if (current.lessons.isEmpty) return;
    final ok = await _confirm(
        'إفراغ اليوم', 'حذف جميع دروس "${current.dayName}"؟');
    if (ok != true) return;
    setState(() => current.lessons.clear());
    widget.onChanged();
  }

  // ═══ تبديل إتمام الدرس ═══
  void _toggle(Lesson l) {
    setState(() => l.isDone = !l.isDone);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final weekDone = widget.lessonDays.fold<int>(
        0, (s, d) => s + d.doneCount);
    final weekTotal =
        widget.lessonDays.fold<int>(0, (s, d) => s + d.total);

    return Column(
      children: [
        // ═══ Header: المجموع الأسبوعي ═══
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
          child: Row(
            children: [
              const Icon(Icons.menu_book, size: 18, color: Colors.indigo),
              const SizedBox(width: 6),
              Text(
                'الأسبوع: $weekDone / $weekTotal',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.restart_alt),
                tooltip: 'إفراغ اليوم',
                onPressed: _clearDay,
              ),
            ],
          ),
        ),

        // ═══ شريط أيام الأسبوع ═══
        SizedBox(
          height: 78,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: 7,
            itemBuilder: (_, i) {
              final day = widget.lessonDays[i];
              final isSelected = i == _selectedDay;
              final today = DateTime.now().weekday % 7 == i;
              final primary = Theme.of(context).colorScheme.primary;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDay = i);
                  widget.onDayChanged?.call(i);
                },
                child: Container(
                  width: 62,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary
                        : (today
                            ? primary.withValues(alpha: 0.1)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? primary
                          : (today
                              ? primary.withValues(alpha: 0.5)
                              : Colors.grey.withValues(alpha: 0.3)),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.dayShortName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (day.total > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : (day.isComplete
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.grey.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${day.doneCount}/${day.total}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (day.isComplete
                                      ? Colors.green[700]
                                      : Colors.grey[700]),
                            ),
                          ),
                        )
                      else
                        Text(
                          '—',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // ═══ قائمة دروس اليوم ═══
        Expanded(
          child: current.lessons.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.menu_book,
                            size: 64, color: Colors.indigo),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد دروس في ${current.dayName}.\n'
                          'اضغط "إضافة درس" للبدء.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: current.lessons.length,
                  itemBuilder: (_, i) =>
                      _lessonTile(current.lessons[i], i + 1),
                ),
        ),

        // ═══ Add ═══
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addLesson,
              icon: const Icon(Icons.add),
              label: Text('إضافة درس - ${current.dayName}'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _lessonTile(Lesson l, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: InkWell(
          onTap: () => _toggle(l),
          borderRadius: BorderRadius.circular(20),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: l.isDone ? Colors.green : Colors.grey[300],
            child: Icon(
              l.isDone ? Icons.check : Icons.menu_book,
              color: l.isDone ? Colors.white : Colors.grey[700],
              size: 18,
            ),
          ),
        ),
        title: Text(
          l.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: l.isDone ? TextDecoration.lineThrough : null,
            color: l.isDone ? Colors.grey : null,
          ),
        ),
        subtitle: l.note.isEmpty
            ? null
            : Text(
                l.note,
                style: TextStyle(
                  color: l.isDone ? Colors.grey : null,
                ),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: 'تعديل',
              onPressed: () => _editLesson(l),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Colors.red),
              tooltip: 'حذف',
              onPressed: () => _deleteLesson(l),
            ),
          ],
        ),
      ),
    );
  }
}
