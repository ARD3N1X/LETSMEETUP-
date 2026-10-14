import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/recurrence.dart';
import '../../data/calendar_repository.dart';
import '../../data/models.dart';
import 'auth_controller.dart';
import 'core_providers.dart';

enum PaintMode { copy, move }

class PaintState {
  const PaintState({required this.source, required this.mode, this.days = const [], this.canMove = true});

  final Occurrence source;
  final PaintMode mode;

  /// Zaznaczone dni w kolejności "malowania".
  final List<DateTime> days;
  final bool canMove;

  /// Dni docelowe (bez dnia źródłowego). W trybie przesuwania — tylko ostatni wskazany dzień.
  List<DateTime> get targets {
    final valid = days.where((d) => !Dates.sameDay(d, source.firstDay)).toList();
    if (mode == PaintMode.move) return valid.isEmpty ? const [] : [valid.last];
    return valid;
  }

  PaintState copyWith({PaintMode? mode, List<DateTime>? days}) =>
      PaintState(source: source, mode: mode ?? this.mode, days: days ?? this.days, canMove: canMove);
}

/// Wynik malowania — pozwala cofnąć operację (SnackBar "Cofnij").
class PaintResult {
  const PaintResult(this.count, this.undo);
  final int count;
  final Future<void> Function() undo;
}

/// Tryb "Malowania": kopiowanie wydarzenia na wiele dni jednym gestem lub przesunięcie na inny dzień.
class PaintController extends Notifier<PaintState?> {
  @override
  PaintState? build() => null;

  bool get isActive => state != null;

  void start(Occurrence source, {required bool canMove}) =>
      state = PaintState(source: source, mode: PaintMode.copy, canMove: canMove);

  void setMode(PaintMode mode) {
    final s = state;
    if (s == null || (mode == PaintMode.move && !s.canMove)) return;
    state = s.copyWith(mode: mode, days: const []);
  }

  void hover(DateTime day) {
    final s = state;
    if (s == null) return;
    if (s.mode == PaintMode.move) {
      if (s.days.isEmpty || !Dates.sameDay(s.days.last, day)) state = s.copyWith(days: [day]);
      return;
    }
    if (s.days.any((d) => Dates.sameDay(d, day))) return;
    state = s.copyWith(days: [...s.days, day]);
  }

  void clearSelection() {
    final s = state;
    if (s != null && s.days.isNotEmpty) state = s.copyWith(days: const []);
  }

  void cancel() => state = null;

  /// Zapisuje wynik malowania. Tryb pozostaje aktywny (można malować dalej) — kończy go "X".
  Future<PaintResult?> commit() async {
    final s = state;
    if (s == null) return null;
    final targets = s.targets;
    state = s.copyWith(days: const []);
    if (targets.isEmpty) return null;

    final repo = ref.read(repositoryProvider);
    final me = ref.read(currentUserProvider);
    if (me == null) return null;
    final occ = s.source;
    final event = occ.event;

    if (s.mode == PaintMode.copy) {
      // Kopie są zawsze pojedynczymi (niepowtarzającymi się) wydarzeniami — sekcja 11.5.
      final copies = [
        for (final day in targets)
          event.copyWith(
            id: CalendarRepository.newId(),
            title: occ.title,
            color: occ.color,
            createdById: me.id,
            recurrence: null,
            exceptions: const [],
            startAt: CalendarEvent.toUtcFor(_shift(occ.start, occ.firstDay, day), event.allDay),
            endAt: occ.end == null ? null : CalendarEvent.toUtcFor(_shift(occ.end!, occ.firstDay, day), event.allDay),
          ),
      ];
      await repo.createEvents(copies);
      return PaintResult(copies.length, () => repo.deleteEvents(copies.map((c) => c.id).toList()));
    }

    // Przesunięcie
    final day = targets.single;
    final newStart = CalendarEvent.toUtcFor(_shift(occ.start, occ.firstDay, day), event.allDay);
    final newEnd = occ.end == null ? null : CalendarEvent.toUtcFor(_shift(occ.end!, occ.firstDay, day), event.allDay);

    if (!event.isRecurring) {
      final moved = event.copyWith(startAt: newStart, endAt: newEnd);
      await repo.updateEvent(event, moved);
      // Źródło wskazuje teraz na nowe położenie — kolejne przesunięcie zaczyna się stamtąd.
      state = null;
      return PaintResult(1, () async {
        final current = (await ref.read(databaseProvider).eventById(event.id))?.event ?? moved;
        await repo.updateEvent(current, current.copyWith(startAt: event.startAt, endAt: event.endAt));
      });
    }

    // Pojedyncze wystąpienie serii → wyjątek (override) w tej serii.
    final previous = event.exceptions.where((x) => Dates.sameDay(x.date, occ.originalDate)).firstOrNull;
    await repo.putException(
      event,
      EventException(
        date: occ.originalDate,
        title: previous?.title,
        color: previous?.color,
        startAt: newStart,
        endAt: newEnd,
      ),
    );
    state = null;
    return PaintResult(1, () async {
      final current = (await ref.read(databaseProvider).eventById(event.id))?.event ?? event;
      if (previous == null) {
        await repo.deleteException(current, occ.originalDate);
      } else {
        await repo.putException(current, previous);
      }
    });
  }

  /// Przenosi datę/godzinę o tyle dni, ile dzieli [fromDay] i [toDay] (z zachowaniem godziny).
  static DateTime _shift(DateTime value, DateTime fromDay, DateTime toDay) {
    final delta = Dates.daysBetween(fromDay, toDay);
    return DateTime(value.year, value.month, value.day + delta, value.hour, value.minute);
  }
}

final paintProvider = NotifierProvider<PaintController, PaintState?>(PaintController.new);
