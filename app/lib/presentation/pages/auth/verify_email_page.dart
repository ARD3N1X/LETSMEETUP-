import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/theme.dart';
import '../../../data/remote/api_client.dart';
import '../../providers/auth_controller.dart';
import '../../providers/core_providers.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key, required this.email});
  final String email;

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  final _code = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.trim().length != 6) {
      setState(() => _error = tr('Kod ma 6 cyfr', 'The code has 6 digits'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).verifyEmail(widget.email, _code.text.trim());
    } on ApiException catch (e) {
      setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authProvider.notifier).resendVerification(widget.email);
      showSnack(tr('Wysłaliśmy nowy kod.', 'A new code has been sent.'));
    } on ApiException catch (e) {
      showSnack(errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      title: tr('Potwierdź e-mail', 'Confirm your e-mail'),
      subtitle: tr('Wpisz 6-cyfrowy kod wysłany na\n${widget.email}', 'Enter the 6-digit code sent to\n${widget.email}'),
      children: [
        TextField(
          controller: _code,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: context.text.headlineSmall?.copyWith(letterSpacing: 10, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(counterText: '', hintText: '••••••'),
          onSubmitted: (_) => _verify(),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: context.colors.danger)),
          ),
        const SizedBox(height: 24),
        GradientButton(label: tr('Potwierdź', 'Confirm'), loading: _loading, onPressed: _verify),
        const SizedBox(height: 12),
        TextButton(onPressed: _resend, child: Text(tr('Wyślij kod ponownie', 'Resend code'))),
      ],
    );
  }
}
