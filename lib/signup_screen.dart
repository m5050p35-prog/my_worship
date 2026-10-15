import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

class SignupScreen extends StatefulWidget {
  final Future<String?> Function(String email) onSubmit;
  const SignupScreen({super.key, required this.onSubmit});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _loading = false;
  String? _err;

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    final email = _email.text.trim().toLowerCase();
    if (!email.endsWith('@gmail.com')) {
      setState(() => _err = t.t('gmail_only'));
      return;
    }
    setState(() {
      _loading = true;
      _err = null;
    });
    final e = await widget.onSubmit(email);
    if (!mounted) {
      return;
    }
    if (e == null) {
      Navigator.pop(context, email);
    } else {
      setState(() {
        _loading = false;
        _err = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.t('signup'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: t.t('name'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: t.t('email'),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_err != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _err!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(t.t('create')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
