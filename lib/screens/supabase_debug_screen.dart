import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class SupabaseDebugScreen extends StatefulWidget {
  const SupabaseDebugScreen({super.key});
  @override
  State<SupabaseDebugScreen> createState() => _S();
}

class _S extends State<SupabaseDebugScreen> {
  String _out = 'اضغط "فحص"';
  bool _busy = false;

  Future<void> _check() async {
    setState(() { _busy = true; _out = 'جارٍ الفحص...'; });
    final sb = StringBuffer();
    sb.writeln('URL: ${SupabaseService.url}');
    for (final t in ['users', 'prayer_days', 'workout_entries', 'fasting_entries']) {
      try {
        final r = await SupabaseService.client.from(t).select().limit(1);
        sb.writeln('✅ $t → ${(r as List).length} صف');
      } catch (e) {
        sb.writeln('❌ $t → $e');
      }
    }
    setState(() { _out = sb.toString(); _busy = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فحص Supabase')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          FilledButton.icon(
            onPressed: _busy ? null : _check,
            icon: const Icon(Icons.sync),
            label: const Text('فحص')),
          const SizedBox(height: 16),
          Expanded(child: SingleChildScrollView(
            child: SelectableText(_out, style: const TextStyle(fontFamily: 'monospace')))),
        ]),
      ),
    );
  }
}
