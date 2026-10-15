import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/note_dialog.dart';

class FastingBody extends StatefulWidget {
  final List<FastingEntry> entries;
  final VoidCallback onChanged;
  final void Function(int) onSetup;
  const FastingBody({super.key, required this.entries, required this.onChanged, required this.onSetup});
  @override
  State<FastingBody> createState() => _S();
}

class _S extends State<FastingBody> {
  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.nights_stay, size: 64, color: Colors.indigo),
        const SizedBox(height: 16),
        const Text('اختر مدة الصوم', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 16),
        Wrap(spacing: 8, children: [
          FilledButton(onPressed: () => widget.onSetup(1), child: const Text('يوم')),
          FilledButton(onPressed: () => widget.onSetup(7), child: const Text('أسبوع')),
          FilledButton(onPressed: () => widget.onSetup(30), child: const Text('شهر')),
          FilledButton(onPressed: () => widget.onSetup(365), child: const Text('سنة')),
        ]),
      ]));
    }
    return ListView.builder(
      itemCount: widget.entries.length,
      itemBuilder: (c, i) => _tile(widget.entries[i], i + 1),
    );
  }

  Widget _tile(FastingEntry e, int num) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Checkbox(value: e.isDone, onChanged: (v) {
          e.isDone = v ?? false; widget.onChanged(); setState(() {}); }),
        title: Text('اليوم $num'),
        subtitle: e.note.isEmpty ? null : Text(e.note),
        trailing: IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () async {
          final r = await showNoteDialog(context, e.note);
          if (r != null) { e.note = r; widget.onChanged(); setState(() {}); }
        }),
      ),
    );
  }
}
