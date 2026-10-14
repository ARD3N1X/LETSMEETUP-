import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/palette.dart';
import '../../../core/theme.dart';
import '../../providers/settings_controller.dart';
import '../../widgets/common.dart';

/// Motyw (systemowy / jasny / ciemny) i kolor akcentu z podglądem na żywo (prototyp "Theme Color").
/// Zmiany działają natychmiast, więc ekran nie ma przycisku "Zapisz".
class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final accent = Palette.findAccent(settings.accentColor);
    final primary = context.scheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text(tr('Motyw i kolor', 'Theme & color'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Palette.parse(settings.accentColor), const Color(0xFFF0CFF2), const Color(0xFFFFD1DC)],
              ),
            ),
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: context.colors.card.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(18)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.palette_outlined, size: 16, color: primary),
                      const SizedBox(width: 6),
                      Text(
                        tr('PERSONALIZACJA', 'CUSTOMIZATION'),
                        style: context.text.labelSmall?.copyWith(color: primary, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('Paleta: ${accent?.name ?? settings.accentColor}', '${accent?.name ?? settings.accentColor} palette'),
                    style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          SectionLabel(tr('Tryb', 'Mode')),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 'system', icon: const Icon(Icons.brightness_auto_outlined), label: Text(tr('Systemowy', 'System'))),
              ButtonSegment(value: 'light', icon: const Icon(Icons.light_mode_outlined), label: Text(tr('Jasny', 'Light'))),
              ButtonSegment(value: 'dark', icon: const Icon(Icons.dark_mode_outlined), label: Text(tr('Ciemny', 'Dark'))),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (v) => controller.update((s) => s.copyWith(themeMode: v.first)),
          ),
          SectionLabel(tr('Podgląd na żywo', 'Live preview')),
          const _Preview(),
          SectionLabel(
            tr('Wybierz kolor', 'Choose your color'),
            trailing: accent == null ? null : TagChip(label: accent.name, color: accent.color),
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            child: ColorGrid(
              colors: Palette.accentColors,
              selected: settings.accentColor,
              size: 46,
              onSelected: (c) => controller.update((s) => s.copyWith(accentColor: c)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final primary = context.scheme.primary;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('Podgląd', 'Preview'), style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text(Fmt.fullDate(now), style: context.text.bodySmall?.copyWith(color: context.colors.muted)),
                  ],
                ),
              ),
              IconBadge(Icons.auto_awesome_outlined, color: primary, size: 32),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final (i, d) in Fmt.weekdayShort.indexed)
                Expanded(
                  child: Center(
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: i == now.weekday - 1 ? BoxDecoration(color: primary, shape: BoxShape.circle) : null,
                      child: Text(
                        d,
                        style: context.text.labelSmall?.copyWith(
                          color: i == now.weekday - 1 ? context.scheme.onPrimary : context.colors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _previewEvent(context, tr('Przegląd projektu', 'Design review'), '10:00 – 11:30', primary, highlighted: true),
          const SizedBox(height: 8),
          _previewEvent(context, tr('Lunch zespołu', 'Team lunch'), '12:30 – 13:30', context.colors.muted),
        ],
      ),
    );
  }

  Widget _previewEvent(BuildContext context, String title, String time, Color color, {bool highlighted = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted ? context.scheme.primaryContainer : context.scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: highlighted ? Border.all(color: color.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        children: [
          IconBadge(Icons.calendar_month_outlined, color: color, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: highlighted ? null : context.colors.muted)),
                Text(time, style: context.text.bodySmall?.copyWith(color: context.colors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
