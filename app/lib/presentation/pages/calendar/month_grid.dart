import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates.dart';
import '../../../core/l10n.dart';
import '../../../core/palette.dart';
import '../../../core/recurrence.dart';
import '../../../core/theme.dart';
import '../../providers/calendar_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/paint_controller.dart';
import 'day_events_sheet.dart';
import 'event_chip.dart';
import 'event_details_sheet.dart';

/// Siatka 7×6 dni miesiąca + obsługa trybu malowania.
///
/// Malowanie działa jednym gestem: przytrzymaj wydarzenie i przeciągnij palcem po dniach
/// (long-press → move → puść), albo po włączeniu trybu ze szczegółów — przeciągnij po siatce.
/// Komórka pod palcem jest wyliczana z pozycji, więc nie ma konfliktu z wieloma DragTargetami.
class MonthGrid extends ConsumerStatefulWidget {
  const MonthGrid({super.key, required this.month, required this.rowHeight});

  final DateTime month;
  final double rowHeight;

  @override
  ConsumerState<MonthGrid> createState() => _MonthGridState();
}

class _MonthGridState extends ConsumerState<MonthGrid> {
  final _gridKey = GlobalKey();

  /// Pozycja palca podczas przeciągania (dla "przyklejonej" miniatury).
  final _pointer = ValueNotifier<Offset?>(null);
  late final List<DateTime> _days = Dates.monthGrid(widget.month);

  @override
  void dispose() {
    _pointer.dispose();
    super.dispose();
  }

  DateTime? _dayAt(Offset globalPosition) {
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(globalPosition);
    if (local.dx < 0 || local.dy < 0 || local.dx >= box.size.width || local.dy >= box.size.height) return null;
    final col = (local.dx / (box.size.width / 7)).floor().clamp(0, 6);
    final row = (local.dy / widget.rowHeight).floor().clamp(0, 5);
    return _days[row * 7 + col];
  }

  void _track(Offset global) {
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) _pointer.value = box.globalToLocal(global);
    final day = _dayAt(global);
    if (day != null) {
      final before = ref.read(paintProvider)?.days.length;
      ref.read(paintProvider.notifier).hover(day);
      if (ref.read(paintProvider)?.days.length != before) HapticFeedback.selectionClick();
    }
  }

  Future<void> _finish() async {
    _pointer.value = null;
    final result = await ref.read(paintProvider.notifier).commit();
    if (result == null) return;
    final mode = ref.read(paintProvider)?.mode ?? PaintMode.move;
    final message = mode == PaintMode.copy || result.count > 1
        ? tr('Utworzono kopie: ${result.count}', 'Copies created: ${result.count}')
        : tr('Przeniesiono wydarzenie', 'Event moved');
    showSnack(
      message,
      duration: const Duration(seconds: 5),
      action: SnackBarAction(label: tr('Cofnij', 'Undo'), onPressed: () => result.undo()),
    );
  }

  void _startPaintFromChip(Occurrence occ, Offset global) {
    HapticFeedback.mediumImpact();
    ref.read(paintProvider.notifier).start(occ, canMove: ref.read(canEditEventProvider(occ.event)));
    _track(global);
  }

  @override
  Widget build(BuildContext context) {
    final occurrences = ref.watch(monthOccurrencesProvider(widget.month));
    final paint = ref.watch(paintProvider);
    final today = Dates.today();

    final grid = Column(
      key: _gridKey,
      children: [
        for (var row = 0; row < 6; row++)
          SizedBox(
            height: widget.rowHeight,
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _DayCell(
                      day: _days[row * 7 + col],
                      inMonth: _days[row * 7 + col].month == widget.month.month,
                      isToday: Dates.sameDay(_days[row * 7 + col], today),
                      occurrences: occurrences[_days[row * 7 + col]] ?? const [],
                      paint: paint,
                      lastColumn: col == 6,
                      onChipLongPressStart: _startPaintFromChip,
                      onChipLongPressMove: _track,
                      onChipLongPressEnd: _finish,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // W trybie malowania cała siatka przechwytuje gest przeciągania. Ten sam rodzic w obu
        // trybach, żeby przytrzymany gest z miniatury nie został przerwany przy wejściu w tryb.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: paint == null ? null : (d) => _track(d.globalPosition),
          onPanUpdate: paint == null ? null : (d) => _track(d.globalPosition),
          onPanEnd: paint == null ? null : (_) => _finish(),
          onTapUp: paint == null
              ? null
              : (d) {
                  _track(d.globalPosition);
                  _finish();
                },
          child: grid,
        ),
        if (paint != null)
          ValueListenableBuilder<Offset?>(
            valueListenable: _pointer,
            builder: (context, pos, _) {
              if (pos == null) return const SizedBox.shrink();
              return Positioned(
                left: pos.dx - 50,
                top: pos.dy - 46,
                width: 100,
                child: IgnorePointer(child: EventChip(occurrence: paint.source, elevated: true, height: 26)),
              );
            },
          ),
      ],
    );
  }
}

class _DayCell extends ConsumerWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.occurrences,
    required this.paint,
    required this.lastColumn,
    required this.onChipLongPressStart,
    required this.onChipLongPressMove,
    required this.onChipLongPressEnd,
  });

  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final List<Occurrence> occurrences;
  final PaintState? paint;
  final bool lastColumn;
  final void Function(Occurrence occ, Offset global) onChipLongPressStart;
  final void Function(Offset global) onChipLongPressMove;
  final VoidCallback onChipLongPressEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final scheme = context.scheme;
    final highlighted = paint?.days.any((d) => Dates.sameDay(d, day)) ?? false;
    final paintColor = paint == null ? null : Palette.parse(paint!.source.color);

    return LayoutBuilder(builder: (context, constraints) {
      const numberArea = 30.0;
      const chipHeight = 17.0;
      const gap = 3.0;
      final capacity = ((constraints.maxHeight - numberArea - 4) / (chipHeight + gap)).floor().clamp(1, 6);
      final overflow = occurrences.length > capacity;
      final visible = occurrences.take(overflow ? capacity - 1 : capacity).toList();
      final showTime = constraints.maxWidth > 80;

      final content = Container(
        decoration: BoxDecoration(
          color: highlighted
              ? Color.alphaBlend(paintColor!.withValues(alpha: 0.30), inMonth ? colors.card : colors.outsideMonthCell)
              : (inMonth ? colors.card.withValues(alpha: 0.6) : colors.outsideMonthCell),
          border: Border(
            right: lastColumn ? BorderSide.none : BorderSide(color: colors.gridLine),
            bottom: BorderSide(color: colors.gridLine),
          ),
        ),
        foregroundDecoration: highlighted
            ? BoxDecoration(border: Border.all(color: Palette.withLightness(paintColor!, 0.5), width: 1.5))
            : null,
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 2),
        child: Column(
          children: [
            SizedBox(
              height: numberArea - 4,
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: isToday ? BoxDecoration(color: scheme.primary, shape: BoxShape.circle) : null,
                  child: Text(
                    '${day.day}',
                    style: context.text.labelMedium?.copyWith(
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                      color: isToday ? scheme.onPrimary : (inMonth ? scheme.onSurface : colors.muted.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
              ),
            ),
            for (final occ in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: gap),
                child: GestureDetector(
                  onTap: paint == null ? () => showEventDetails(context, occ) : null,
                  onLongPressStart: paint == null ? (d) => onChipLongPressStart(occ, d.globalPosition) : null,
                  onLongPressMoveUpdate: (d) => onChipLongPressMove(d.globalPosition),
                  onLongPressEnd: (_) => onChipLongPressEnd(),
                  child: EventChip(
                    occurrence: occ,
                    showTime: showTime,
                    dimmed: paint != null && paint!.source.key == occ.key,
                  ),
                ),
              ),
            if (overflow)
              Text(
                tr('+${occurrences.length - visible.length} więcej', '+${occurrences.length - visible.length} more'),
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: context.text.labelSmall?.copyWith(fontSize: 10, color: colors.muted, fontWeight: FontWeight.w700),
              ),
          ],
        ),
      );

      return Semantics(
        label: '${Fmt.fullDate(day)}, ${tr('wydarzenia', 'events')}: ${occurrences.length}',
        button: true,
        child: InkWell(
          onTap: paint == null ? () => showDayEvents(context, ref, day) : null,
          onLongPress: paint == null ? () => showQuickAdd(context, ref, day) : null,
          child: content,
        ),
      );
    });
  }
}
