import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates.dart';
import '../../../core/l10n.dart';
import '../../../core/palette.dart';
import '../../../core/recurrence.dart';
import '../../../core/theme.dart';
import '../../../data/calendar_repository.dart';
import '../../../data/local/database.dart';
import '../../../data/models.dart';
import '../../providers/auth_controller.dart';
import '../../providers/core_providers.dart';
import '../../providers/settings_controller.dart';
import '../../widgets/common.dart';

enum _Repeat { none, daily, weekly, monthly, yearly }

enum _SeriesEnd { never, until, count }

/// Formularz wydarzenia: tworzenie, edycja serii lub edycja pojedynczego wystąpienia serii.
class EventFormPage extends ConsumerStatefulWidget {
  const EventFormPage({super.key, this.initialDate, this.initialTitle, this.eventId, this.occurrenceDate});

  final DateTime? initialDate;
  final String? initialTitle;
  final String? eventId;

  /// Ustawione = edytujemy tylko to wystąpienie serii (wyjątek).
  final DateTime? occurrenceDate;

  @override
  ConsumerState<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends ConsumerState<EventFormPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();

  LocalEvent? _original;
  Occurrence? _occurrence;
  bool _loading = true;
  bool _saving = false;

  bool _allDay = false;
  late DateTime _startDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  late DateTime _endDate;
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  late String _color;
  String? _groupId;
  _Repeat _repeat = _Repeat.none;
  bool _repeatExpanded = false;
  int _interval = 1;
  Set<int> _weekDays = {};
  _SeriesEnd _seriesEnd = _SeriesEnd.never;
  DateTime? _until;
  int _count = 10;

  /// null = domyślne z ustawień, -1 = bez przypomnienia.
  int? _reminder;
  String? _scheduleError;

  bool get _isEdit => widget.eventId != null;
  bool get _isOccurrence => widget.occurrenceDate != null;

  @override
  void initState() {
    super.initState();
    final day = widget.initialDate ?? Dates.today();
    _startDate = day;
    _endDate = day;
    _color = ref.read(settingsProvider).defaultEventColor;
    _title.text = widget.initialTitle ?? '';
    _weekDays = {day.weekday};
    if (_isEdit) {
      _load();
    } else {
      final now = TimeOfDay.now();
      // Najbliższa pełna godzina, jeśli wydarzenie jest na dziś.
      if (Dates.sameDay(day, Dates.today()) && now.hour < 23) {
        _startTime = TimeOfDay(hour: now.hour + 1, minute: 0);
        _endTime = TimeOfDay(hour: (now.hour + 2).clamp(0, 23), minute: now.hour + 2 > 23 ? 59 : 0);
      }
      _loading = false;
    }
  }

  Future<void> _load() async {
    final local = await ref.read(databaseProvider).eventById(widget.eventId!);
    if (!mounted) return;
    if (local == null) {
      Navigator.pop(context);
      showSnack(tr('Wydarzenie zostało usunięte.', 'The event was deleted.'));
      return;
    }
    final e = local.event;
    var start = e.localStart;
    var end = e.localEnd;
    var title = e.title;
    var color = e.color;
    if (_isOccurrence) {
      final occ = Recurrence.expand(e, widget.occurrenceDate!, widget.occurrenceDate!.add(const Duration(days: 40)))
          .where((o) => Dates.sameDay(o.originalDate, widget.occurrenceDate!))
          .firstOrNull;
      if (occ != null) {
        _occurrence = occ;
        start = occ.start;
        end = occ.end;
        title = occ.title;
        color = occ.color;
      }
    }
    setState(() {
      _original = local;
      _title.text = title;
      _description.text = e.description ?? '';
      _location.text = e.location ?? '';
      _allDay = e.allDay;
      _startDate = Dates.dateOnly(start);
      _startTime = TimeOfDay.fromDateTime(start);
      _endDate = Dates.dateOnly(end ?? start);
      _endTime = end == null ? TimeOfDay(hour: (start.hour + 1).clamp(0, 23), minute: start.minute) : TimeOfDay.fromDateTime(end);
      _color = color;
      _groupId = e.groupId;
      _reminder = local.reminderMinutes;
      final rule = e.recurrence;
      if (rule != null) {
        _repeat = _Repeat.values.byName(rule.frequency.name);
        _repeatExpanded = true;
        _interval = rule.interval;
        _weekDays = (rule.byWeekDay ?? [start.weekday]).toSet();
        if (rule.until != null) {
          _seriesEnd = _SeriesEnd.until;
          _until = rule.until;
        } else if (rule.count != null) {
          _seriesEnd = _SeriesEnd.count;
          _count = rule.count!;
        }
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  DateTime get _start => _allDay ? _startDate : DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
  DateTime get _end => _allDay ? _endDate : DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime.hour, _endTime.minute);

  RecurrenceRule? get _rule {
    if (_repeat == _Repeat.none) return null;
    return RecurrenceRule(
      frequency: Frequency.values.byName(_repeat.name),
      interval: _interval,
      until: _seriesEnd == _SeriesEnd.until ? _until : null,
      count: _seriesEnd == _SeriesEnd.count ? _count : null,
      byWeekDay: _repeat == _Repeat.weekly ? (_weekDays.toList()..sort()) : null,
    );
  }

  String? _validateSchedule() {
    if (_end.isBefore(_start)) return tr('Koniec nie może być przed początkiem.', 'The end cannot be before the start.');
    if (_repeat == _Repeat.weekly && _weekDays.isEmpty) return tr('Wybierz co najmniej jeden dzień tygodnia.', 'Pick at least one weekday.');
    if (_repeat != _Repeat.none && _seriesEnd == _SeriesEnd.until) {
      if (_until == null) return tr('Wybierz datę końca serii.', 'Pick the series end date.');
      if (_until!.isBefore(_startDate)) return tr('Koniec serii nie może być przed jej początkiem.', 'The series cannot end before it starts.');
    }
    if (_repeat != _Repeat.none && _seriesEnd == _SeriesEnd.count && _count < 1) {
      return tr('Liczba wystąpień musi być większa od 0.', 'The number of occurrences must be greater than 0.');
    }
    return null;
  }

  Future<void> _save() async {
    final formOk = _form.currentState!.validate();
    final scheduleError = _validateSchedule();
    setState(() => _scheduleError = scheduleError);
    if (!formOk || scheduleError != null) return;

    final me = ref.read(currentUserProvider);
    if (me == null) return;
    setState(() => _saving = true);
    final repo = ref.read(repositoryProvider);
    final description = _description.text.trim();
    final location = _location.text.trim();

    try {
      if (_isOccurrence && _original != null) {
        final event = _original!.event;
        final occ = _occurrence;
        final timesChanged = occ == null || !occ.start.isAtSameMomentAs(_start) || (occ.end != null && !occ.end!.isAtSameMomentAs(_end));
        await repo.putException(
          event,
          EventException(
            date: widget.occurrenceDate!,
            title: _title.text.trim() == event.title ? null : _title.text.trim(),
            color: _color == event.color ? null : _color,
            startAt: timesChanged ? CalendarEvent.toUtcFor(_start, event.allDay) : null,
            endAt: timesChanged ? CalendarEvent.toUtcFor(_end, event.allDay) : null,
          ),
        );
      } else {
        final draft = CalendarEvent(
          id: _original?.event.id ?? CalendarRepository.newId(),
          title: _title.text.trim(),
          description: description.isEmpty ? null : description,
          location: location.isEmpty ? null : location,
          createdById: _original?.event.createdById ?? me.id,
          groupId: _groupId,
          startAt: CalendarEvent.toUtcFor(_start, _allDay),
          endAt: CalendarEvent.toUtcFor(_end, _allDay),
          allDay: _allDay,
          color: _color,
          recurrence: _rule,
          exceptions: _original?.event.exceptions ?? const [],
          version: _original?.event.version ?? 0,
        );
        if (_original == null) {
          await repo.createEvent(draft, reminderMinutes: _reminder);
        } else {
          await repo.updateEvent(_original!.event, draft, reminderMinutes: _reminder, reminderChanged: true);
        }
      }
      if (!mounted) return;
      Navigator.pop(context);
      if (!ref.read(syncStatusProvider).value.online) {
        showSnack(tr('Zapisano lokalnie. Zsynchronizujemy, gdy wróci połączenie.', 'Saved locally. We will sync when you are back online.'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // --- Wybór daty/godziny ---

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        final shift = Dates.daysBetween(_startDate, picked);
        _startDate = picked;
        _endDate = Dates.addDays(_endDate, shift); // zachowaj długość wydarzenia
        if (_repeat == _Repeat.weekly && _weekDays.length == 1) _weekDays = {picked.weekday};
      } else {
        _endDate = picked;
      }
      _scheduleError = null;
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: !L10n.isEnglish),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        final duration = _end.difference(_start);
        _startTime = picked;
        final newEnd = _start.add(duration.isNegative ? const Duration(hours: 1) : duration);
        _endDate = Dates.dateOnly(newEnd);
        _endTime = TimeOfDay.fromDateTime(newEnd);
      } else {
        _endTime = picked;
      }
      _scheduleError = null;
    });
  }

  Future<void> _pickReminder() async {
    final defaultMinutes = ref.read(settingsProvider).defaultReminderMinutes;
    final options = <(int?, String)>[
      (null, tr('Domyślne (${Fmt.minutes(defaultMinutes)})', 'Default (${Fmt.minutes(defaultMinutes)})')),
      (-1, tr('Bez przypomnienia', 'No reminder')),
      for (final m in const [0, 5, 15, 30, 60, 1440]) (m, Fmt.minutes(m)),
    ];
    final picked = await showModalBottomSheet<(int?,)>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final (value, label) in options)
              ListTile(
                title: Text(label),
                trailing: value == _reminder ? Icon(Icons.check_rounded, color: context.scheme.primary) : null,
                onTap: () => Navigator.pop(context, (value,)),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _reminder = picked.$1);
  }

  String get _reminderLabel {
    if (_reminder == null) return tr('Przypomnienie: ${Fmt.minutes(ref.read(settingsProvider).defaultReminderMinutes)}', 'Reminder: ${Fmt.minutes(ref.read(settingsProvider).defaultReminderMinutes)}');
    if (_reminder == -1) return tr('Bez przypomnienia', 'No reminder');
    return tr('Przypomnienie: ${Fmt.minutes(_reminder!)}', 'Reminder: ${Fmt.minutes(_reminder!)}');
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsProvider).value ?? const [];
    final title = _isOccurrence
        ? tr('Edytuj wystąpienie', 'Edit occurrence')
        : _isEdit
            ? tr('Edytuj wydarzenie', 'Edit event')
            : tr('Nowe wydarzenie', 'New event');

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 120,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left_rounded),
          label: Text(tr('Anuluj', 'Cancel')),
          style: TextButton.styleFrom(foregroundColor: context.colors.muted),
        ),
        title: Text(title),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  if (_isOccurrence)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: AppCard(
                        color: context.scheme.primaryContainer,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: context.scheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(tr(
                                'Zmieniasz tylko wystąpienie z dnia ${Fmt.shortDate(widget.occurrenceDate!)}. Pozostałe zostaną bez zmian.',
                                'You are changing only the occurrence on ${Fmt.shortDate(widget.occurrenceDate!)}. Others stay unchanged.',
                              )),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SectionLabel(tr('Szczegóły wydarzenia', 'Event details')),
                  TextFormField(
                    controller: _title,
                    autofocus: !_isEdit && _title.text.isEmpty,
                    maxLength: 200,
                    textCapitalization: TextCapitalization.sentences,
                    style: context.text.titleMedium,
                    decoration: InputDecoration(
                      hintText: tr('Nazwij swoje wydarzenie…', 'Give your event a name…'),
                      counterText: '',
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Palette.parse(_color), shape: BoxShape.circle)),
                      ),
                    ),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? tr('Podaj nazwę wydarzenia', 'Enter the event name') : null,
                  ),
                  SectionLabel(
                    tr('Termin', 'Schedule'),
                    trailing: _isOccurrence
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(tr('Cały dzień', 'All day'), style: context.text.bodySmall),
                              const SizedBox(width: 6),
                              Switch(
                                value: _allDay,
                                onChanged: (v) => setState(() {
                                  _allDay = v;
                                  _scheduleError = null;
                                }),
                              ),
                            ],
                          ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerTile(
                          icon: Icons.calendar_today_outlined,
                          label: tr('Data', 'Date'),
                          value: Fmt.shortDate(_startDate),
                          onTap: () => _pickDate(start: true),
                        ),
                      ),
                      if (!_allDay) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PickerTile(
                            icon: Icons.schedule_rounded,
                            label: tr('Godzina', 'Time'),
                            value: _startTime.format(context),
                            onTap: () => _pickTime(start: true),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerTile(
                          icon: Icons.event_outlined,
                          label: tr('Data końca', 'End date'),
                          value: Fmt.shortDate(_endDate),
                          onTap: () => _pickDate(start: false),
                        ),
                      ),
                      if (!_allDay) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PickerTile(
                            icon: Icons.schedule_rounded,
                            label: tr('Godzina końca', 'End time'),
                            value: _endTime.format(context),
                            onTap: () => _pickTime(start: false),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_scheduleError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 4),
                      child: Text(_scheduleError!, style: TextStyle(color: context.colors.danger)),
                    ),
                  SectionLabel(tr('Kolor etykiety', 'Label color')),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    child: ColorGrid(colors: Palette.eventColors, selected: _color, onSelected: (c) => setState(() => _color = c)),
                  ),
                  if (!_isOccurrence) ...[
                    SectionLabel(tr('Kalendarz', 'Calendar group')),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(tr('Prywatne', 'Private')),
                          avatar: const Icon(Icons.lock_outline_rounded, size: 16),
                          selected: _groupId == null,
                          onSelected: (_) => setState(() => _groupId = null),
                        ),
                        for (final g in groups)
                          ChoiceChip(
                            label: Text(g.name),
                            selected: _groupId == g.id,
                            onSelected: (_) => setState(() => _groupId = g.id),
                          ),
                      ],
                    ),
                    if (_groupId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          tr('Wydarzenie zobaczą wszyscy członkowie grupy.', 'All group members will see this event.'),
                          style: context.text.bodySmall?.copyWith(color: context.colors.muted),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _repeatCard(context),
                  ],
                  const SizedBox(height: 16),
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        if (!_isOccurrence) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: Row(
                              children: [
                                const IconBadge(Icons.place_outlined, color: Color(0xFF77DD77)),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: TextField(
                                    controller: _location,
                                    maxLength: 200,
                                    decoration: InputDecoration(
                                      hintText: tr('Dodaj lokalizację', 'Add location'),
                                      counterText: '',
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(indent: 16, endIndent: 16),
                        ],
                        ListTile(
                          leading: IconBadge(Icons.notifications_none_rounded, color: context.colors.muted),
                          title: Text(_reminderLabel, style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: _pickReminder,
                        ),
                      ],
                    ),
                  ),
                  if (!_isOccurrence) ...[
                    SectionLabel(tr('Opis', 'Description')),
                    TextFormField(
                      controller: _description,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: tr('Dodaj notatki lub szczegóły…', 'Add any notes or details here…'),
                        prefixIcon: const Padding(padding: EdgeInsets.only(bottom: 48), child: Icon(Icons.notes_rounded)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  GradientButton(
                    label: _isEdit ? tr('Zapisz zmiany', 'Save changes') : tr('Utwórz wydarzenie', 'Create event'),
                    loading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _repeatCard(BuildContext context) {
    final options = [
      (_Repeat.none, tr('Nie powtarza się', 'Does not repeat')),
      (_Repeat.daily, tr('Codziennie', 'Daily')),
      (_Repeat.weekly, tr('Co tydzień', 'Weekly')),
      (_Repeat.monthly, tr('Co miesiąc', 'Monthly')),
      (_Repeat.yearly, tr('Co rok', 'Yearly')),
    ];
    final unit = switch (_repeat) {
      _Repeat.daily => tr('dni', 'days'),
      _Repeat.weekly => tr('tyg.', 'weeks'),
      _Repeat.monthly => tr('mies.', 'months'),
      _Repeat.yearly => tr('lat', 'years'),
      _Repeat.none => '',
    };

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            leading: const IconBadge(Icons.repeat_rounded, color: Color(0xFF9FA8DA)),
            title: Text(tr('Powtarzaj', 'Repeat event'), style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            subtitle: Text(_rule == null ? tr('Ustaw częstotliwość', 'Set recurring frequency') : Recurrence.describe(_rule!)),
            trailing: AnimatedRotation(
              turns: _repeatExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.expand_more_rounded),
            ),
            onTap: () => setState(() => _repeatExpanded = !_repeatExpanded),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_repeatExpanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                    child: RadioGroup<_Repeat>(
                      groupValue: _repeat,
                      onChanged: (v) => setState(() {
                        _repeat = v ?? _Repeat.none;
                        _scheduleError = null;
                      }),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Divider(indent: 8, endIndent: 8),
                          for (final (value, label) in options)
                            RadioListTile<_Repeat>(
                              value: value,
                              title: Text(label),
                              controlAffinity: ListTileControlAffinity.trailing,
                              dense: true,
                            ),
                          if (_repeat != _Repeat.none) ...[
                            const Divider(indent: 8, endIndent: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Text(tr('Co', 'Every'), style: context.text.bodyLarge),
                                  const Spacer(),
                                  IconButton.filledTonal(
                                    onPressed: _interval > 1 ? () => setState(() => _interval--) : null,
                                    icon: const Icon(Icons.remove_rounded),
                                  ),
                                  SizedBox(
                                    width: 44,
                                    child: Text('$_interval', textAlign: TextAlign.center, style: context.text.titleMedium),
                                  ),
                                  IconButton.filledTonal(
                                    onPressed: _interval < 99 ? () => setState(() => _interval++) : null,
                                    icon: const Icon(Icons.add_rounded),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(width: 48, child: Text(unit)),
                                ],
                              ),
                            ),
                            if (_repeat == _Repeat.weekly)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    for (var d = 1; d <= 7; d++)
                                      FilterChip(
                                        label: Text(Fmt.weekdayShort[d - 1]),
                                        showCheckmark: false,
                                        selected: _weekDays.contains(d),
                                        onSelected: (on) => setState(() {
                                          on ? _weekDays.add(d) : _weekDays.remove(d);
                                          _scheduleError = null;
                                        }),
                                      ),
                                  ],
                                ),
                              ),
                            const Divider(indent: 8, endIndent: 8),
                            SectionLabel(tr('Koniec serii', 'Series end'), padding: const EdgeInsets.fromLTRB(16, 8, 16, 0)),
                            RadioGroup<_SeriesEnd>(
                              groupValue: _seriesEnd,
                              onChanged: (v) => setState(() {
                                _seriesEnd = v ?? _SeriesEnd.never;
                                if (_seriesEnd == _SeriesEnd.until) _until ??= Dates.addMonths(_startDate, 3);
                                _scheduleError = null;
                              }),
                              child: Column(
                                children: [
                                  RadioListTile<_SeriesEnd>(
                                    value: _SeriesEnd.never,
                                    dense: true,
                                    title: Text(tr('Nigdy', 'Never')),
                                  ),
                                  RadioListTile<_SeriesEnd>(
                                    value: _SeriesEnd.until,
                                    dense: true,
                                    title: Text(tr('Do daty', 'On date')),
                                    secondary: _seriesEnd == _SeriesEnd.until
                                        ? TextButton(
                                            onPressed: () async {
                                              final picked = await showDatePicker(
                                                context: context,
                                                initialDate: _until ?? _startDate,
                                                firstDate: _startDate,
                                                lastDate: DateTime(2100),
                                              );
                                              if (picked != null) setState(() => _until = picked);
                                            },
                                            child: Text(_until == null ? '—' : Fmt.shortDate(_until!)),
                                          )
                                        : null,
                                  ),
                                  RadioListTile<_SeriesEnd>(
                                    value: _SeriesEnd.count,
                                    dense: true,
                                    title: Text(tr('Po liczbie wystąpień', 'After occurrences')),
                                    secondary: _seriesEnd == _SeriesEnd.count
                                        ? SizedBox(
                                            width: 72,
                                            child: TextFormField(
                                              initialValue: '$_count',
                                              keyboardType: TextInputType.number,
                                              textAlign: TextAlign.center,
                                              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(vertical: 8)),
                                              onChanged: (v) => _count = int.tryParse(v) ?? 0,
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.icon, required this.label, required this.value, required this.onTap});
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: context.colors.muted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall?.copyWith(color: context.colors.muted, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
