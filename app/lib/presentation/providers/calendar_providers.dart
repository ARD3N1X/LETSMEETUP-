import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/recurrence.dart';
import '../../data/models.dart';
import 'auth_controller.dart';
import 'core_providers.dart';

class VisibleMonth extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void set(DateTime month) => state = DateTime(month.year, month.month);
}

final visibleMonthProvider = NotifierProvider<VisibleMonth, DateTime>(VisibleMonth.new);

/// Bazowy miesiąc PageView (indeks [monthPageOrigin] = bieżący miesiąc w chwili startu).
const monthPageOrigin = 1200;

/// Wystąpienia wydarzeń w 42-dniowej siatce miesiąca, z uwzględnieniem widoczności grup.
final monthOccurrencesProvider = Provider.family<Map<DateTime, List<Occurrence>>, DateTime>((ref, month) {
  final events = ref.watch(localEventsProvider).value ?? const [];
  final visibility = ref.watch(visibilityProvider).value ?? const {};
  final groups = ref.watch(groupsByIdProvider);
  final days = Dates.monthGrid(month);
  final result = {for (final d in days) d: <Occurrence>[]};

  for (final local in events) {
    final event = local.event;
    final groupId = event.groupId;
    if (groupId != null && (!groups.containsKey(groupId) || visibility[groupId] == false)) continue;
    for (final occ in Recurrence.expand(event, days.first, days.last)) {
      var day = occ.firstDay.isBefore(days.first) ? days.first : occ.firstDay;
      final last = occ.lastDay.isAfter(days.last) ? days.last : occ.lastDay;
      while (!day.isAfter(last)) {
        result[day]?.add(occ);
        day = DateTime(day.year, day.month, day.day + 1);
      }
    }
  }
  for (final list in result.values) {
    list.sort(compareOccurrences);
  }
  return result;
});

int compareOccurrences(Occurrence a, Occurrence b) {
  if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
  final byStart = a.start.compareTo(b.start);
  return byStart != 0 ? byStart : a.title.compareTo(b.title);
}

/// Czy zalogowany użytkownik może edytować/usunąć wydarzenie (autor lub admin grupy).
final canEditEventProvider = Provider.family<bool, CalendarEvent>((ref, event) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return false;
  if (event.groupId == null) return event.createdById == me.id;
  final group = ref.watch(groupsByIdProvider)[event.groupId];
  if (group == null) return false;
  return event.createdById == me.id || group.isAdmin;
});
