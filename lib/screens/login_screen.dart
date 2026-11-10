import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/backend.dart';
import '../l10n/app_localizations.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

String authErrorText(AppLocalizations l, Object error) => switch (error) {
  AuthException(error: AuthError.invalidCredentials) => l.authInvalidCredentials,
  AuthException(error: AuthError.emailInUse) => l.authEmailInUse,
  AuthException(error: AuthError.weakPassword) => l.authWeakPassword,
  AuthException(error: AuthError.invalidEmail) => l.authInvalidEmail,
  AuthException(error: AuthError.network) => l.authNetwork,
  _ => l.authUnknown,
};

/// Logowanie i zakładanie konta e-mailem i hasłem.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _register = false;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final backend = ref.read(backendProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_register) {
        await backend.registerWithEmail(name: _name.text, email: _email.text, password: _password.text);
      } else {
        await backend.signInWithEmail(_email.text, _password.text);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = authErrorText(AppLocalizations.of(context), e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final l = AppLocalizations.of(context);
    if (_email.text.trim().isEmpty) {
      setState(() => _error = l.authInvalidEmail);
      return;
    }
    try {
      await ref.read(backendProvider).sendPasswordReset(_email.text);
      if (mounted) setState(() => _error = null);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.resetSent)));
    } catch (e) {
      if (mounted) setState(() => _error = authErrorText(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    String? required(String? v) => (v == null || v.trim().isEmpty) ? l.fieldRequired : null;

    return Scaffold(
      appBar: brandAppBar(context, l.loginTitle, color: RollColors.purple),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l.loginTabSignIn)),
                ButtonSegment(value: true, label: Text(l.loginTabRegister)),
              ],
              selected: {_register},
              onSelectionChanged: (s) => setState(() {
                _register = s.first;
                _error = null;
              }),
            ),
            const SizedBox(height: 20),
            if (_register) ...[
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: l.loginName),
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.givenName],
                validator: required,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _email,
              decoration: InputDecoration(labelText: l.loginEmailField),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              decoration: InputDecoration(labelText: l.loginPassword),
              obscureText: true,
              autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
              validator: (v) => required(v) ?? (_register && v!.length < 6 ? l.passwordTooShort : null),
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_register ? l.registerSubmit : l.loginSubmit),
            ),
            if (!_register) TextButton(onPressed: _busy ? null : _reset, child: Text(l.forgotPassword)),
          ],
        ),
      ),
    );
  }
}
