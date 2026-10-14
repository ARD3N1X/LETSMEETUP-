import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n.dart';
import '../../../core/palette.dart';
import '../../../core/theme.dart';
import '../../../data/models.dart';
import '../../../data/remote/api_client.dart';
import '../../providers/core_providers.dart';
import '../../widgets/common.dart';

enum _Filter { all, admin, member }

/// Lista grup (prototyp "Manage Groups"). Tap w kartę = zarządzanie grupą — bez osobnych przycisków na karcie.
class GroupsPage extends ConsumerStatefulWidget {
  const GroupsPage({super.key});

  @override
  ConsumerState<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends ConsumerState<GroupsPage> {
  final _search = TextEditingController();
  _Filter _filter = _Filter.all;
  bool _sortByMembers = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsProvider).value ?? const <Group>[];
    final query = _search.text.trim().toLowerCase();
    final admins = groups.where((g) => g.isAdmin).length;

    final visible = groups.where((g) {
      if (_filter == _Filter.admin && !g.isAdmin) return false;
      if (_filter == _Filter.member && g.isAdmin) return false;
      if (query.isEmpty) return true;
      return g.name.toLowerCase().contains(query) || (g.description?.toLowerCase().contains(query) ?? false);
    }).toList()
      ..sort((a, b) => _sortByMembers ? b.memberCount.compareTo(a.memberCount) : a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: tr('Nowa grupa', 'New group'),
        onPressed: () => showCreateGroupSheet(context),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(syncServiceProvider).syncNow(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
                child: Text(tr('Grupy', 'Groups'), style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              ),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: tr('Szukaj grup…', 'Search groups…'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: tr('Wyczyść', 'Clear'),
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(tr('Wszystkie (${groups.length})', 'All (${groups.length})')),
                    selected: _filter == _Filter.all,
                    onSelected: (_) => setState(() => _filter = _Filter.all),
                  ),
                  ChoiceChip(
                    label: Text('Admin ($admins)'),
                    selected: _filter == _Filter.admin,
                    onSelected: (_) => setState(() => _filter = _Filter.admin),
                  ),
                  ChoiceChip(
                    label: Text(tr('Członek (${groups.length - admins})', 'Member (${groups.length - admins})')),
                    selected: _filter == _Filter.member,
                    onSelected: (_) => setState(() => _filter = _Filter.member),
                  ),
                ],
              ),
              SectionLabel(
                tr('Twoje grupy', 'Your groups'),
                trailing: TextButton(
                  onPressed: () => setState(() => _sortByMembers = !_sortByMembers),
                  child: Text(_sortByMembers ? tr('Wg liczby członków', 'By members') : tr('Wg nazwy', 'By name')),
                ),
              ),
              if (groups.isNotEmpty && visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(tr('Brak grup spełniających kryteria.', 'No groups match.'),
                      textAlign: TextAlign.center, style: TextStyle(color: context.colors.muted)),
                ),
              for (final g in visible) ...[
                _GroupCard(group: g, onTap: () => context.push('/groups/${g.id}')),
                const SizedBox(height: 14),
              ],
              _JoinCard(onTap: () => showJoinGroupDialog(context, ref)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.onTap});
  final Group group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Palette.parse(group.color);
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(group.name, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        group.isAdmin
                            ? const TagChip(label: 'Admin', color: Color(0xFFFF8FB1), icon: Icons.shield_outlined)
                            : TagChip(label: tr('Członek', 'Member'), color: const Color(0xFF4FC3F7), icon: Icons.person_outline_rounded),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.group_outlined, size: 16, color: context.colors.muted),
                        const SizedBox(width: 6),
                        Text(
                          tr('Członkowie: ${group.memberCount}', '${group.memberCount} members'),
                          style: context.text.bodySmall?.copyWith(color: context.colors.muted),
                        ),
                      ],
                    ),
                    if (group.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      Text(
                        group.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium?.copyWith(color: context.colors.muted),
                      ),
                    ],
                    const SizedBox(height: 12),
                    AvatarStack(
                      people: [for (final m in group.members) (id: m.userId, name: m.displayName, url: m.avatarUrl)],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinCard extends StatelessWidget {
  const _JoinCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: context.scheme.outline),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Column(
            children: [
              IconBadge(Icons.group_add_outlined, size: 48, color: context.colors.muted),
              const SizedBox(height: 10),
              Text(tr('Dołącz do grupy', 'Join a group'), style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                tr('Masz kod zaproszenia? Wpisz go, aby synchronizować grafik z zespołem.',
                    'Got an invite code? Enter it to sync your schedule with the team.'),
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(color: context.colors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(22)));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

Future<void> showJoinGroupDialog(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  final router = GoRouter.of(context);
  final repo = ref.read(repositoryProvider);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      var loading = false;
      String? error;
      return StatefulBuilder(builder: (context, setState) {
        Future<void> submit() async {
          final code = controller.text.trim();
          if (code.length < 8) {
            setState(() => error = tr('Kod ma 8 znaków', 'The code has 8 characters'));
            return;
          }
          setState(() {
            loading = true;
            error = null;
          });
          try {
            final group = await repo.joinGroup(code);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            showSnack(tr('Dołączyłeś do grupy ${group.name}', 'You joined ${group.name}'));
            router.push('/groups/${group.id}');
          } on ApiException catch (e) {
            setState(() {
              loading = false;
              error = errorMessage(e);
            });
          }
        }

        return AlertDialog(
          title: Text(tr('Dołącz do grupy', 'Join a group')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr('Wpisz 8-znakowy kod otrzymany od admina grupy.', 'Enter the 8-character code from the group admin.')),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 8,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                  TextInputFormatter.withFunction((_, v) => v.copyWith(text: v.text.toUpperCase())),
                ],
                style: context.text.titleLarge?.copyWith(letterSpacing: 6, fontWeight: FontWeight.w700),
                decoration: InputDecoration(counterText: '', hintText: 'ABCD2345', errorText: error),
                onSubmitted: (_) => submit(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(tr('Anuluj', 'Cancel'))),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
              onPressed: loading ? null : submit,
              child: loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(tr('Dołącz', 'Join')),
            ),
          ],
        );
      });
    },
  );
  controller.dispose();
}

Future<void> showCreateGroupSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => const _CreateGroupSheet(),
  );
}

class _CreateGroupSheet extends ConsumerStatefulWidget {
  const _CreateGroupSheet();

  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _color = Palette.defaultGroupColor;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final router = GoRouter.of(context);
    try {
      final description = _description.text.trim();
      final group = await ref.read(repositoryProvider).createGroup(
            name: _name.text.trim(),
            description: description.isEmpty ? null : description,
            color: _color,
          );
      if (!mounted) return;
      Navigator.pop(context);
      router.push('/groups/${group.id}');
    } on ApiException catch (e) {
      showSnack(errorMessage(e));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr('Nowa grupa', 'New group'), style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  tr('Kod zaproszenia wygenerujemy automatycznie.', 'We will generate an invite code automatically.'),
                  style: context.text.bodySmall?.copyWith(color: context.colors.muted),
                ),
                SectionLabel(tr('Nazwa', 'Name')),
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  maxLength: 100,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(hintText: tr('np. Zespół projektowy', 'e.g. Design Team'), counterText: ''),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? tr('Podaj nazwę grupy', 'Enter the group name') : null,
                ),
                SectionLabel(tr('Opis (opcjonalnie)', 'Description (optional)')),
                TextFormField(
                  controller: _description,
                  maxLength: 500,
                  maxLines: 3,
                  minLines: 2,
                  decoration: InputDecoration(hintText: tr('Czym zajmuje się grupa?', 'What is this group about?')),
                ),
                SectionLabel(tr('Kolor grupy', 'Group color')),
                ColorGrid(colors: Palette.eventColors, selected: _color, onSelected: (c) => setState(() => _color = c)),
                const SizedBox(height: 24),
                GradientButton(label: tr('Utwórz grupę', 'Create group'), loading: _saving, onPressed: _create),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
