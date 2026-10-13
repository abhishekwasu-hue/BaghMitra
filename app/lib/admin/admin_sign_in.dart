import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'admin_auth.dart';

class AdminSignInScreen extends StatefulWidget {
  const AdminSignInScreen({
    required this.auth,
    required this.productName,
    super.key,
  });
  final AdminAuth auth;
  final String productName;

  @override
  State<AdminSignInScreen> createState() => _AdminSignInScreenState();
}

class _AdminSignInScreenState extends State<AdminSignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _failed = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await widget.auth.signIn(_email.text.trim(), _password.text);
    } on AdminSignInError {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(BmSpace.xl),
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.adminTitle(widget.productName),
                    style: BmType.title.copyWith(color: c.brand),
                  ),
                  const SizedBox(height: BmSpace.lg),
                  TextField(
                    key: const Key('admin-email'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(labelText: t.adminEmail),
                  ),
                  const SizedBox(height: BmSpace.md),
                  TextField(
                    key: const Key('admin-password'),
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(labelText: t.adminPassword),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_failed) ...[
                    const SizedBox(height: BmSpace.sm),
                    Text(
                      t.adminSignInFailed,
                      style: BmType.body.copyWith(color: c.danger),
                    ),
                  ],
                  const SizedBox(height: BmSpace.lg),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(t.adminSignIn),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
