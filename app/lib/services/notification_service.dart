import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/dates.dart';
import '../core/l10n.dart';
import '../core/recurrence.dart';
import '../data/local/database.dart';

/// Przypomnienia o wydarzeniach (lokalne, działają bez internetu) i powiadomienia w aplikacji.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Payload klikniętego powiadomienia: `day:2026-08-14` albo `event:<id>:2026-08-14`.
  final _taps = StreamController<String>.broadcast();
  Stream<String> get taps => _taps.stream;
  String? launchPayload;

  static const _remindersChannel = AndroidNotificationDetails(
    'reminders',
    'Przypomnienia',
    channelDescription: 'Przypomnienia o wydarzeniach',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _activityChannel = AndroidNotificationDetails(
    'group_activity',
    'Aktywność w grupach',
    channelDescription: 'Nowe wydarzenia w Twoich grupach',
    importance: Importance.defaultImportance,
  );

  /// Maks. liczba zaplanowanych przypomnień (iOS pozwala na 64).
  static const _maxScheduled = 50;
  static const _horizon = Duration(days: 14);

  Future<void> init() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    try {
      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      debugPrint('Timezone init failed: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _taps.add(payload);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) launchPayload = launch?.notificationResponse?.payload;
    _ready = true;
  }

  Future<bool> requestPermission() async {
    if (!_ready) return false;
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  Future<void> showActivity({required String title, required String body, String? payload}) async {
    if (!_ready) return;
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 30),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: _activityChannel, iOS: DarwinNotificationDetails()),
      payload: payload,
    );
  }

  /// Planuje przypomnienia na najbliższe 14 dni od nowa.
  Future<void> reschedule(List<LocalEvent> events, {required bool enabled, required int defaultMinutes}) async {
    if (!_ready) return;
    await _plugin.cancelAllPendingNotifications();
    if (!enabled) return;

    final now = DateTime.now();
    final from = Dates.dateOnly(now);
    final to = Dates.dateOnly(now.add(_horizon));
    final pending = <(DateTime, Occurrence)>[];

    for (final local in events) {
      final minutes = local.reminderMinutes ?? defaultMinutes;
      if (minutes < 0) continue;
      for (final occ in Recurrence.expand(local.event, from, to)) {
        // Wydarzenia całodniowe: przypomnienie o 9:00.
        final anchor = occ.allDay ? DateTime(occ.start.year, occ.start.month, occ.start.day, 9) : occ.start;
        final fireAt = anchor.subtract(Duration(minutes: minutes));
        if (fireAt.isAfter(now)) pending.add((fireAt, occ));
      }
    }
    pending.sort((a, b) => a.$1.compareTo(b.$1));

    for (final (fireAt, occ) in pending.take(_maxScheduled)) {
      final when = occ.allDay ? tr('Dzisiaj', 'Today') : '${Fmt.dayTitle(occ.start)}, ${Fmt.time(occ.start)}';
      await _plugin.zonedSchedule(
        id: occ.key.hashCode & 0x7fffffff,
        title: occ.title,
        body: when,
        scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
        notificationDetails: const NotificationDetails(android: _remindersChannel, iOS: DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'event:${occ.event.id}:${Dates.key(occ.originalDate)}',
      );
    }
  }

  Future<void> cancelAll() async {
    if (_ready) await _plugin.cancelAll();
  }
}
