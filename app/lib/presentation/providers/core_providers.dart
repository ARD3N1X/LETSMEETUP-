import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/calendar_repository.dart';
import '../../data/local/database.dart';
import '../../data/models.dart';
import '../../data/remote/api_client.dart';
import '../../data/remote/realtime_client.dart';
import '../../services/notification_service.dart';
import '../../services/push_service.dart';
import '../../services/sync_service.dart';

/// Inicjalizowane w `main()` i wstrzykiwane przez `ProviderScope.overrides`.
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('prefsProvider'));
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('databaseProvider'));
final tokenStoreProvider = Provider<TokenStore>((ref) => throw UnimplementedError('tokenStoreProvider'));
final notificationServiceProvider =
    Provider<NotificationService>((ref) => throw UnimplementedError('notificationServiceProvider'));
final pushServiceProvider = Provider<PushService>((ref) => throw UnimplementedError('pushServiceProvider'));

final apiProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(tokenStoreProvider)));

final realtimeProvider = Provider<RealtimeClient>((ref) {
  final client = RealtimeClient(ref.watch(apiProvider));
  ref.onDispose(client.dispose);
  return client;
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    db: ref.watch(databaseProvider),
    api: ref.watch(apiProvider),
    realtime: ref.watch(realtimeProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final repositoryProvider = Provider<CalendarRepository>((ref) {
  final sync = ref.watch(syncServiceProvider);
  return CalendarRepository(ref.watch(databaseProvider), ref.watch(apiProvider), onLocalChange: sync.kick);
});

final syncStatusProvider = Provider<ValueNotifier<SyncStatus>>((ref) => ref.watch(syncServiceProvider).status);

final localEventsProvider = StreamProvider<List<LocalEvent>>((ref) => ref.watch(databaseProvider).watchEvents());

final groupsProvider = StreamProvider<List<Group>>((ref) => ref.watch(databaseProvider).watchGroups());

final visibilityProvider = StreamProvider<Map<String, bool>>((ref) => ref.watch(databaseProvider).watchVisibility());

final groupsByIdProvider = Provider<Map<String, Group>>((ref) {
  final groups = ref.watch(groupsProvider).value ?? const [];
  return {for (final g in groups) g.id: g};
});

/// userId → dane członka (imię, avatar) ze wszystkich grup użytkownika.
final membersIndexProvider = Provider<Map<String, GroupMember>>((ref) {
  final groups = ref.watch(groupsProvider).value ?? const [];
  return {
    for (final g in groups)
      for (final m in g.members) m.userId: m,
  };
});

/// Globalny dostęp do SnackBarów (np. z serwisu synchronizacji).
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showSnack(String message, {SnackBarAction? action, Duration duration = const Duration(seconds: 3)}) {
  final messenger = scaffoldMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action, duration: duration));
}
