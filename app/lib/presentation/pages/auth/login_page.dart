import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n.dart';
import '../../../core/theme.dart';
import '../../../data/remote/api_client.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final email = _email.text.trim();
    try {
      await ref.read(authProvider.notifier).login(email, _password.text, remember: _remember);
    } on ApiException catch (e) {
      if (e.code == 'EMAIL_NOT_VERIFIED') {
        await ref.read(authProvider.notifier).resendVerification(email).catchError((_) {});
        if (mounted) context.push('/verify?email=${Uri.encodeComponent(email)}');
      } else {
        setState(() => _error = errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: tr('Witaj ponownie!', 'Welcome back!'),
      subtitle: tr('Zsynchronizuj swój grafik.', "Let's get your schedule synced."),
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledField(
                  label: tr('Adres e-mail', 'E-mail address'),
                  controller: _email,
                  icon: Icons.mail_outline_rounded,
                  hint: 'hello@letsmeetup.app',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                LabeledField(
                  label: tr('Hasło', 'Password'),
                  controller: _password,
                  icon: Icons.lock_outline_rounded,
                  hint: tr('Wpisz hasło', 'Enter your password'),
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: Validators.required,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/forgot?email=${Uri.encodeComponent(_email.text.trim())}'),
            child: Text(tr('Nie pamiętasz hasła?', 'Forgot password?')),
          ),
        ),
        CheckboxListTile(
          value: _remember,
          onChanged: (v) => setState(() => _remember = v ?? true),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(tr('Zapamiętaj mnie', 'Remember me'), style: context.text.bodyMedium),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: context.colors.danger)),
          ),
        const SizedBox(height: 12),
        GradientButton(
          label: tr('Zaloguj się', 'Sign in'),
          icon: Icons.arrow_forward_rounded,
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(tr('Nowy tutaj?', 'New here?'), style: context.text.bodyLarge?.copyWith(color: context.colors.muted)),
            TextButton.icon(
              onPressed: () => context.push('/register'),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: Text(tr('Utwórz konto', 'Create account'), style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ],
    );
  }
}
