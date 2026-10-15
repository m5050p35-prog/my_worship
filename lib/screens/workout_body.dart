import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/note_dialog.dart';

class WorkoutBody extends StatefulWidget {
  final List<WorkoutEntry> entries;
  final WorkoutConfig config;
  final VoidCallback onChanged;
  final void Function(WorkoutConfig) onConfigChanged;
  final VoidCallback onReset;
  const WorkoutBody({super.key, required this.entries, required this.config,
    required this.onChanged, required this.onConfigChanged, required this.onReset});
  @override
  State<WorkoutBody> createState() => _S();
}

class _S extends State<WorkoutBody> {
  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) return _onboarding();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          Text('${widget.config.workoutDays} تمرين / ${widget.config.restDays} راحة',
            style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.edit), onPressed: _editPattern),
          IconButton(icon: const Icon(Icons.refresh), onPressed: widget.onReset),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: widget.entries.length,
          itemBuilder: (c, i) => _tile(widget.entries[i], i + 1),
        ),
      ),
    ]);
  }

  Widget _onboarding() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.fitness_center, size: 64, color: Colors.teal),
        const SizedBox(height: 16),
        const Text('اختر نمط التمرين', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 16),
        FilledButton(onPressed: _editPattern, child: const Text('ابدأ')),
      ]),
    ));
  }

  Widget _tile(WorkoutEntry e, int num) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: e.isRest ? Colors.grey[400]
            : (e.isDone ? Colors.teal : Colors.orange[200]),
          child: Icon(e.isRest ? Icons.bed : (e.isDone ? Icons.check : Icons.fitness_center),
            color: Colors.white, size: 20),
        ),
        title: Text('اليوم $num - ${e.isRest ? "راحة" : "تمرين"}'),
        subtitle: e.note.isEmpty ? null : Text(e.note),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (!e.isRest)
            Checkbox(value: e.isDone, onChanged: (v) {
              e.isDone = v ?? false; widget.onChanged(); setState(() {}); }),
          IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () async {
            final r = await showNoteDialog(context, e.note);
            if (r != null) { e.note = r; widget.onChanged(); setState(() {}); }
          }),
        ]),
      ),
    );
  }

  Future<void> _editPattern() async {
    final w = TextEditingController(text: widget.config.workoutDays.toString());
    final r = TextEditingController(text: widget.config.restDays.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('نمط التمرين'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: w, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'أيام التمرين')),
          TextField(controller: r, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'أيام الراحة')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
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
