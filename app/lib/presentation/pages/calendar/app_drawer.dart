import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config.dart';
import '../../../core/l10n.dart';
import '../../../core/palette.dart';
import '../../../core/theme.dart';
import '../../providers/auth_controller.dart';
import '../../providers/core_providers.dart';
import '../../widgets/common.dart';

/// Panel "Nawigator": profil, widoczność grup w kalendarzu i wylogowanie.
/// Ustawienia są wyłącznie w dolnym pasku, grupy tworzy się na ekranie Grupy — bez dublowania.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final groups = ref.watch(groupsProvider).value ?? const [];
    final visibility = ref.watch(visibilityProvider).value ?? const {};
    final repo = ref.read(repositoryProvider);

    return Drawer(
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(32))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.layers_outlined, color: context.scheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: SectionLabel(tr('Nawigator', 'Navigator'), padding: EdgeInsets.zero)),
                  IconButton(
                    tooltip: tr('Zamknij', 'Close'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (user != null)
                AppCard(
                  child: Row(
                    children: [
                      Avatar(id: user.id, name: user.displayName, url: user.avatarUrl, size: 52),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.displayName, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            Text(
                              user.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall?.copyWith(color: context.colors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView(
                  children: [
                    SectionLabel(tr('Moje grupy', 'My groups')),
                    if (groups.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Text(
                          tr('Nie należysz jeszcze do żadnej grupy. Utwórz ją lub dołącz w zakładce Grupy.',
                              'You are not in any group yet. Create or join one in the Groups tab.'),
                          style: context.text.bodySmall?.copyWith(color: context.colors.muted),
                        ),
                      ),
                    for (final g in groups)
                      CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        controlAffinity: ListTileControlAffinity.trailing,
                        dense: true,
                        value: visibility[g.id] ?? true,
                        activeColor: Palette.parse(g.color),
                        onChanged: (v) => repo.setGroupVisible(g.id, v ?? true),
                        title: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: Palette.parse(g.color), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(g.name, style: context.text.bodyLarge, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    SectionLabel(tr('Prywatne', 'Private')),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      dense: true,
                      leading: Icon(Icons.lock_outline_rounded, size: 18, color: context.colors.muted),
                      title: Text(
                        tr('Moje wydarzenia', 'My events'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: context.colors.muted),
                      ),
                      trailing: TagChip(label: tr('Stałe', 'Locked'), color: context.colors.muted),
                    ),
                  ],
                ),
              ),
              const Divider(),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.danger,
                  backgroundColor: context.colors.dangerSoft,
                  side: BorderSide(color: context.colors.danger.withValues(alpha: 0.25)),
                ),
                onPressed: () async {
                  final confirmed = await confirmDialog(
                    context,
                    title: tr('Wylogować się?', 'Log out?'),
                    message: tr('Dane kalendarza zostaną usunięte z tego urządzenia.', 'Calendar data will be removed from this device.'),
                    confirmLabel: tr('Wyloguj', 'Log out'),
                    destructive: true,
                  );
                  if (confirmed) await ref.read(authProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text(tr('Wyloguj', 'Log out')),
              ),
              const SizedBox(height: 12),
              Text(
                '${AppConfig.appName} v${AppConfig.version}',
                textAlign: TextAlign.center,
                style: context.text.labelSmall?.copyWith(color: context.colors.muted, letterSpacing: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
