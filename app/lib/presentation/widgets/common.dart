import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/l10n.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';

/// Okrągły avatar: zdjęcie albo inicjały na kolorze wyliczonym z id.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.id, required this.name, this.url, this.size = 40, this.border});

  final String id;
  final String name;
  final String? url;
  final double size;
  final Color? border;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = Palette.fromId(id);
    final resolved = AppConfig.resolveUrl(url);
    final fallback = Container(
      alignment: Alignment.center,
      color: color,
      child: Text(
        _initials,
        style: TextStyle(
          color: Palette.withLightness(color, 0.25),
          fontWeight: FontWeight.w700,
          fontSize: size * 0.4,
          height: 1,
        ),
      ),
    );
    return Semantics(
      label: name,
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: border == null ? null : Border.all(color: border!, width: size > 24 ? 2 : 1),
        ),
        child: ClipOval(
          child: resolved == null
              ? fallback
              : CachedNetworkImage(
                  imageUrl: resolved,
                  fit: BoxFit.cover,
                  memCacheWidth: (size * 3).round(),
                  placeholder: (_, _) => fallback,
                  errorWidget: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}

/// Zachodzące na siebie avatary z licznikiem "+N".
class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.people, this.size = 28, this.max = 3});

  final List<({String id, String name, String? url})> people;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    final shown = people.take(max).toList();
    final extra = people.length - shown.length;
    final overlap = size * 0.62;
    final count = shown.length + (extra > 0 ? 1 : 0);
    return SizedBox(
      height: size,
      width: count == 0 ? 0 : overlap * (count - 1) + size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * overlap,
              child: Avatar(id: shown[i].id, name: shown[i].name, url: shown[i].url, size: size, border: context.colors.card),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * overlap,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.scheme.surfaceContainerHighest,
                  border: Border.all(color: context.colors.card, width: 2),
                ),
                child: Text('+$extra', style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Mała etykieta sekcji ("SZCZEGÓŁY WYDARZENIA").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing, this.padding = const EdgeInsets.fromLTRB(4, 24, 4, 10)});

  final String text;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: context.text.labelSmall?.copyWith(
                color: context.colors.muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Biała karta z delikatnym cieniem (styl prototypu).
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.radius = 22, this.color});

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: context.colors.shadow, blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: color ?? context.colors.card,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

/// Ikona w zaokrąglonym kwadracie o kolorze akcentu.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.color, this.size = 36});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.scheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(size * 0.32)),
      child: Icon(icon, size: size * 0.55, color: Palette.withLightness(c, Theme.of(context).brightness == Brightness.dark ? 0.75 : 0.42)),
    );
  }
}

/// Siatka okrągłych próbek kolorów (paleta wydarzeń / akcentów).
class ColorGrid extends StatelessWidget {
  const ColorGrid({super.key, required this.colors, required this.selected, required this.onSelected, this.size = 34});

  final List<NamedColor> colors;
  final String selected;
  final ValueChanged<String> onSelected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (final c in colors)
          Semantics(
            button: true,
            selected: c.hex.toUpperCase() == selected.toUpperCase(),
            label: c.name,
            child: GestureDetector(
              onTap: () => onSelected(c.hex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: c.color,
                  shape: BoxShape.circle,
                  border: c.hex.toUpperCase() == selected.toUpperCase()
                      ? Border.all(color: context.scheme.onSurface.withValues(alpha: 0.75), width: 2.5)
                      : null,
                  boxShadow: c.hex.toUpperCase() == selected.toUpperCase()
                      ? [BoxShadow(color: c.color.withValues(alpha: 0.6), blurRadius: 10)]
                      : null,
                ),
                child: c.hex.toUpperCase() == selected.toUpperCase()
                    ? Icon(Icons.check_rounded, size: size * 0.55, color: Palette.withLightness(c.color, 0.25))
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

/// Logo aplikacji (ikona z prototypu).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset('assets/icon/logo.png', width: size, height: size, fit: BoxFit.cover),
      );
}

/// Duży przycisk z gradientem (logowanie, zapis formularza).
class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.label, required this.onPressed, this.loading = false, this.icon, this.color});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? context.scheme.primary;
    final enabled = onPressed != null && !loading;
    final fg = Palette.onColor(base);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled || loading ? 1 : 0.55,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(colors: [Palette.withLightness(base, 0.7), base, Palette.withLightness(base, 0.45)]),
            boxShadow: [BoxShadow(color: base.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: enabled ? onPressed : null,
              child: SizedBox(
                height: 56,
                child: Center(
                  child: loading
                      ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(label, style: context.text.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w700)),
                            if (icon != null) ...[const SizedBox(width: 8), Icon(icon, color: fg, size: 20)],
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mały znacznik roli / statusu ("ADMIN", "CZŁONEK").
class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = Palette.withLightness(color, dark ? 0.78 : 0.42);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: dark ? 0.2 : 0.14), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 4)],
          Text(
            label.toUpperCase(),
            style: context.text.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w800, letterSpacing: 0.6, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBadge(icon, size: 52, color: context.colors.muted),
          const SizedBox(height: 14),
          Text(title, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message, style: context.text.bodyMedium?.copyWith(color: context.colors.muted), textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

// --- Dialogi ---

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('Anuluj', 'Cancel'))),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: destructive ? TextButton.styleFrom(foregroundColor: context.colors.danger) : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Pole tekstowe w dialogu (np. zmiana imienia, hasło).
Future<String?> textInputDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
  String initial = '',
  bool obscure = false,
  bool destructive = false,
  String? message,
  int? maxLength,
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null) ...[Text(message), const SizedBox(height: 14)],
          TextField(
            controller: controller,
            autofocus: true,
            obscureText: obscure,
            maxLength: maxLength,
            decoration: InputDecoration(labelText: label),
            onSubmitted: (v) => Navigator.pop(context, v.trim()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Anuluj', 'Cancel'))),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          style: destructive ? TextButton.styleFrom(foregroundColor: context.colors.danger) : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

/// Wybór jednej z opcji (np. "To wystąpienie" / "Cała seria").
Future<T?> choiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<(T value, String label, IconData icon)> options,
  bool destructive = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            for (final (value, label, icon) in options)
              ListTile(
                leading: Icon(icon, color: destructive ? context.colors.danger : null),
                title: Text(label, style: destructive ? TextStyle(color: context.colors.danger) : null),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    ),
  );
}
