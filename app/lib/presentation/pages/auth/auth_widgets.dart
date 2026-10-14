import 'package:flutter/material.dart';

import '../../../core/config.dart';
import '../../../core/l10n.dart';
import '../../../core/theme.dart';
import '../../widgets/common.dart';

/// Wspólny układ ekranów logowania/rejestracji (prototyp "Login / Register").
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.children, this.showBack = false});

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showBack ? AppBar(backgroundColor: Colors.transparent) : null,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.9, -0.8),
            radius: 1.4,
            colors: [context.scheme.primary.withValues(alpha: 0.10), context.colors.background],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: [BoxShadow(color: context.colors.shadow, blurRadius: 30, offset: const Offset(0, 12))],
                        ),
                        child: const AppLogo(size: 112),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, textAlign: TextAlign.center, style: context.text.bodyLarge?.copyWith(color: context.colors.muted)),
                    const SizedBox(height: 28),
                    ...children,
                    const SizedBox(height: 28),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${AppConfig.appName} v${AppConfig.version}',
                          style: context.text.labelMedium?.copyWith(
                            color: context.scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pole formularza z etykietą nad polem i ikoną (prototyp).
class LabeledField extends StatefulWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.validator,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final String? Function(String?)? validator;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  State<LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<LabeledField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(widget.label, padding: const EdgeInsets.fromLTRB(4, 14, 4, 8)),
        TextFormField(
          controller: widget.controller,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          validator: widget.validator,
          onFieldSubmitted: widget.onSubmitted,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Padding(padding: const EdgeInsets.all(10), child: IconBadge(widget.icon, size: 30)),
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? tr('Pokaż hasło', 'Show password') : tr('Ukryj hasło', 'Hide password'),
                    icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class Validators {
  Validators._();

  static String? email(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return tr('Podaj adres e-mail', 'Enter your e-mail');
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) return tr('Nieprawidłowy adres e-mail', 'Invalid e-mail');
    return null;
  }

  /// Min. 8 znaków, 1 wielka litera, 1 cyfra (sekcja 5.8).
  static String? newPassword(String? v) {
    final value = v ?? '';
    if (value.length < 8) return tr('Hasło musi mieć min. 8 znaków', 'At least 8 characters');
    if (!RegExp(r'[A-ZĄĆĘŁŃÓŚŹŻ]').hasMatch(value)) return tr('Dodaj wielką literę', 'Add an uppercase letter');
    if (!RegExp(r'\d').hasMatch(value)) return tr('Dodaj cyfrę', 'Add a digit');
    return null;
  }

  static String? required(String? v) => (v?.trim().isEmpty ?? true) ? tr('To pole jest wymagane', 'Required') : null;
}
