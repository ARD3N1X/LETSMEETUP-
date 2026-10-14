import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/theme.dart';
import '../../providers/core_providers.dart';
import '../../providers/settings_controller.dart';
import '../../widgets/common.dart';

/// Powiadomienia (prototyp "Notifications & Reminders"): push + przypomnienia z domyślnym czasem.
/// Przełączniki działają od razu — bez przycisku "Zastosuj".
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  static const _reminderOptions = [5, 15, 30, 60, 1440];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final pushAvailable = ref.watch(pushServiceProvider).isAvailable;
    final selectedIndex = _reminderOptions.indexOf(settings.defaultReminderMinutes);

    return Scaffold(
      appBar: AppBar(title: Text(tr('Powiadomienia', 'Notifications'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [context.scheme.primaryContainer, context.colors.card],
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: context.colors.card, borderRadius: BorderRadius.circular(18)),
                  child: Icon(Icons.notifications_none_rounded, size: 30, color: context.scheme.primary),
                ),
                const SizedBox(height: 12),
                Text(tr('Bądź na bieżąco', 'Stay synced'), style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(tr('Zdecyduj, jak otrzymujesz informacje', 'Manage how you receive updates'),
                    style: context.text.bodySmall?.copyWith(color: context.colors.muted)),
              ],
            ),
          ),
          SectionLabel(tr('Preferencje', 'Alert preferences')),
          _SwitchCard(
            icon: Icons.phone_iphone_rounded,
            color: const Color(0xFF4FC3F7),
            title: tr('Powiadomienia push', 'Push notifications'),
            subtitle: tr('Nowe wydarzenia i zmiany w Twoich grupach', 'New events and changes in your groups'),
            value: settings.pushEnabled,
            onChanged: (v) => controller.update((s) => s.copyWith(pushEnabled: v)),
          ),
          const SizedBox(height: 10),
          _SwitchCard(
            icon: Icons.alarm_rounded,
            color: const Color(0xFF77DD77),
            title: tr('Przypomnienia o wydarzeniach', 'Event reminders'),
            subtitle: tr('Działają także bez internetu', 'Work even without internet'),
            value: settings.remindersEnabled,
            onChanged: (v) => controller.update((s) => s.copyWith(remindersEnabled: v)),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: settings.remindersEnabled ? 1 : 0.45,
            child: IgnorePointer(
              ignoring: !settings.remindersEnabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionLabel(tr('Czas przypomnienia', 'Reminder timing')),
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tr('Domyślne przypomnienie', 'Default reminder'),
                                      style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                  Text(tr('Kiedy mamy Ci przypomnieć?', 'When should we alert you by default?'),
                                      style: context.text.bodySmall?.copyWith(color: context.colors.muted)),
                                ],
                              ),
                            ),
                            TagChip(label: Fmt.minutes(settings.defaultReminderMinutes), color: const Color(0xFF77DD77)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (final m in _reminderOptions)
                              Semantics(
                                button: true,
                                selected: m == settings.defaultReminderMinutes,
                                label: Fmt.minutes(m),
                                child: GestureDetector(
                                  onTap: () => controller.update((s) => s.copyWith(defaultReminderMinutes: m)),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    width: m == settings.defaultReminderMinutes ? 54 : 46,
                                    height: m == settings.defaultReminderMinutes ? 54 : 46,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: m == settings.defaultReminderMinutes
                                          ? context.scheme.primary
                                          : context.scheme.surfaceContainerHighest,
                                    ),
                                    child: Text(
                                      Fmt.minutesShort(m),
                                      style: context.text.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: m == settings.defaultReminderMinutes ? context.scheme.onPrimary : context.colors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: selectedIndex < 0 ? 0 : (selectedIndex + 1) / _reminderOptions.length,
                            minHeight: 6,
                            backgroundColor: context.scheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.scheme.outline),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: context.colors.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pushAvailable
                        ? tr('Uprawnienia do powiadomień możesz też zmienić w ustawieniach systemu.',
                            'You can also change notification permissions in system settings.')
                        : tr('Push w tle wymaga konfiguracji Firebase. Do tego czasu powiadomienia o aktywności grup pojawiają się, gdy aplikacja jest otwarta.',
                            'Background push requires Firebase configuration. Until then, group activity notifications appear while the app is open.'),
                    style: context.text.bodySmall?.copyWith(color: context.colors.muted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: SwitchListTile(
        secondary: IconBadge(icon, color: color, size: 42),
        title: Text(title, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
