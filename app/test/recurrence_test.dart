import 'package:flutter_test/flutter_test.dart';
import 'package:letsmeetup/core/dates.dart';
import 'package:letsmeetup/core/recurrence.dart';
import 'package:letsmeetup/data/models.dart';

CalendarEvent event({
  required DateTime start,
  DateTime? end,
  bool allDay = false,
  RecurrenceRule? rule,
  List<EventException> exceptions = const [],
}) =>
    CalendarEvent(
      id: 'e1',
      title: 'Test',
      createdById: 'u1',
      startAt: CalendarEvent.toUtcFor(start, allDay),
      endAt: end == null ? null : CalendarEvent.toUtcFor(end, allDay),
      allDay: allDay,
      color: '#87CEEB',
      recurrence: rule,
      exceptions: exceptions,
    );

List<DateTime> days(Iterable<Occurrence> list) => list.map((o) => o.firstDay).toList();

void main() {
  final aug1 = DateTime(2026, 8, 1);
  final aug31 = DateTime(2026, 8, 31);

  test('single event appears only on its day', () {
    final e = event(start: DateTime(2026, 8, 14, 10), end: DateTime(2026, 8, 14, 11));
    expect(days(Recurrence.expand(e, aug1, aug31)), [DateTime(2026, 8, 14)]);
    expect(Recurrence.expand(e, DateTime(2026, 9, 1), DateTime(2026, 9, 30)), isEmpty);
  });

  test('daily with interval and count', () {
    final e = event(
      start: DateTime(2026, 8, 1, 9),
      rule: const RecurrenceRule(frequency: Frequency.daily, interval: 2, count: 4),
    );
    expect(days(Recurrence.expand(e, aug1, aug31)), [
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 3),
      DateTime(2026, 8, 5),
      DateTime(2026, 8, 7),
    ]);
  });

  test('weekly on selected ISO weekdays until a date (inclusive)', () {
    // 3.08.2026 to poniedziałek.
    final e = event(
      start: DateTime(2026, 8, 3, 18),
      rule: RecurrenceRule(frequency: Frequency.weekly, byWeekDay: const [1, 3], until: DateTime(2026, 8, 12)),
    );
    expect(days(Recurrence.expand(e, aug1, aug31)), [
      DateTime(2026, 8, 3),
      DateTime(2026, 8, 5),
      DateTime(2026, 8, 10),
      DateTime(2026, 8, 12),
    ]);
  });

  test('monthly on the 31st skips shorter months', () {
    final e = event(start: DateTime(2026, 1, 31, 12), rule: const RecurrenceRule(frequency: Frequency.monthly));
    final result = days(Recurrence.expand(e, DateTime(2026, 1, 1), DateTime(2026, 5, 31)));
    expect(result, [DateTime(2026, 1, 31), DateTime(2026, 3, 31), DateTime(2026, 5, 31)]);
  });

  test('yearly on Feb 29 occurs only in leap years', () {
    final e = event(start: DateTime(2028, 2, 29), allDay: true, rule: const RecurrenceRule(frequency: Frequency.yearly));
    final result = days(Recurrence.expand(e, DateTime(2028, 1, 1), DateTime(2033, 12, 31)));
    expect(result, [DateTime(2028, 2, 29), DateTime(2032, 2, 29)]);
  });

  test('cancelled and overridden occurrences', () {
    final e = event(
      start: DateTime(2026, 8, 3, 10),
      end: DateTime(2026, 8, 3, 11),
      rule: const RecurrenceRule(frequency: Frequency.weekly),
      exceptions: [
        EventException(date: DateTime(2026, 8, 10), cancelled: true),
        EventException(date: DateTime(2026, 8, 17), title: 'Przesunięte', startAt: DateTime(2026, 8, 18, 15).toUtc()),
      ],
    );
    final result = Recurrence.expand(e, aug1, aug31);
    expect(days(result), [DateTime(2026, 8, 3), DateTime(2026, 8, 18), DateTime(2026, 8, 24), DateTime(2026, 8, 31)]);
    final moved = result[1];
    expect(moved.title, 'Przesunięte');
    expect(moved.originalDate, DateTime(2026, 8, 17));
    expect(moved.start, DateTime(2026, 8, 18, 15));
    expect(moved.end, DateTime(2026, 8, 18, 16), reason: 'keeps the original duration');
  });

  test('count includes cancelled occurrences (RFC 5545)', () {
    final e = event(
      start: DateTime(2026, 8, 1),
      allDay: true,
      rule: const RecurrenceRule(frequency: Frequency.daily, count: 3),
      exceptions: [EventException(date: DateTime(2026, 8, 2), cancelled: true)],
    );
    expect(days(Recurrence.expand(e, aug1, aug31)), [DateTime(2026, 8, 1), DateTime(2026, 8, 3)]);
  });

  test('multi-day events span every covered day; midnight end does not spill over', () {
    final multi = event(start: DateTime(2026, 8, 14, 20), end: DateTime(2026, 8, 16, 10));
    final occ = Recurrence.expand(multi, aug1, aug31).single;
    expect(occ.coversDay(DateTime(2026, 8, 15)), isTrue);
    expect(occ.lastDay, DateTime(2026, 8, 16));

    final untilMidnight = event(start: DateTime(2026, 8, 14, 22), end: DateTime(2026, 8, 15));
    expect(Recurrence.expand(untilMidnight, aug1, aug31).single.lastDay, DateTime(2026, 8, 14));
  });

  test('all-day dates are not shifted by time zones', () {
    final e = event(start: DateTime(2026, 8, 14), allDay: true);
    expect(e.startAt, DateTime.utc(2026, 8, 14));
    expect(e.localStart, DateTime(2026, 8, 14));
  });

  test('describe produces readable text', () {
    const rule = RecurrenceRule(frequency: Frequency.weekly, byWeekDay: [3]);
    expect(Recurrence.describe(rule), contains('Co tydzień'));
    expect(Recurrence.describe(rule), contains('Śr'));
  });

  test('month grid starts on Monday and has 42 days', () {
    final grid = Dates.monthGrid(DateTime(2026, 8));
    expect(grid, hasLength(42));
    expect(grid.first.weekday, DateTime.monday);
    expect(grid.first, DateTime(2026, 7, 27));
  });
}
