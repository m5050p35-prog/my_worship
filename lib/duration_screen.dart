import 'package:flutter/material.dart';

Future<int?> showDurationScreen(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(title: const Text('يوم واحد'), onTap: () => Navigator.pop(context, 1)),
      ListTile(title: const Text('أسبوع'), onTap: () => Navigator.pop(context, 7)),
      ListTile(title: const Text('شهر'), onTap: () => Navigator.pop(context, 30)),
      ListTile(title: const Text('سنة'), onTap: () => Navigator.pop(context, 365)),
      ListTile(title: const Text('مخصص'), onTap: () async {
        final c = TextEditingController();
        final v = await showDialog<int>(context: context, builder: (_) => AlertDialog(
          title: const Text('أدخل العدد'),
          content: TextField(controller: c, keyboardType: TextInputType.number),
          actions: [FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(c.text) ?? 0),
            child: const Text('حفظ'))],
        ));
        if (context.mounted) Navigator.pop(context, v);
      }),
    ])),
  );
}
