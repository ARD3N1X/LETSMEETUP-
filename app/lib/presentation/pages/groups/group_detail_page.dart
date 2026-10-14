import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n.dart';
import '../../../core/palette.dart';
import '../../../core/theme.dart';
import '../../../data/models.dart';
import '../../../data/remote/api_client.dart';
import '../../providers/auth_controller.dart';
import '../../providers/core_providers.dart';
import '../../widgets/common.dart';

/// Zarządzanie grupą: zakładki Członkowie / Ustawienia. Akcje admina widoczne tylko dla adminów.
class GroupDetailPage extends ConsumerWidget {
  const GroupDetailPage({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupsByIdProvider)[groupId];
    if (group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: ref.watch(groupsProvider).isLoading
              ? const CircularProgressIndicator()
              : EmptyState(
                  icon: Icons.group_off_outlined,
                  title: tr('Grupa niedostępna', 'Group unavailable'),
                  message: tr('Grupa została usunięta lub nie jesteś już jej członkiem.', 'The group was deleted or you are no longer a member.'),
                ),
        ),
      );
    }
    final color = Palette.parse(group.color);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          bottom: TabBar(
            indicatorColor: color,
            labelStyle: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: tr('Członkowie (${group.memberCount})', 'Members (${group.memberCount})')),
              Tab(text: tr('Ustawienia', 'Settings')),
            ],
          ),
        ),
        body: TabBarView(children: [_MembersTab(group: group), _SettingsTab(group: group)]),
      ),
    );
  }
}

Future<void> _run(BuildContext context, Future<void> Function() action, {String? success}) async {
  try {
    await action();
    if (success != null) showSnack(success);
  } on ApiException catch (e) {
    showSnack(errorMessage(e));
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final repo = ref.read(repositoryProvider);
    final members = [...group.members]
      ..sort((a, b) {
        if (a.isAdmin != b.isAdmin) return a.isAdmin ? -1 : 1;
        return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      });

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: members.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final m = members[i];
        final isMe = m.userId == me?.id;
        return AppCard(
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
          child: Row(
            children: [
              Avatar(id: m.userId, name: m.displayName, url: m.avatarUrl, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMe ? '${m.displayName} (${tr('Ty', 'you')})' : m.displayName,
                      style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    m.isAdmin
                        ? const TagChip(label: 'Admin', color: Color(0xFFFF8FB1), icon: Icons.shield_outlined)
                        : TagChip(label: tr('Członek', 'Member'), color: const Color(0xFF4FC3F7)),
                  ],
                ),
              ),
              if (group.isAdmin && !isMe)
                PopupMenuButton<String>(
                  tooltip: tr('Zarządzaj członkiem', 'Manage member'),
                  onSelected: (action) async {
                    switch (action) {
                      case 'role':
                        await _run(context, () => repo.setMemberRole(group.id, m.userId, m.isAdmin ? GroupRole.member : GroupRole.admin));
                      case 'remove':
                        final ok = await confirmDialog(
                          context,
                          title: tr('Usunąć z grupy?', 'Remove from group?'),
                          message: tr('${m.displayName} straci dostęp do wydarzeń grupy.', '${m.displayName} will lose access to group events.'),
                          confirmLabel: tr('Usuń', 'Remove'),
                          destructive: true,
                        );
                        if (ok && context.mounted) await _run(context, () => repo.removeMember(group.id, m.userId));
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'role',
                      child: Text(m.isAdmin ? tr('Odbierz rolę admina', 'Remove admin role') : tr('Nadaj rolę admina', 'Make admin')),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text(tr('Usuń z grupy', 'Remove from group'), style: TextStyle(color: context.colors.danger)),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsTab extends ConsumerStatefulWidget {
  const _SettingsTab({required this.group});
  final Group group;

  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  late final _name = TextEditingController(text: widget.group.name);
  late final _description = TextEditingController(text: widget.group.description ?? '');
  late String _color = widget.group.color;
  bool _saving = false;

  Group get group => widget.group;

  bool get _dirty =>
      _name.text.trim() != group.name || _description.text.trim() != (group.description ?? '') || _color != group.color;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      showSnack(tr('Podaj nazwę grupy', 'Enter the group name'));
      return;
    }
    setState(() => _saving = true);
    await _run(
      context,
      () => ref.read(repositoryProvider).updateGroup(group.id, name: _name.text.trim(), description: _description.text.trim(), color: _color),
      success: tr('Zapisano', 'Saved'),
    );
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _leave() async {
    final ok = await confirmDialog(
      context,
      title: tr('Opuścić grupę?', 'Leave group?'),
      message: group.memberCount == 1
          ? tr('Jesteś ostatnim członkiem — grupa zostanie usunięta.', 'You are the last member — the group will be deleted.')
          : tr('Wydarzenia grupy znikną z Twojego kalendarza.', 'Group events will disappear from your calendar.'),
      confirmLabel: tr('Opuść', 'Leave'),
      destructive: true,
    );
    if (!ok || !mounted) return;
    final router = GoRouter.of(context);
    try {
      await ref.read(repositoryProvider).leaveGroup(group.id);
      router.go('/groups');
    } on ApiException catch (e) {
      showSnack(errorMessage(e));
    }
  }

  Future<void> _delete() async {
    final password = await textInputDialog(
      context,
      title: tr('Usunąć grupę?', 'Delete group?'),
      message: tr('Grupa i wszystkie jej wydarzenia zostaną trwale usunięte u wszystkich członków. Potwierdź hasłem.',
          'The group and all its events will be permanently deleted for all members. Confirm with your password.'),
      label: tr('Hasło', 'Password'),
      confirmLabel: tr('Usuń grupę', 'Delete group'),
      obscure: true,
      destructive: true,
    );
    if (password == null || password.isEmpty || !mounted) return;
    final router = GoRouter.of(context);
    try {
      await ref.read(repositoryProvider).deleteGroup(group.id, password);
      router.go('/groups');
      showSnack(tr('Grupa została usunięta', 'Group deleted'));
    } on ApiException catch (e) {
      showSnack(errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = group.isAdmin;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        SectionLabel(tr('Kod zaproszenia', 'Invite code')),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      group.inviteCode,
                      style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 4, fontFamily: 'monospace'),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: tr('Kopiuj kod', 'Copy code'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: group.inviteCode));
                      showSnack(tr('Skopiowano kod', 'Code copied'));
                    },
                    icon: const Icon(Icons.copy_rounded),
                  ),
                  if (admin)
                    IconButton(
                      tooltip: tr('Wygeneruj nowy kod', 'Generate new code'),
                      onPressed: () async {
                        final ok = await confirmDialog(
                          context,
                          title: tr('Nowy kod?', 'New code?'),
                          message: tr('Dotychczasowy kod przestanie działać.', 'The current code will stop working.'),
                          confirmLabel: tr('Wygeneruj', 'Generate'),
                        );
                        if (ok && context.mounted) {
                          await _run(context, () => ref.read(repositoryProvider).regenerateInviteCode(group.id));
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tr('Przekaż kod osobom, które chcesz zaprosić (Grupy → Dołącz do grupy).',
                    'Share the code with people you want to invite (Groups → Join a group).'),
                style: context.text.bodySmall?.copyWith(color: context.colors.muted),
              ),
            ],
          ),
        ),
        if (admin) ...[
          SectionLabel(tr('Dane grupy', 'Group details')),
          TextField(
            controller: _name,
            maxLength: 100,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: tr('Nazwa', 'Name'), counterText: ''),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: tr('Opis', 'Description')),
          ),
          SectionLabel(tr('Kolor grupy', 'Group color')),
          ColorGrid(colors: Palette.eventColors, selected: _color, onSelected: (c) => setState(() => _color = c)),
          const SizedBox(height: 16),
          FilledButton(onPressed: _dirty && !_saving ? _save : null, child: Text(tr('Zapisz zmiany', 'Save changes'))),
        ] else if (group.description?.isNotEmpty == true) ...[
          SectionLabel(tr('Opis', 'Description')),
          Text(group.description!, style: context.text.bodyMedium),
        ],
        SectionLabel(tr('Członkostwo', 'Membership')),
        OutlinedButton.icon(
          onPressed: _leave,
          icon: const Icon(Icons.logout_rounded),
          label: Text(tr('Opuść grupę', 'Leave group')),
        ),
        if (admin) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.danger,
              backgroundColor: context.colors.dangerSoft,
              side: BorderSide(color: context.colors.danger.withValues(alpha: 0.25)),
            ),
            onPressed: _delete,
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text(tr('Usuń grupę', 'Delete group')),
          ),
        ],
      ],
    );
  }
}
