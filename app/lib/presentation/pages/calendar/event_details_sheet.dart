import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates.dart';
import '../../../core/l10n.dart';
import '../../../core/palette.dart';
import '../../../core/recurrence.dart';
import '../../../core/theme.dart';
import '../../../data/local/database.dart';
import '../../../data/models.dart';
import '../../providers/auth_controller.dart';
import '../../providers/calendar_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/paint_controller.dart';
import '../../widgets/common.dart';

Future<void> showEventDetails(BuildContext context, Occurrence occurrence) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: false,
    builder: (_) => EventDetailsSheet(occurrence: occurrence),
  );
}

/// Otwiera szczegóły wydarzenia po id (np. z powiadomienia).
Future<void> showEventDetailsById(BuildContext context, AppDatabase db, String id, DateTime date) async {
  final local = await db.eventById(id);
  if (local == null || !context.mounted) return;
  final occurrences = Recurrence.expand(local.event, date, date);
  final occurrence = occurrences.where((o) => Dates.sameDay(o.originalDate, date)).firstOrNull ??
      occurrences.firstOrNull ??
      Recurrence.expand(local.event, local.event.localStart, local.event.localStart).firstOrNull;
  if (occurrence == null) return;
  await showEventDetails(context, occurrence);
}

/// Szczegóły wydarzenia: kolorowy nagłówek, autor, termin, powtarzalność, opis, grupa
/// oraz jedyne miejsce akcji Edytuj / Maluj / Usuń.
class EventDetailsSheet extends ConsumerWidget {
  const EventDetailsSheet({super.key, required this.occurrence});
  final Occurrence occurrence;

  CalendarEvent get event => occurrence.event;

  String _when() {
    final start = occurrence.start;
    final end = occurrence.end;
    if (occurrence.allDay) {
      if (end == null || Dates.sameDay(start, end)) return '${Fmt.fullDate(start)} · ${tr('cały dzień', 'all day')}';
      return '${Fmt.fullDate(start)} – ${Fmt.fullDate(end)}';
    }
    if (end == null) return '${Fmt.fullDate(start)}, ${Fmt.time(start)}';
    if (Dates.sameDay(start, end)) return '${Fmt.fullDate(start)}, ${Fmt.time(start)} – ${Fmt.time(end)}';
    return '${Fmt.fullDate(start)}, ${Fmt.time(start)} – ${Fmt.fullDate(end)}, ${Fmt.time(end)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Palette.parse(occurrence.color);
    final group = ref.watch(groupsByIdProvider)[event.groupId];
    final author = ref.watch(membersIndexProvider)[event.createdById];
    final me = ref.watch(currentUserProvider);
    final canEdit = ref.watch(canEditEventProvider(event));
    final headerFg = Palette.onColor(color);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 120,
              padding: const EdgeInsets.fromLTRB(22, 16, 12, 16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          occurrence.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.headlineSmall?.copyWith(color: headerFg, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Fmt.dayTitle(occurrence.start),
                          style: context.text.bodyMedium?.copyWith(color: headerFg.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: tr('Zamknij', 'Close'),
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: headerFg),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (group != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          Avatar(
                            id: event.createdById,
                            name: author?.displayName ?? '?',
                            url: author?.avatarUrl,
                            size: 34,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              event.createdById == me?.id
                                  ? tr('Dodane przez Ciebie', 'Added by you')
                                  : tr('Dodane przez ${author?.displayName ?? 'byłego członka'}',
                                      'Added by ${author?.displayName ?? 'a former member'}'),
                              style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          TagChip(label: group.name, color: Palette.parse(group.color)),
                        ],
                      ),
                    ),
                  _InfoRow(icon: Icons.schedule_rounded, text: _when()),
                  if (event.recurrence != null)
                    _InfoRow(icon: Icons.repeat_rounded, text: Recurrence.describe(event.recurrence!)),
                  if (event.location?.isNotEmpty == true) _InfoRow(icon: Icons.place_outlined, text: event.location!),
                  if (group == null) _InfoRow(icon: Icons.lock_outline_rounded, text: tr('Prywatne — widoczne tylko dla Ciebie', 'Private — only visible to you')),
                  if (event.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(event.description!, style: context.text.bodyMedium),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (canEdit)
                    _ActionButton(
                      icon: Icons.edit_outlined,
                      label: tr('Edytuj', 'Edit'),
                      onTap: () => _edit(context),
                    ),
                  _ActionButton(
                    icon: Icons.brush_outlined,
                    label: tr('Maluj po kalendarzu', 'Paint'),
                    onTap: () {
                      ref.read(paintProvider.notifier).start(occurrence, canMove: canEdit);
                      Navigator.pop(context);
                    },
                  ),
                  if (canEdit)
                    _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: tr('Usuń', 'Delete'),
                      danger: true,
                      onTap: () => _delete(context, ref),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    var onlyThis = false;
    if (event.isRecurring) {
      final choice = await choiceSheet<bool>(
        context,
        title: tr('Edytuj wydarzenie cykliczne', 'Edit recurring event'),
        options: [
          (true, tr('Tylko to wystąpienie', 'This occurrence only'), Icons.event_outlined),
          (false, tr('Cała seria', 'The whole series'), Icons.repeat_rounded),
        ],
      );
      if (choice == null) return;
      onlyThis = choice;
    }
    if (!context.mounted) return;
    final router = GoRouter.of(context);
    Navigator.pop(context);
    router.push(
      onlyThis
          ? '/event/${event.id}/edit?occurrence=${Dates.key(occurrence.originalDate)}'
          : '/event/${event.id}/edit',
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    // Arkusz zostanie zamknięty — zależności pobieramy przed pop (ref przestanie być ważny).
    final repo = ref.read(repositoryProvider);
    final db = ref.read(databaseProvider);
    if (event.isRecurring) {
      final choice = await choiceSheet<bool>(
        context,
        destructive: true,
        title: tr('Usuń wydarzenie cykliczne', 'Delete recurring event'),
        options: [
          (true, tr('Usuń to wydarzenie', 'Delete this occurrence'), Icons.event_busy_outlined),
          (false, tr('Usuń całą serię', 'Delete the whole series'), Icons.delete_sweep_outlined),
        ],
      );
      if (choice == null || !context.mounted) return;
      Navigator.pop(context);
      if (choice) {
        await repo.putException(event, EventException(date: occurrence.originalDate, cancelled: true));
        showSnack(
          tr('Usunięto wystąpienie', 'Occurrence deleted'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: tr('Cofnij', 'Undo'),
            onPressed: () async {
              final current = (await db.eventById(event.id))?.event;
              if (current != null) await repo.deleteException(current, occurrence.originalDate);
            },
          ),
        );
      } else {
        await repo.deleteEvent(event.id);
        showSnack(tr('Usunięto serię', 'Series deleted'));
      }
      return;
    }

    final confirmed = await confirmDialog(
      context,
      title: tr('Usunąć wydarzenie?', 'Delete event?'),
      message: event.groupId == null
          ? tr('„${event.title}” zostanie usunięte.', '"${event.title}" will be deleted.')
          : tr('„${event.title}” zniknie z kalendarzy wszystkich członków grupy.',
              '"${event.title}" will disappear from all group members\' calendars.'),
      confirmLabel: tr('Usuń', 'Delete'),
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    Navigator.pop(context);
    await repo.deleteEvent(event.id);
    showSnack(
      tr('Usunięto wydarzenie', 'Event deleted'),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(label: tr('Cofnij', 'Undo'), onPressed: () => repo.createEvent(event)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: context.colors.muted),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: context.text.bodyMedium)),
          ],
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.danger = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? context.colors.danger : context.scheme.primary;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: danger ? context.colors.dangerSoft : context.scheme.primaryContainer,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              child: Column(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
