import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n.dart';
import '../../../core/theme.dart';
import '../../../data/remote/api_client.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
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
      final needsVerification =
          await ref.read(authProvider.notifier).register(email, _password.text, _name.text.trim());
      if (needsVerification && mounted) context.pushReplacement('/verify?email=${Uri.encodeComponent(email)}');
    } on ApiException catch (e) {
      setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      title: tr('Utwórz konto', 'Create account'),
      subtitle: tr('Planuj spotkania razem ze swoimi grupami.', 'Plan meetups together with your groups.'),
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledField(
                  label: tr('Imię i nazwisko', 'Full name'),
                  controller: _name,
                  icon: Icons.person_outline_rounded,
                  hint: tr('np. Anna Nowak', 'e.g. Anna Smith'),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return tr('Podaj imię', 'Enter your name');
                    if (value.length > 50) return tr('Maks. 50 znaków', 'Max. 50 characters');
                    return null;
                  },
                ),
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
                  hint: tr('Min. 8 znaków, wielka litera i cyfra', 'Min. 8 chars, uppercase and digit'),
                  obscure: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.newPassword,
                ),
                LabeledField(
                  label: tr('Powtórz hasło', 'Repeat password'),
                  controller: _confirm,
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) => v != _password.text ? tr('Hasła nie są takie same', 'Passwords do not match') : null,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: context.colors.danger)),
          ),
        GradientButton(
          label: tr('Utwórz konto', 'Create account'),
          icon: Icons.arrow_forward_rounded,
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(tr('Masz już konto?', 'Already have an account?'), style: TextStyle(color: context.colors.muted)),
            TextButton(onPressed: () => context.pop(), child: Text(tr('Zaloguj się', 'Sign in'))),
          ],
        ),
      ],
    );
  }
}
