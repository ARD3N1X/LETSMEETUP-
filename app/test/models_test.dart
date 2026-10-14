import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letsmeetup/core/palette.dart';
import 'package:letsmeetup/data/models.dart';

void main() {
  final base = CalendarEvent(
    id: 'e1',
    title: 'Spotkanie',
    createdById: 'u1',
    startAt: DateTime.utc(2026, 8, 14, 8),
    endAt: DateTime.utc(2026, 8, 14, 9),
    allDay: false,
    color: '#87CEEB',
    recurrence: RecurrenceRule(frequency: Frequency.weekly, byWeekDay: const [5], until: DateTime(2026, 12, 31)),
  );

  test('event JSON round-trip', () {
    final restored = CalendarEvent.fromJson(base.toJson());
    expect(restored.toJson(), base.toJson());
    expect(restored.recurrence!.until, DateTime(2026, 12, 31));
  });

  test('diff contains only changed fields (partial update)', () {
    final changed = base.copyWith(color: '#FDFD96');
    expect(changed.diff(base), {'color': '#FDFD96'});
    expect(base.copyWith(description: 'Opis').diff(base).keys, ['description']);
    expect(base.diff(base), isEmpty);
  });

  test('copyWith can clear nullable fields', () {
    final private = base.copyWith(groupId: null, recurrence: null);
    expect(private.recurrence, isNull);
    expect(private.diff(base), {'recurrence': null});
  });

  test('chip text color keeps readable contrast on pastel colors', () {
    for (final c in Palette.eventColors) {
      final (bg, fg) = Palette.chip(c.color, Brightness.light);
      final surface = Color.alphaBlend(bg, Colors.white);
      final l1 = surface.computeLuminance();
      final l2 = fg.computeLuminance();
      final contrast = (l1 > l2 ? l1 + 0.05 : l2 + 0.05) / (l1 > l2 ? l2 + 0.05 : l1 + 0.05);
      expect(contrast, greaterThan(4.5), reason: '${c.hex} chip text must meet WCAG AA');
    }
  });

  test('hex helpers', () {
    expect(Palette.toHex(Palette.parse('#4fc3f7')), '#4FC3F7');
  });
}
