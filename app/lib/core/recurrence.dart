import '../data/models.dart';
import 'dates.dart';
import 'l10n.dart';

/// Pojedyncze wystąpienie wydarzenia w kalendarzu (dla serii — wygenerowane z reguły).
class Occurrence {
  const Occurrence({
    required this.event,
    required this.originalDate,
    required this.start,
    required this.end,
    required this.title,
    required this.color,
    this.isOverride = false,
  });

  final CalendarEvent event;

  /// Data wystąpienia wg reguły (klucz wyjątku), lokalna.
  final DateTime originalDate;
  final DateTime start;
  final DateTime? end;
  final String title;
  final String color;
  final bool isOverride;

  bool get allDay => event.allDay;

  DateTime get firstDay => Dates.dateOnly(start);

  /// Ostatni dzień, w którym wystąpienie jest widoczne (koniec o północy nie zajmuje kolejnego dnia).
  DateTime get lastDay {
    final e = end;
    if (e == null) return firstDay;
    if (allDay) return Dates.dateOnly(e);
    final isMidnight = e.hour == 0 && e.minute == 0;
    final day = Dates.dateOnly(e);
    return isMidnight && day.isAfter(firstDay) ? day.subtract(const Duration(days: 1)) : day;
  }

  bool coversDay(DateTime day) => !day.isBefore(firstDay) && !day.isAfter(lastDay);

  String get key => '${event.id}_${Dates.key(originalDate)}';
}

class Recurrence {
  Recurrence._();

  /// Daty wystąpień serii rozpoczynającej się [first], nie późniejsze niż [limit].
  static Iterable<DateTime> dates(DateTime first, RecurrenceRule rule, DateTime limit) sync* {
    final interval = rule.interval < 1 ? 1 : rule.interval;
    final until = rule.until;
    var emitted = 0;
    bool done(DateTime d) =>
        d.isAfter(limit) || (until != null && d.isAfter(until)) || (rule.count != null && emitted >= rule.count!);

    switch (rule.frequency) {
      case Frequency.daily:
        for (var i = 0;; i++) {
          final d = DateTime(first.year, first.month, first.day + i * interval);
          if (done(d)) return;
          emitted++;
          yield d;
        }
      case Frequency.weekly:
        final weekDays = [...(rule.byWeekDay?.isNotEmpty == true ? rule.byWeekDay! : [first.weekday])]..sort();
        final weekStart = Dates.startOfWeek(first);
        for (var w = 0;; w++) {
          final ws = DateTime(weekStart.year, weekStart.month, weekStart.day + 7 * w * interval);
          for (final wd in weekDays) {
            final d = DateTime(ws.year, ws.month, ws.day + wd - 1);
            if (d.isBefore(first)) continue;
            if (done(d)) return;
            emitted++;
            yield d;
          }
        }
      case Frequency.monthly:
        final monthDays = [...(rule.byMonthDay?.isNotEmpty == true ? rule.byMonthDay! : [first.day])]..sort();
        for (var m = 0;; m++) {
          final monthStart = DateTime(first.year, first.month + m * interval, 1);
          if (monthStart.isAfter(limit) || (until != null && monthStart.isAfter(until))) return;
          final length = Dates.daysInMonth(monthStart.year, monthStart.month);
          for (final md in monthDays) {
            if (md > length) continue; // np. 31 w miesiącu 30-dniowym — pomijamy (jak RFC 5545)
            final d = DateTime(monthStart.year, monthStart.month, md);
            if (d.isBefore(first)) continue;
            if (done(d)) return;
            emitted++;
            yield d;
          }
        }
      case Frequency.yearly:
        for (var y = 0;; y++) {
          final year = first.year + y * interval;
          if (DateTime(year).isAfter(limit)) return;
          if (first.month == 2 && first.day == 29 && Dates.daysInMonth(year, 2) == 28) continue;
          final d = DateTime(year, first.month, first.day);
          if (done(d)) return;
          emitted++;
          yield d;
        }
    }
  }

  /// Wystąpienia wydarzenia, które zachodzą na zakres dni [from]–[to] (lokalne daty, włącznie).
  static List<Occurrence> expand(CalendarEvent event, DateTime from, DateTime to) {
    final start = event.localStart;
    final end = event.localEnd;
    final rule = event.recurrence;

    if (rule == null) {
      final occurrence = Occurrence(
        event: event,
        originalDate: Dates.dateOnly(start),
        start: start,
        end: end,
        title: event.title,
        color: event.color,
      );
      return _overlaps(occurrence, from, to) ? [occurrence] : const [];
    }

    final spanDays = end == null ? 0 : Dates.daysBetween(start, end);
    final exceptions = {for (final x in event.exceptions) Dates.key(x.date): x};
    final result = <Occurrence>[];
    // Zapas: przesunięte wystąpienie z następnego tygodnia może trafić do zakresu.
    final limit = to.add(const Duration(days: 7));

    for (final d in dates(Dates.dateOnly(start), rule, limit)) {
      if (DateTime(d.year, d.month, d.day + spanDays).isBefore(from) && exceptions.isEmpty) continue;
      final exception = exceptions[Dates.key(d)];
      if (exception?.cancelled == true) continue;

      var occStart = DateTime(d.year, d.month, d.day, start.hour, start.minute);
      DateTime? occEnd = end == null ? null : DateTime(d.year, d.month, d.day + spanDays, end.hour, end.minute);
      if (exception?.startAt != null) {
        occStart = event.allDay ? Dates.allDayToLocal(exception!.startAt!) : exception!.startAt!.toLocal();
        if (exception.endAt != null) {
          occEnd = event.allDay ? Dates.allDayToLocal(exception.endAt!) : exception.endAt!.toLocal();
        } else if (occEnd != null) {
          occEnd = occStart.add(event.endAt!.difference(event.startAt));
        }
      }

      final occurrence = Occurrence(
        event: event,
        originalDate: d,
        start: occStart,
        end: occEnd,
        title: exception?.title ?? event.title,
        color: exception?.color ?? event.color,
        isOverride: exception != null,
      );
      if (_overlaps(occurrence, from, to)) result.add(occurrence);
    }
    return result;
  }

  static bool _overlaps(Occurrence o, DateTime from, DateTime to) =>
      !o.lastDay.isBefore(from) && !o.firstDay.isAfter(to);

  /// "Co tydzień: pn, śr" / "Every 2 weeks on Mon, Wed".
  static String describe(RecurrenceRule rule) {
    final n = rule.interval;
    String base;
    switch (rule.frequency) {
      case Frequency.daily:
        base = n == 1 ? tr('Codziennie', 'Every day') : tr('Co $n dni', 'Every $n days');
      case Frequency.weekly:
        base = n == 1 ? tr('Co tydzień', 'Every week') : tr('Co $n tyg.', 'Every $n weeks');
        final days = rule.byWeekDay;
        if (days != null && days.isNotEmpty) {
          final names = ([...days]..sort()).map((d) => Fmt.weekdayShort[d - 1]).join(', ');
          base = '$base ${tr('w dni', 'on')}: $names';
        }
      case Frequency.monthly:
        base = n == 1 ? tr('Co miesiąc', 'Every month') : tr('Co $n mies.', 'Every $n months');
      case Frequency.yearly:
        base = n == 1 ? tr('Co rok', 'Every year') : tr('Co $n lata', 'Every $n years');
    }
    if (rule.until != null) return '$base, ${tr('do', 'until')} ${Fmt.shortDate(rule.until!)}';
    if (rule.count != null) return '$base, ${tr('${rule.count} razy', '${rule.count} times')}';
    return base;
  }
}
