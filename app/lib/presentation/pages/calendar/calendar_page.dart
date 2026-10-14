import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config.dart';
import '../../../core/dates.dart';
import '../../../core/l10n.dart';
import '../../../core/palette.dart';
import '../../../core/theme.dart';
import '../../../services/sync_service.dart';
import '../../providers/auth_controller.dart';
import '../../providers/calendar_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/paint_controller.dart';
import '../../widgets/common.dart';
import 'app_drawer.dart';
import 'month_grid.dart';

/// Ekran główny: miesięczna siatka kalendarza (swipe = zmiana miesiąca).
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late final DateTime _origin = ref.read(visibleMonthProvider);
  late final PageController _pages = PageController(initialPage: monthPageOrigin);

  int _pageFor(DateTime month) => monthPageOrigin + (month.year - _origin.year) * 12 + month.month - _origin.month;
  DateTime _monthFor(int page) => Dates.addMonths(_origin, page - monthPageOrigin);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(DateTime month) {
    final target = _pageFor(month);
    final current = _pages.hasClients ? _pages.page?.round() ?? target : target;
    if (current == target) return;
    if ((current - target).abs() > 2) {
      _pages.jumpToPage(target);
    } else {
      _pages.animateToPage(target, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  Future<void> _pickMonth(DateTime month) async {
    final picked = await showDialog<DateTime>(context: context, builder: (_) => _MonthPickerDialog(initial: month));
    if (picked != null) ref.read(visibleMonthProvider.notifier).set(picked);
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(visibleMonthProvider);
    final paint = ref.watch(paintProvider);
    ref.listen(visibleMonthProvider, (_, next) => _goTo(next));

    return Scaffold(
      drawer: const AppDrawer(),
      floatingActionButton: paint != null
          ? null
          : FloatingActionButton(
              tooltip: tr('Dodaj wydarzenie', 'Add event'),
              onPressed: () {
                final today = Dates.today();
                final inMonth = today.year == month.year && today.month == month.month;
                context.push('/event/new?date=${Dates.key(inMonth ? today : month)}');
              },
              child: const Icon(Icons.add_rounded, size: 30),
            ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                const _Header(),
                _MonthBar(
                  month: month,
                  onPrevious: () => ref.read(visibleMonthProvider.notifier).set(Dates.addMonths(month, -1)),
                  onNext: () => ref.read(visibleMonthProvider.notifier).set(Dates.addMonths(month, 1)),
                  onPick: () => _pickMonth(month),
                ),
                Expanded(
                  child: LayoutBuilder(builder: (context, constraints) {
                    final rowHeight = (constraints.maxWidth / 7 * 1.45).clamp(74.0, 124.0);
                    return RefreshIndicator(
                      onRefresh: () => ref.read(syncServiceProvider).syncNow(),
                      notificationPredicate: (_) => paint == null,
                      child: SingleChildScrollView(
                        physics: paint != null ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            const _WeekdayHeader(),
                            SizedBox(
                              height: rowHeight * 6,
                              child: PageView.builder(
                                controller: _pages,
                                physics: paint != null ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
                                onPageChanged: (page) => ref.read(visibleMonthProvider.notifier).set(_monthFor(page)),
                                itemBuilder: (context, page) => MonthGrid(month: _monthFor(page), rowHeight: rowHeight),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: paint != null ? _PaintInfoCard(state: paint) : _MonthOverview(month: month),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            if (paint != null) Positioned(top: 8, left: 0, right: 0, child: Center(child: _PaintModeBar(state: paint))),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 4),
      child: Row(
        children: [
          const AppLogo(size: 36),
          const SizedBox(width: 10),
          Text(AppConfig.appName, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const Spacer(),
          const _SyncIndicator(),
          const SizedBox(width: 6),
          Tooltip(
            message: tr('Profil i grupy', 'Profile and groups'),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: user == null
                    ? const Icon(Icons.account_circle_outlined, size: 40)
                    : Avatar(id: user.id, name: user.displayName, url: user.avatarUrl, size: 40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status synchronizacji widoczny tylko wtedy, gdy jest coś do powiedzenia (offline / zaległe zmiany).
class _SyncIndicator extends ConsumerWidget {
  const _SyncIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: ref.watch(syncStatusProvider),
      builder: (context, status, _) {
        if (status.online && status.pending == 0) return const SizedBox.shrink();
        final offline = !status.online;
        return Tooltip(
          message: offline
              ? tr('Offline — zmiany do wysłania: ${status.pending}', 'Offline — pending changes: ${status.pending}')
              : tr('Synchronizacja…', 'Syncing…'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: offline ? context.colors.dangerSoft : context.scheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(offline ? Icons.cloud_off_rounded : Icons.cloud_sync_outlined,
                    size: 16, color: offline ? context.colors.danger : context.scheme.primary),
                if (status.pending > 0) ...[
                  const SizedBox(width: 4),
                  Text('${status.pending}', style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({required this.month, required this.onPrevious, required this.onNext, required this.onPick});

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrent = now.year == month.year && now.month == month.month;
    return Consumer(builder: (context, ref, _) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 12, 6),
        child: Row(
          children: [
            IconButton(tooltip: tr('Poprzedni miesiąc', 'Previous month'), onPressed: onPrevious, icon: const Icon(Icons.chevron_left_rounded)),
            Expanded(
              child: TextButton(
                onPressed: onPick,
                style: TextButton.styleFrom(foregroundColor: context.scheme.onSurface),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(Fmt.monthYear(month), style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 2),
                    Icon(Icons.expand_more_rounded, size: 20, color: context.colors.muted),
                  ],
                ),
              ),
            ),
            IconButton(tooltip: tr('Następny miesiąc', 'Next month'), onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded)),
            const SizedBox(width: 4),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isCurrent ? 0.45 : 1,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  foregroundColor: context.scheme.primary,
                  backgroundColor: context.scheme.primaryContainer,
                  side: BorderSide(color: context.scheme.primary.withValues(alpha: 0.3)),
                ),
                onPressed: isCurrent ? null : () => ref.read(visibleMonthProvider.notifier).set(DateTime(now.year, now.month)),
                child: Text(tr('Dzisiaj', 'Today')),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.card.withValues(alpha: 0.6),
        border: Border(top: BorderSide(color: context.colors.gridLine), bottom: BorderSide(color: context.colors.gridLine)),
      ),
      child: Row(
        children: [
          for (final (i, name) in Fmt.weekdayShort.indexed)
            Expanded(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: context.text.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: i >= 5 ? context.scheme.primary : context.colors.muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Podsumowanie miesiąca (prototyp "August Overview"): liczba wydarzeń wg kalendarza.
class _MonthOverview extends ConsumerWidget {
  const _MonthOverview({required this.month});
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(monthOccurrencesProvider(month));
    final groups = ref.watch(groupsProvider).value ?? const [];
    final visibility = ref.watch(visibilityProvider).value ?? const {};

    final seen = <String>{};
    final counts = <String?, int>{};
    for (final entry in days.entries) {
      if (entry.key.month != month.month) continue;
      for (final occ in entry.value) {
        if (seen.add(occ.key)) counts[occ.event.groupId] = (counts[occ.event.groupId] ?? 0) + 1;
      }
    }
    final total = seen.length;
    final tiles = <(String, int, Color)>[
      (tr('Prywatne', 'Private'), counts[null] ?? 0, context.colors.muted),
      for (final g in groups)
        if (visibility[g.id] ?? true) (g.name, counts[g.id] ?? 0, Palette.parse(g.color)),
    ];

    return AppCard(
      key: const ValueKey('overview'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('Podsumowanie: ${Fmt.month(month).toLowerCase()}', '${Fmt.month(month)} overview'),
                        style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      total == 0
                          ? tr('Brak zaplanowanych wydarzeń', 'No events scheduled')
                          : tr('Zaplanowane wydarzenia: $total', 'You have $total events scheduled'),
                      style: context.text.bodySmall?.copyWith(color: context.colors.muted),
                    ),
                  ],
                ),
              ),
              IconBadge(Icons.calendar_month_outlined, color: const Color(0xFF77DD77), size: 40),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tiles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final (label, count, color) = tiles[i];
                final dark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  width: 112,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: dark ? 0.16 : 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Palette.withLightness(color, dark ? 0.78 : 0.4),
                        ),
                      ),
                      Text('$count', style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Karta zastępująca podsumowanie w trybie malowania (prototyp "Rapid Scheduling").
class _PaintInfoCard extends StatelessWidget {
  const _PaintInfoCard({required this.state});
  final PaintState state;

  @override
  Widget build(BuildContext context) {
    final copy = state.mode == PaintMode.copy;
    final color = Palette.parse(state.source.color);
    return AppCard(
      key: const ValueKey('paint'),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          IconBadge(Icons.brush_outlined, size: 48, color: color),
          const SizedBox(height: 10),
          Text(tr('Szybkie planowanie', 'Rapid scheduling'), style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            copy
                ? tr('Przeciągnij palcem po dniach, aby skopiować „${state.source.title}”.',
                    'Drag across days to copy "${state.source.title}".')
                : tr('Przeciągnij na dzień, na który chcesz przenieść wydarzenie.', 'Drag to the day you want to move the event to.'),
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: context.colors.muted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: tr('Zaznaczone dni', 'Targeted days'),
                  value: '${state.targets.length}',
                  color: context.scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _Stat(label: tr('Wydarzenie', 'Event'), value: state.source.title, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: Palette.withLightness(color, dark ? 0.78 : 0.38))),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// Pływający pasek trybu malowania: Kopiuj / Przesuń i zakończenie (X).
class _PaintModeBar extends ConsumerWidget {
  const _PaintModeBar({required this.state});
  final PaintState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(paintProvider.notifier);
    const fg = Colors.white;
    Widget option(PaintMode mode, String label) {
      final selected = state.mode == mode;
      final enabled = mode == PaintMode.copy || state.canMove;
      return Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        child: GestureDetector(
          onTap: enabled ? () => controller.setMode(mode) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withValues(alpha: 0.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              label,
              style: TextStyle(color: fg.withValues(alpha: enabled ? 1 : 0.35), fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return Material(
      color: const Color(0xFF1E1F24),
      elevation: 10,
      borderRadius: BorderRadius.circular(26),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.brush_rounded, color: Palette.parse(state.source.color), size: 18),
            const SizedBox(width: 8),
            Text(tr('Malowanie', 'Painting'), style: const TextStyle(color: fg, fontWeight: FontWeight.w800)),
            const SizedBox(width: 10),
            option(PaintMode.copy, tr('Kopiuj', 'Copy')),
            option(PaintMode.move, tr('Przesuń', 'Move')),
            Container(width: 1, height: 22, margin: const EdgeInsets.symmetric(horizontal: 6), color: Colors.white24),
            IconButton(
              tooltip: tr('Zakończ malowanie', 'Stop painting'),
              visualDensity: VisualDensity.compact,
              onPressed: controller.cancel,
              icon: const Icon(Icons.close_rounded, color: fg, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({required this.initial});
  final DateTime initial;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year = widget.initial.year;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      title: Row(
        children: [
          IconButton(onPressed: () => setState(() => _year--), icon: const Icon(Icons.chevron_left_rounded)),
          Expanded(child: Text('$_year', textAlign: TextAlign.center)),
          IconButton(onPressed: () => setState(() => _year++), icon: const Icon(Icons.chevron_right_rounded)),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          childAspectRatio: 2.1,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (var m = 1; m <= 12; m++)
              Builder(builder: (context) {
                final selected = _year == widget.initial.year && m == widget.initial.month;
                final current = _year == now.year && m == now.month;
                return Material(
                  color: selected ? context.scheme.primary : context.scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.pop(context, DateTime(_year, m)),
                    child: Center(
                      child: Text(
                        Fmt.month(DateTime(_year, m)).substring(0, 3),
                        style: TextStyle(
                          fontWeight: current || selected ? FontWeight.w800 : FontWeight.w500,
                          color: selected ? context.scheme.onPrimary : (current ? context.scheme.primary : null),
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, DateTime(now.year, now.month)),
          child: Text(tr('Bieżący miesiąc', 'This month')),
        ),
      ],
    );
  }
}
