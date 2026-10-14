import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config.dart';
import '../../../core/l10n.dart';
import '../../../core/palette.dart';
import '../../../core/theme.dart';
import '../../../data/remote/api_client.dart';
import '../../providers/auth_controller.dart';
import '../../providers/core_providers.dart';
import '../../providers/settings_controller.dart';
import '../../widgets/common.dart';
import '../auth/auth_widgets.dart';

/// Ustawienia. Zmiany działają natychmiast — bez przycisków "Zapisz".
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final themeName = switch (settings.themeMode) {
      'light' => tr('Jasny', 'Light'),
      'dark' => tr('Ciemny', 'Dark'),
      _ => tr('Systemowy', 'System'),
    };
    final accentName = Palette.findAccent(settings.accentColor)?.name ?? settings.accentColor;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
              child: Text(tr('Ustawienia', 'Settings'), style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            ),
            if (user != null) _ProfileCard(),
            SectionLabel(tr('Wygląd', 'Appearance')),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _Tile(
                    icon: Icons.palette_outlined,
                    color: Palette.parse(settings.accentColor),
                    title: tr('Motyw i kolor', 'Theme & color'),
                    subtitle: '$themeName · $accentName',
                    onTap: () => context.push('/settings/theme'),
                  ),
                  const Divider(indent: 64),
                  ListTile(
                    leading: const IconBadge(Icons.translate_rounded, color: Color(0xFF9FA8DA)),
                    title: Text(tr('Język', 'Language'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: SegmentedButton<String>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
                      segments: const [
                        ButtonSegment(value: 'pl', label: Text('PL')),
                        ButtonSegment(value: 'en', label: Text('EN')),
                      ],
                      selected: {settings.language},
                      onSelectionChanged: (v) => controller.update((s) => s.copyWith(language: v.first)),
                    ),
                  ),
                ],
              ),
            ),
            SectionLabel(tr('Wydarzenia i powiadomienia', 'Events & notifications')),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _Tile(
                    icon: Icons.notifications_none_rounded,
                    color: const Color(0xFF4FC3F7),
                    title: tr('Powiadomienia', 'Notifications'),
                    subtitle: [
                      if (settings.pushEnabled) tr('push', 'push'),
                      if (settings.remindersEnabled) tr('przypomnienia ${Fmt.minutesShort(settings.defaultReminderMinutes)}', 'reminders ${Fmt.minutesShort(settings.defaultReminderMinutes)}'),
                    ].join(' · ').ifEmpty(tr('Wyłączone', 'Off')),
                    onTap: () => context.push('/settings/notifications'),
                  ),
                  const Divider(indent: 64),
                  ListTile(
                    leading: IconBadge(Icons.circle, color: Palette.parse(settings.defaultEventColor)),
                    title: Text(tr('Domyślny kolor wydarzeń', 'Default event color'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(color: Palette.parse(settings.defaultEventColor), shape: BoxShape.circle),
                    ),
                    onTap: () => _pickDefaultColor(context, ref),
                  ),
                ],
              ),
            ),
            SectionLabel(tr('Konto', 'Account')),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _Tile(
                    icon: Icons.key_outlined,
                    color: const Color(0xFFFFAB40),
                    title: tr('Zmień hasło', 'Change password'),
                    onTap: () => _changePassword(context, ref),
                  ),
                  const Divider(indent: 64),
                  _Tile(
                    icon: Icons.person_remove_outlined,
                    color: context.colors.danger,
                    title: tr('Usuń konto', 'Delete account'),
                    danger: true,
                    onTap: () => _deleteAccount(context, ref),
                  ),
                ],
              ),
            ),
            SectionLabel(tr('O aplikacji', 'About')),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _Tile(
                    icon: Icons.info_outline_rounded,
                    color: context.colors.muted,
                    title: AppConfig.appName,
                    subtitle: '${tr('Wersja', 'Version')} ${AppConfig.version}',
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: AppConfig.appName,
                      applicationVersion: AppConfig.version,
                      applicationIcon: const AppLogo(size: 48),
                    ),
                  ),
                  const Divider(indent: 64),
                  _Tile(
                    icon: Icons.privacy_tip_outlined,
                    color: context.colors.muted,
                    title: tr('Polityka prywatności', 'Privacy policy'),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(tr('Polityka prywatności', 'Privacy policy')),
                        content: Text(tr(
                          'Przechowujemy wyłącznie dane potrzebne do działania kalendarza: e-mail, imię, avatar, '
                              'ustawienia oraz wydarzenia i grupy. Wydarzenia prywatne widzisz tylko Ty, a grupowe — członkowie grupy. '
                              'Po wylogowaniu dane są usuwane z urządzenia. Konto i wszystkie dane możesz usunąć w Ustawienia → Konto.',
                          'We only store data needed for the calendar to work: e-mail, name, avatar, settings, events and groups. '
                              'Private events are visible only to you, group events to group members. '
                              'Logging out removes data from the device. You can delete your account and all data in Settings → Account.',
                        )),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDefaultColor(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => Consumer(builder: (context, ref, _) {
        final selected = ref.watch(settingsProvider).defaultEventColor;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tr('Domyślny kolor wydarzeń', 'Default event color'), style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 18),
                ColorGrid(
                  colors: Palette.eventColors,
                  selected: selected,
                  size: 40,
                  onSelected: (c) {
                    ref.read(settingsProvider.notifier).update((s) => s.copyWith(defaultEventColor: c));
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final current = await textInputDialog(
      context,
      title: tr('Zmień hasło', 'Change password'),
      label: tr('Obecne hasło', 'Current password'),
      confirmLabel: tr('Dalej', 'Next'),
      obscure: true,
    );
    if (current == null || current.isEmpty || !context.mounted) return;
    final next = await textInputDialog(
      context,
      title: tr('Nowe hasło', 'New password'),
      message: tr('Min. 8 znaków, wielka litera i cyfra.', 'Min. 8 characters, an uppercase letter and a digit.'),
      label: tr('Nowe hasło', 'New password'),
      confirmLabel: tr('Zmień', 'Change'),
      obscure: true,
    );
    if (next == null || next.isEmpty) return;
    final invalid = Validators.newPassword(next);
    if (invalid != null) {
      showSnack(invalid);
      return;
    }
    try {
      await ref.read(authProvider.notifier).changePassword(current, next);
      showSnack(tr('Hasło zostało zmienione', 'Password changed'));
    } on ApiException catch (e) {
      showSnack(errorMessage(e));
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final password = await textInputDialog(
      context,
      title: tr('Usunąć konto?', 'Delete account?'),
      message: tr('Twoje konto, wydarzenia i członkostwa zostaną trwale usunięte. Tej operacji nie można cofnąć.',
          'Your account, events and memberships will be permanently deleted. This cannot be undone.'),
      label: tr('Hasło', 'Password'),
      confirmLabel: tr('Usuń konto', 'Delete account'),
      obscure: true,
      destructive: true,
    );
    if (password == null || password.isEmpty) return;
    try {
      await ref.read(authProvider.notifier).deleteAccount(password);
    } on ApiException catch (e) {
      showSnack(errorMessage(e));
    }
  }
}

class _ProfileCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<_ProfileCard> {
  bool _uploading = false;

  Future<void> _changeAvatar() async {
    final user = ref.read(currentUserProvider);
    final action = await choiceSheet<String>(
      context,
      title: tr('Zdjęcie profilowe', 'Profile photo'),
      options: [
        ('gallery', tr('Wybierz z galerii', 'Choose from gallery'), Icons.photo_library_outlined),
        ('camera', tr('Zrób zdjęcie', 'Take a photo'), Icons.photo_camera_outlined),
        if (user?.avatarUrl != null) ('remove', tr('Usuń zdjęcie', 'Remove photo'), Icons.delete_outline_rounded),
      ],
    );
    if (action == null) return;
    final auth = ref.read(authProvider.notifier);
    setState(() => _uploading = true);
    try {
      if (action == 'remove') {
        await auth.removeAvatar();
      } else {
        final file = await ImagePicker().pickImage(
          source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (file != null) await auth.uploadAvatar(file.path);
      }
    } on ApiException catch (e) {
      showSnack(errorMessage(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _changeName() async {
    final user = ref.read(currentUserProvider);
    final name = await textInputDialog(
      context,
      title: tr('Imię i nazwisko', 'Full name'),
      label: tr('Imię i nazwisko', 'Full name'),
      confirmLabel: tr('Zapisz', 'Save'),
      initial: user?.displayName ?? '',
      maxLength: 50,
    );
    if (name == null || name.isEmpty || name == user?.displayName) return;
    try {
      await ref.read(authProvider.notifier).updateDisplayName(name);
    } on ApiException catch (e) {
      showSnack(errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider)!;
    return AppCard(
      child: Row(
        children: [
          Semantics(
            button: true,
            label: tr('Zmień zdjęcie profilowe', 'Change profile photo'),
            child: GestureDetector(
              onTap: _uploading ? null : _changeAvatar,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Avatar(id: user.id, name: user.displayName, url: user.avatarUrl, size: 64),
                  if (_uploading)
                    const Positioned.fill(child: Center(child: CircularProgressIndicator(strokeWidth: 2.4))),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: context.scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.colors.card, width: 2),
                      ),
                      child: Icon(Icons.photo_camera_rounded, size: 13, color: context.scheme.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayName, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text(user.email, style: context.text.bodySmall?.copyWith(color: context.colors.muted)),
              ],
            ),
          ),
          IconButton(tooltip: tr('Zmień imię', 'Edit name'), onPressed: _changeName, icon: const Icon(Icons.edit_outlined)),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.color, required this.title, this.subtitle, this.onTap, this.danger = false});
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: IconBadge(icon, color: color),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: danger ? context.colors.danger : null)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
