import 'package:flutter/material.dart';
import '../models.dart';

class PrayerBody extends StatefulWidget {
  final List<PrayerDay> days;
  final SortMode sortMode;
  final void Function(SortMode) onSortChanged;
  final VoidCallback onChanged;
  final VoidCallback onAddDay;

  const PrayerBody({
    super.key,
    required this.days,
    required this.sortMode,
    required this.onSortChanged,
    required this.onChanged,
    required this.onAddDay,
  });

  @override
  State<PrayerBody> createState() => _PrayerBodyState();
}

class _PrayerBodyState extends State<PrayerBody> {
  @override
  void initState() {
    super.initState();
    _applySort(widget.sortMode);
  }

  void _applySort(SortMode m) {
    switch (m) {
      case SortMode.ascending:
        widget.days.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
        break;
      case SortMode.descending:
        widget.days.sort((a, b) => b.dayNumber.compareTo(a.dayNumber));
        break;
      case SortMode.incompleteFirst:
        widget.days.sort((a, b) {
          if (a.isComplete == b.isComplete) {
            return a.dayNumber.compareTo(b.dayNumber);
          }
          return a.isComplete ? 1 : -1;
        });
        break;
      case SortMode.completeFirst:
        widget.days.sort((a, b) {
          if (a.isComplete == b.isComplete) {
            return a.dayNumber.compareTo(b.dayNumber);
          }
          return a.isComplete ? -1 : 1;
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

  Future<void> _deleteDay(PrayerDay d) async {
    final ok = await _confirm('حذف اليوم', 'حذف اليوم رقم ${d.dayNumber}؟');
    if (ok != true) return;
    setState(() => widget.days.remove(d));
    widget.onChanged();
  }

  Future<void> _resetAll() async {
    if (widget.days.isEmpty) return;
    final ok = await _confirm(
        'إعادة تعيين', 'مسح علامات جميع الصلوات؟ (الأيام تبقى محفوظة)');
    if (ok != true) return;
    setState(() {
      for (final d in widget.days) {
        d.fajr = false;
        d.dhuhr = false;
        d.asr = false;
        d.maghrib = false;
        d.isha = false;
      }
      _applySort(widget.sortMode);
    });
    widget.onChanged();
  }

  void _togglePrayer(PrayerDay d, int index) {
    setState(() {
      switch (index) {
        case 0:
          d.fajr = !d.fajr;
          break;
        case 1:
          d.dhuhr = !d.dhuhr;
          break;
        case 2:
          d.asr = !d.asr;
          break;
        case 3:
          d.maghrib = !d.maghrib;
          break;
        case 4:
          d.isha = !d.isha;
          break;
      }
      if (widget.sortMode == SortMode.incompleteFirst ||
          widget.sortMode == SortMode.completeFirst) {
        _applySort(widget.sortMode);
      }
    });
    widget.onChanged();
  }

  void _toggleFullDay(PrayerDay d) {
    setState(() {
      final make = !d.isComplete;
      d.fajr = make;
      d.dhuhr = make;
      d.asr = make;
      d.maghrib = make;
      d.isha = make;
      if (widget.sortMode == SortMode.incompleteFirst ||
          widget.sortMode == SortMode.completeFirst) {
        _applySort(widget.sortMode);
      }
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final complete = widget.days.where((d) => d.isComplete).length;

    return Column(
      children: [
        // ═══ Header مع Sort ═══
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
          child: Row(
            children: [
              Text(
                'مكتمل: $complete / ${widget.days.length}',
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
                tooltip: 'إعادة تعيين كل العلامات',
                onPressed: _resetAll,
              ),
            ],
          ),
        ),
        // ═══ List ═══
        Expanded(
          child: widget.days.isEmpty
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
                  itemCount: widget.days.length,
                  itemBuilder: (c, i) => _card(widget.days[i]),
                ),
        ),
        // ═══ Add ═══
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onAddDay,
              icon: const Icon(Icons.add),
              label: const Text('إضافة يوم'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(PrayerDay d) {
    const names = ['فجر', 'ظهر', 'عصر', 'مغرب', 'عشاء'];
    final vals = [d.fajr, d.dhuhr, d.asr, d.maghrib, d.isha];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'اليوم ${d.dayNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (d.isComplete) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.check_circle, color: Colors.teal, size: 18),
                ],
                const Spacer(),
                Text(
                  '${d.completed}/5',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.red),
                  tooltip: 'حذف اليوم',
                  onPressed: () => _deleteDay(d),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (int i = 0; i < 5; i++)
                  Column(
                    children: [
                      InkWell(
                        onTap: () => _togglePrayer(d, i),
                        borderRadius: BorderRadius.circular(24),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              vals[i] ? Colors.teal : Colors.grey[300],
                          child: Icon(
                            vals[i] ? Icons.check : Icons.circle_outlined,
                            color: vals[i] ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(names[i], style: const TextStyle(fontSize: 12)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: d.completed / 5),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _toggleFullDay(d),
              icon: Icon(d.isComplete ? Icons.refresh : Icons.done_all),
              label: Text(d.isComplete ? 'إعادة تعيين' : 'اكتمل اليوم'),
            ),
          ],
        ),
      ),
    );
  }
}
