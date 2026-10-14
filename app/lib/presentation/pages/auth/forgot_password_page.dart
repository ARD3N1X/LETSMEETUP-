import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/theme.dart';
import '../../../data/remote/api_client.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';

/// Reset hasła: 1) e-mail → kod, 2) kod + nowe hasło.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key, this.email = ''});
  final String email;

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = ref.read(authProvider.notifier);
    try {
      if (!_codeSent) {
        await auth.forgotPassword(_email.text.trim());
        setState(() => _codeSent = true);
      } else {
        await auth.resetPassword(_email.text.trim(), _code.text.trim(), _password.text);
      }
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
      title: tr('Nowe hasło', 'New password'),
      subtitle: _codeSent
          ? tr('Jeśli konto istnieje, wysłaliśmy kod na podany adres.', 'If the account exists, we sent a code to it.')
          : tr('Podaj e-mail — wyślemy kod do zmiany hasła.', "Enter your e-mail — we'll send a reset code."),
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledField(
                label: tr('Adres e-mail', 'E-mail address'),
                controller: _email,
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              if (_codeSent) ...[
                SectionLabel(tr('Kod z e-maila', 'Code from e-mail'), padding: const EdgeInsets.fromLTRB(4, 14, 4, 8)),
                TextFormField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(counterText: '', hintText: '123456'),
                  validator: (v) => (v?.trim().length ?? 0) == 6 ? null : tr('Kod ma 6 cyfr', 'The code has 6 digits'),
                ),
                LabeledField(
                  label: tr('Nowe hasło', 'New password'),
                  controller: _password,
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                  validator: Validators.newPassword,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: context.colors.danger)),
          ),
        const SizedBox(height: 24),
        GradientButton(
          label: _codeSent ? tr('Zmień hasło', 'Change password') : tr('Wyślij kod', 'Send code'),
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
