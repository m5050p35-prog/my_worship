import 'package:flutter/material.dart';

Future<String?> showNoteDialog(BuildContext context, String current) {
  final ctrl = TextEditingController(text: current);
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('ملاحظة'),
      content: TextField(controller: ctrl, maxLines: 3, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(context, ctrl.text),
          child: const Text('حفظ')),
      ],
    ),
  );
}
