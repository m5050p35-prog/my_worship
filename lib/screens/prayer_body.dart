import 'package:flutter/material.dart';
import '../models.dart';

class PrayerBody extends StatefulWidget {
  final List<PrayerDay> days;
  final VoidCallback onChanged;
  final VoidCallback onAddDay;
  const PrayerBody({super.key, required this.days, required this.onChanged, required this.onAddDay});
  @override
  State<PrayerBody> createState() => _S();
}

class _S extends State<PrayerBody> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: widget.days.isEmpty
          ? const Center(child: Text('لا توجد أيام. اضغط "إضافة يوم" للبدء'))
          : ListView.builder(
              itemCount: widget.days.length,
              itemBuilder: (c, i) => _card(context, widget.days[i], i + 1),
            ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton.icon(
          onPressed: widget.onAddDay,
          icon: const Icon(Icons.add),
          label: const Text('إضافة يوم'),
        ),
      ),
    ]);
  }

  Widget _card(BuildContext c, PrayerDay d, int num) {
    const names = ['فجر', 'ظهر', 'عصر', 'مغرب', 'عشاء'];
    final vals = [d.fajr, d.dhuhr, d.asr, d.maghrib, d.isha];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            Text('اليوم $num', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            Text('${d.completed}/5', style: TextStyle(color: Colors.grey[600])),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 8, children: [
            for (int i = 0; i < 5; i++)
              Column(children: [
                InkWell(
                  onTap: () {
                    switch (i) {
                      case 0: d.fajr = !d.fajr; break;
                      case 1: d.dhuhr = !d.dhuhr; break;
                      case 2: d.asr = !d.asr; break;
                      case 3: d.maghrib = !d.maghrib; break;
                      case 4: d.isha = !d.isha; break;
                    }
                    widget.onChanged();
                    (context as Element).markNeedsBuild();
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: vals[i] ? Colors.teal : Colors.grey[300],
                    child: Icon(vals[i] ? Icons.check : Icons.circle_outlined,
                      color: vals[i] ? Colors.white : Colors.grey[700]),
                  ),
                ),
                const SizedBox(height: 4),
                Text(names[i], style: const TextStyle(fontSize: 12)),
              ]),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: d.completed / 5),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              final make = !d.isComplete;
              d.fajr = d.dhuhr = d.asr = d.maghrib = d.isha = make;
              widget.onChanged();
              (context as Element).markNeedsBuild();
            },
            icon: Icon(d.isComplete ? Icons.refresh : Icons.done_all),
            label: Text(d.isComplete ? 'إعادة تعيين' : 'اكتمل اليوم'),
          ),
        ]),
      ),
    );
  }
}
