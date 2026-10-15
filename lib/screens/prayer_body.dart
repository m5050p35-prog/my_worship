import 'dart:async';
import 'package:flutter/material.dart';
import '../models.dart';

class PrayerBody extends StatefulWidget {
  final List<PrayerDay> days;
  final VoidCallback onChanged;
  final VoidCallback onAddDay;

  const PrayerBody({
    super.key,
    required this.days,
    required this.onChanged,
    required this.onAddDay,
  });

  @override
  State<PrayerBody> createState() => _PrayerBodyState();
}

class _PrayerBodyState extends State<PrayerBody> {
  Timer? _sortTimer;

  @override
  void dispose() {
    _sortTimer?.cancel();
    super.dispose();
  }

  /// إعادة ترتيب: غير المكتمل أولاً، ثم المكتمل
  void _scheduleResort() {
    _sortTimer?.cancel();
    _sortTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        final incomplete = widget.days.where((d) => !d.isComplete).toList();
        final complete = widget.days.where((d) => d.isComplete).toList();
        widget.days
          ..clear()
          ..addAll(incomplete)
          ..addAll(complete);
      });
      widget.onChanged();
    });
  }

  Future<void> _deleteDay(PrayerDay d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف اليوم'),
        content: Text('هل تريد حذف اليوم رقم ${d.dayNumber}؟'),
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
    setState(() => widget.days.remove(d));
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                  const Icon(Icons.check_circle,
                      color: Colors.teal, size: 18),
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
                        onTap: () {
                          setState(() {
                            switch (i) {
                              case 0: d.fajr = !d.fajr; break;
                              case 1: d.dhuhr = !d.dhuhr; break;
                              case 2: d.asr = !d.asr; break;
                              case 3: d.maghrib = !d.maghrib; break;
                              case 4: d.isha = !d.isha; break;
                            }
                          });
                          widget.onChanged();
                          if (d.isComplete) _scheduleResort();
                        },
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
              onPressed: () {
                setState(() {
                  final make = !d.isComplete;
                  d.fajr = d.dhuhr = d.asr = d.maghrib = d.isha = make;
                });
                widget.onChanged();
                if (d.isComplete) _scheduleResort();
              },
              icon: Icon(d.isComplete ? Icons.refresh : Icons.done_all),
              label:
                  Text(d.isComplete ? 'إعادة تعيين' : 'اكتمل اليوم'),
            ),
          ],
        ),
      ),
    );
  }
}
