import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config.dart';
import 'core/dates.dart';
import 'core/l10n.dart';
import 'core/theme.dart';
import 'presentation/pages/calendar/event_details_sheet.dart';
import 'presentation/providers/auth_controller.dart';
import 'presentation/providers/calendar_providers.dart';
import 'presentation/providers/core_providers.dart';
import 'presentation/providers/settings_controller.dart';
import 'presentation/router.dart';
import 'services/sync_service.dart';

class LetsMeetUpApp extends ConsumerWidget {
  const LetsMeetUpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final accent = ref.watch(accentColorProvider);
    final language = ref.watch(settingsProvider.select((s) => s.language));

    return MaterialApp.router(
      // Zmiana języka przebudowuje całe drzewo (teksty z tr()).
      key: ValueKey(language),
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: router,
      themeMode: ref.watch(themeModeProvider),
      theme: AppTheme.build(Brightness.light, accent),
      darkTheme: AppTheme.build(Brightness.dark, accent),
      locale: Locale(language),
      supportedLocales: const [Locale('pl'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => SessionScope(child: child ?? const SizedBox()),
    );
  }
}

/// Spina sesję z usługami: synchronizacja, push, przypomnienia, komunikaty i nawigacja z powiadomień.
class SessionScope extends ConsumerStatefulWidget {
  const SessionScope({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SessionScope> createState() => _SessionScopeState();
}

class _SessionScopeState extends ConsumerState<SessionScope> {
  final _subs = <StreamSubscription<dynamic>>[];
  Timer? _rescheduleDebounce;

  @override
  void initState() {
    super.initState();
    final sync = ref.read(syncServiceProvider);
    final notifications = ref.read(notificationServiceProvider);
    final push = ref.read(pushServiceProvider);

    _subs
      ..add(sync.notices.listen(_onNotice))
      ..add(sync.activity.listen(_onActivity))
      ..add(notifications.taps.listen(_openPayload))
      ..add(push.taps.listen((data) {
        final date = data['date'];
        if (date is String) _openPayload('day:$date');
      }));

    ref.listenManual(authProvider, _onSessionChanged, fireImmediately: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final launch = notifications.launchPayload;
      if (launch != null) _openPayload(launch);
    });
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _rescheduleDebounce?.cancel();
    super.dispose();
  }

  void _onSessionChanged(AuthState? previous, AuthState next) {
    final user = next.user;
    if (next.isSignedIn && user != null) {
      if (previous?.user?.id != user.id) {
        ref.read(syncServiceProvider).start(user.id);
        ref.read(notificationServiceProvider).requestPermission();
        if (ref.read(settingsProvider).pushEnabled) ref.read(pushServiceProvider).register();
      }
    } else {
      ref.read(syncServiceProvider).stop();
    }
  }

  void _onNotice(SyncNotice notice) {
    switch (notice) {
      case SyncNotice.savedOffline:
        showSnack(tr('Brak połączenia. Zmiany zostaną zsynchronizowane później.',
            'No connection. Changes will be synced later.'));
      case SyncNotice.synced:
        showSnack(tr('Zsynchronizowano', 'Synced'));
      case SyncNotice.rejected:
        showSnack(tr('Serwer odrzucił zmianę — przywrócono aktualną wersję.',
            'The server rejected a change — the current version was restored.'));
    }
  }

  void _onActivity(GroupActivity activity) {
    final settings = ref.read(settingsProvider);
    if (!settings.pushEnabled) return;
    final members = ref.read(membersIndexProvider);
    final group = ref.read(groupsByIdProvider)[activity.event.groupId];
    final actor = members[activity.actorId]?.displayName ?? '?';
    ref.read(notificationServiceProvider).showActivity(
          title: tr('Nowe wydarzenie w ${group?.name ?? 'grupie'}', 'New event in ${group?.name ?? 'group'}'),
          body: tr('$actor dodał(a) wydarzenie: ${activity.event.title}', '$actor added: ${activity.event.title}'),
          payload: 'event:${activity.event.id}:${Dates.key(activity.event.localStart)}',
        );
  }

  /// `day:YYYY-MM-DD` lub `event:<id>:YYYY-MM-DD` → kalendarz na tym dniu (+ szczegóły wydarzenia).
  void _openPayload(String payload) {
    final parts = payload.split(':');
    if (parts.length < 2) return;
    final date = Dates.parseKey(parts.last);
    ref.read(visibleMonthProvider.notifier).set(date);
    ref.read(routerProvider).go('/calendar');
    if (parts.first == 'event' && parts.length == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final context = rootNavigatorKey.currentContext;
        if (context == null || !context.mounted) return;
        await showEventDetailsById(context, ref.read(databaseProvider), parts[1], date);
      });
    }
  }

  void _scheduleReminders() {
    _rescheduleDebounce?.cancel();
    _rescheduleDebounce = Timer(const Duration(seconds: 2), () {
      final events = ref.read(localEventsProvider).value;
      if (events == null || !ref.read(authProvider).isSignedIn) return;
      final settings = ref.read(settingsProvider);
      ref.read(notificationServiceProvider).reschedule(
            events,
            enabled: settings.remindersEnabled,
            defaultMinutes: settings.defaultReminderMinutes,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(localEventsProvider, (_, _) => _scheduleReminders());
    ref.listen(settingsProvider.select((s) => (s.remindersEnabled, s.defaultReminderMinutes)), (_, _) => _scheduleReminders());
    ref.listen(settingsProvider.select((s) => s.pushEnabled), (_, enabled) {
      if (!ref.read(authProvider).isSignedIn) return;
      final push = ref.read(pushServiceProvider);
      enabled ? push.register() : push.unregister();
    });
    return widget.child;
  }
}
