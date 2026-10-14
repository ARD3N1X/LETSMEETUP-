import 'dart:convert';

import '../core/dates.dart';

DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String).toUtc();

class UserSettings {
  const UserSettings({
    this.themeMode = 'system',
    this.accentColor = '#4FC3F7',
    this.defaultEventColor = '#87CEEB',
    this.language = 'pl',
    this.pushEnabled = true,
    this.remindersEnabled = true,
    this.defaultReminderMinutes = 15,
  });

  final String themeMode;
  final String accentColor;
  final String defaultEventColor;
  final String language;
  final bool pushEnabled;
  final bool remindersEnabled;
  final int defaultReminderMinutes;

  factory UserSettings.fromJson(Map<String, dynamic> j) => UserSettings(
        themeMode: j['themeMode'] as String? ?? 'system',
        accentColor: j['accentColor'] as String? ?? '#4FC3F7',
        defaultEventColor: j['defaultEventColor'] as String? ?? '#87CEEB',
        language: j['language'] as String? ?? 'pl',
        pushEnabled: j['pushEnabled'] as bool? ?? true,
        remindersEnabled: j['remindersEnabled'] as bool? ?? true,
        defaultReminderMinutes: j['defaultReminderMinutes'] as int? ?? 15,
      );

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'accentColor': accentColor,
        'defaultEventColor': defaultEventColor,
        'language': language,
        'pushEnabled': pushEnabled,
        'remindersEnabled': remindersEnabled,
        'defaultReminderMinutes': defaultReminderMinutes,
      };

  UserSettings copyWith({
    String? themeMode,
    String? accentColor,
    String? defaultEventColor,
    String? language,
    bool? pushEnabled,
    bool? remindersEnabled,
    int? defaultReminderMinutes,
  }) =>
      UserSettings(
        themeMode: themeMode ?? this.themeMode,
        accentColor: accentColor ?? this.accentColor,
        defaultEventColor: defaultEventColor ?? this.defaultEventColor,
        language: language ?? this.language,
        pushEnabled: pushEnabled ?? this.pushEnabled,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        defaultReminderMinutes: defaultReminderMinutes ?? this.defaultReminderMinutes,
      );
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.settings,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final UserSettings settings;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        email: j['email'] as String,
        displayName: j['displayName'] as String,
        avatarUrl: j['avatarUrl'] as String?,
        settings: UserSettings.fromJson((j['settings'] as Map?)?.cast<String, dynamic>() ?? const {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'settings': settings.toJson(),
      };

  AppUser copyWith({String? displayName, UserSettings? settings}) => AppUser(
        id: id,
        email: email,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl,
        settings: settings ?? this.settings,
      );
}

enum GroupRole { admin, member }

class GroupMember {
  const GroupMember({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final GroupRole role;
  final DateTime joinedAt;

  bool get isAdmin => role == GroupRole.admin;

  factory GroupMember.fromJson(Map<String, dynamic> j) => GroupMember(
        userId: j['userId'] as String,
        displayName: j['displayName'] as String,
        avatarUrl: j['avatarUrl'] as String?,
        role: j['role'] == 'admin' ? GroupRole.admin : GroupRole.member,
        joinedAt: _date(j['joinedAt']) ?? DateTime.now().toUtc(),
      );
}

class Group {
  const Group({
    required this.id,
    required this.name,
    required this.color,
    required this.inviteCode,
    required this.createdById,
    required this.myRole,
    required this.members,
    required this.json,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
  final String color;
  final String inviteCode;
  final String createdById;
  final GroupRole myRole;
  final List<GroupMember> members;

  /// Oryginalny JSON (do zapisu w lokalnej bazie).
  final Map<String, dynamic> json;

  bool get isAdmin => myRole == GroupRole.admin;
  int get memberCount => members.length;

  factory Group.fromJson(Map<String, dynamic> j) => Group(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        color: j['color'] as String? ?? '#F49AC2',
        inviteCode: j['inviteCode'] as String? ?? '',
        createdById: j['createdById'] as String? ?? '',
        myRole: j['myRole'] == 'admin' ? GroupRole.admin : GroupRole.member,
        members: ((j['members'] as List?) ?? const [])
            .map((m) => GroupMember.fromJson((m as Map).cast<String, dynamic>()))
            .toList(),
        json: j,
      );
}

enum Frequency { daily, weekly, monthly, yearly }

class RecurrenceRule {
  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.until,
    this.count,
    this.byWeekDay,
    this.byMonthDay,
  });

  final Frequency frequency;
  final int interval;

  /// Ostatni dzień serii (włącznie), lokalna data.
  final DateTime? until;
  final int? count;

  /// ISO: 1 = poniedziałek … 7 = niedziela.
  final List<int>? byWeekDay;
  final List<int>? byMonthDay;

  factory RecurrenceRule.fromJson(Map<String, dynamic> j) => RecurrenceRule(
        frequency: Frequency.values.byName(j['freq'] as String),
        interval: j['interval'] as int? ?? 1,
        until: j['until'] == null ? null : Dates.parseKey(j['until'] as String),
        count: j['count'] as int?,
        byWeekDay: (j['byWeekDay'] as List?)?.cast<int>(),
        byMonthDay: (j['byMonthDay'] as List?)?.cast<int>(),
      );

  Map<String, dynamic> toJson() => {
        'freq': frequency.name,
        'interval': interval,
        if (until != null) 'until': Dates.key(until!),
        if (count != null) 'count': count,
        if (byWeekDay != null && byWeekDay!.isNotEmpty) 'byWeekDay': byWeekDay,
        if (byMonthDay != null && byMonthDay!.isNotEmpty) 'byMonthDay': byMonthDay,
      };
}

class EventException {
  const EventException({required this.date, this.cancelled = false, this.title, this.color, this.startAt, this.endAt});

  /// Oryginalna data wystąpienia (lokalna).
  final DateTime date;
  final bool cancelled;
  final String? title;
  final String? color;
  final DateTime? startAt;
  final DateTime? endAt;

  factory EventException.fromJson(Map<String, dynamic> j) => EventException(
        date: Dates.parseKey(j['date'] as String),
        cancelled: j['cancelled'] as bool? ?? false,
        title: j['title'] as String?,
        color: j['color'] as String?,
        startAt: _date(j['startAt']),
        endAt: _date(j['endAt']),
      );

  Map<String, dynamic> toJson() => {
        'date': Dates.key(date),
        'cancelled': cancelled,
        'title': title,
        'color': color,
        'startAt': startAt?.toIso8601String(),
        'endAt': endAt?.toIso8601String(),
      };
}

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.createdById,
    required this.startAt,
    required this.allDay,
    required this.color,
    this.description,
    this.location,
    this.groupId,
    this.endAt,
    this.recurrence,
    this.exceptions = const [],
    this.version = 0,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? location;
  final String createdById;
  final String? groupId;

  /// UTC. Dla [allDay] — północ UTC dnia kalendarzowego.
  final DateTime startAt;
  final DateTime? endAt;
  final bool allDay;
  final String color;
  final RecurrenceRule? recurrence;
  final List<EventException> exceptions;
  final int version;
  final DateTime? updatedAt;

  bool get isRecurring => recurrence != null;
  bool get isPrivate => groupId == null;

  /// Początek w lokalnej strefie czasowej.
  DateTime get localStart => allDay ? Dates.allDayToLocal(startAt) : startAt.toLocal();

  /// Koniec w lokalnej strefie (dla całodniowych — ostatni dzień, włącznie).
  DateTime? get localEnd => endAt == null ? null : (allDay ? Dates.allDayToLocal(endAt!) : endAt!.toLocal());

  static DateTime toUtcFor(DateTime local, bool allDay) => allDay ? Dates.allDayToUtc(local) : local.toUtc();

  factory CalendarEvent.fromJson(Map<String, dynamic> j) => CalendarEvent(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        location: j['location'] as String?,
        createdById: j['createdById'] as String,
        groupId: j['groupId'] as String?,
        startAt: _date(j['startAt'])!,
        endAt: _date(j['endAt']),
        allDay: j['allDay'] as bool? ?? false,
        color: j['color'] as String? ?? '#87CEEB',
        recurrence: j['recurrence'] == null
            ? null
            : RecurrenceRule.fromJson((j['recurrence'] as Map).cast<String, dynamic>()),
        exceptions: ((j['exceptions'] as List?) ?? const [])
            .map((e) => EventException.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        version: j['version'] as int? ?? 0,
        updatedAt: _date(j['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'location': location,
        'createdById': createdById,
        'groupId': groupId,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt?.toIso8601String(),
        'allDay': allDay,
        'color': color,
        'recurrence': recurrence?.toJson(),
        'exceptions': exceptions.map((e) => e.toJson()).toList(),
        'version': version,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  /// Pola wysyłane przy tworzeniu (POST /events).
  Map<String, dynamic> toCreatePayload() => {
        'id': id,
        'title': title,
        'description': description,
        'location': location,
        'groupId': groupId,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt?.toIso8601String(),
        'allDay': allDay,
        'color': color,
        'recurrence': recurrence?.toJson(),
      };

  /// Pola różniące się od [other] — dla PATCH (zmiana tylko zmienionych pól).
  Map<String, dynamic> diff(CalendarEvent other) {
    final a = toCreatePayload();
    final b = other.toCreatePayload();
    final result = <String, dynamic>{};
    for (final key in a.keys) {
      if (key == 'id') continue;
      if (jsonEncode(a[key]) != jsonEncode(b[key])) result[key] = a[key];
    }
    return result;
  }

  CalendarEvent copyWith({
    String? title,
    Object? description = _keep,
    Object? location = _keep,
    Object? groupId = _keep,
    DateTime? startAt,
    Object? endAt = _keep,
    bool? allDay,
    String? color,
    Object? recurrence = _keep,
    List<EventException>? exceptions,
    String? createdById,
    String? id,
  }) =>
      CalendarEvent(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description == _keep ? this.description : description as String?,
        location: location == _keep ? this.location : location as String?,
        createdById: createdById ?? this.createdById,
        groupId: groupId == _keep ? this.groupId : groupId as String?,
        startAt: startAt ?? this.startAt,
        endAt: endAt == _keep ? this.endAt : endAt as DateTime?,
        allDay: allDay ?? this.allDay,
        color: color ?? this.color,
        recurrence: recurrence == _keep ? this.recurrence : recurrence as RecurrenceRule?,
        exceptions: exceptions ?? this.exceptions,
        version: version,
        updatedAt: updatedAt,
      );
}

const _keep = Object();
