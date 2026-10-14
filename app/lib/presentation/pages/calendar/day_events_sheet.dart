import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates.dart';
import '../../../core/l10n.dart';
import '../../../core/palette.dart';
import '../../../core/recurrence.dart';
import '../../../core/theme.dart';
import '../../../data/calendar_repository.dart';
import '../../../data/models.dart';
import '../../providers/auth_controller.dart';
import '../../providers/calendar_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/settings_controller.dart';
import '../../widgets/common.dart';
import 'event_details_sheet.dart';

/// Tap na dzień → lista wydarzeń tego dnia + dodanie wydarzenia na ten dzień.
Future<void> showDayEvents(BuildContext context, WidgetRef ref, DateTime day) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => DayEventsSheet(day: day),
  );
}

class DayEventsSheet extends ConsumerWidget {
  const DayEventsSheet({super.key, required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = DateTime(day.year, day.month);
    final occurrences = ref.watch(monthOccurrencesProvider(month))[day] ?? const <Occurrence>[];
    final groups = ref.watch(groupsByIdProvider);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(Fmt.dayTitle(day), style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                occurrences.isEmpty
                    ? tr('Brak wydarzeń', 'No events')
                    : tr('Wydarzenia: ${occurrences.length}', 'Events: ${occurrences.length}'),
                style: context.text.bodyMedium?.copyWith(color: context.colors.muted),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: occurrences.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => OccurrenceTile(
                    occurrence: occurrences[i],
                    group: groups[occurrences[i].event.groupId],
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      showEventDetails(navigator.context, occurrences[i]);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  final router = GoRouter.of(context);
                  Navigator.pop(context);
                  router.push('/event/new?date=${Dates.key(day)}');
                },
                icon: const Icon(Icons.add_rounded),
                label: Text(tr('Dodaj wydarzenie na ten dzień', 'Add event on this day')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OccurrenceTile extends ConsumerWidget {
  const OccurrenceTile({super.key, required this.occurrence, required this.group, required this.onTap});

  final Occurrence occurrence;
  final Group? group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Palette.parse(occurrence.color);
    final author = ref.watch(membersIndexProvider)[occurrence.event.createdById];
    final me = ref.watch(currentUserProvider);
    final time = occurrence.allDay
        ? tr('Cały dzień', 'All day')
        : occurrence.end == null
            ? Fmt.time(occurrence.start)
            : '${Fmt.time(occurrence.start)} – ${Fmt.time(occurrence.end!)}';

    return AppCard(
      padding: const EdgeInsets.all(12),
      radius: 18,
      onTap: onTap,
      child: Row(
        children: [
          Container(width: 5, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(occurrence.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  [time, group?.name ?? tr('Prywatne', 'Private')].join(' · '),
                  style: context.text.bodySmall?.copyWith(color: context.colors.muted),
                ),
              ],
            ),
          ),
          if (occurrence.event.isRecurring) Icon(Icons.repeat_rounded, size: 16, color: context.colors.muted),
          if (group != null && author != null && occurrence.event.createdById != me?.id) ...[
            const SizedBox(width: 8),
            Avatar(id: author.userId, name: author.displayName, url: author.avatarUrl, size: 26),
          ],
        ],
      ),
    );
  }
}

/// Long-press na dzień → szybkie dodanie wydarzenia (tylko tytuł).
Future<void> showQuickAdd(BuildContext context, WidgetRef ref, DateTime day) async {
  final controller = TextEditingController();
  final action = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tr('Szybkie dodawanie', 'Quick add')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Fmt.fullDate(day), style: TextStyle(color: context.colors.muted)),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: tr('Nazwa wydarzenia…', 'Event name…'), counterText: ''),
            onSubmitted: (_) => Navigator.pop(context, 'save'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, 'more'), child: Text(tr('Więcej opcji', 'More options'))),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
          onPressed: () => Navigator.pop(context, 'save'),
          child: Text(tr('Dodaj', 'Add')),
        ),
      ],
    ),
  );
  final title = controller.text.trim();
  controller.dispose();
  if (!context.mounted || action == null) return;
  if (action == 'more') {
    context.push('/event/new?date=${Dates.key(day)}&title=${Uri.encodeComponent(title)}');
    return;
  }
  if (title.isEmpty) return;
  final me = ref.read(currentUserProvider);
  if (me == null) return;
  final event = CalendarEvent(
    id: CalendarRepository.newId(),
    title: title,
    createdById: me.id,
    startAt: CalendarEvent.toUtcFor(day, true),
    allDay: true,
    color: ref.read(settingsProvider).defaultEventColor,
  );
  await ref.read(repositoryProvider).createEvent(event);
  if (!ref.read(syncStatusProvider).value.online) {
    showSnack(tr('Zapisano lokalnie. Zsynchronizujemy, gdy wróci połączenie.', 'Saved locally. We will sync when you are back online.'));
  }
}
