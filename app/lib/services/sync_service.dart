import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../data/calendar_repository.dart';
import '../data/local/database.dart';
import '../data/models.dart';
import '../data/remote/api_client.dart';
import '../data/remote/realtime_client.dart';

@immutable
class SyncStatus {
  const SyncStatus({this.online = true, this.pending = 0, this.syncing = false});
  final bool online;
  final int pending;
  final bool syncing;

  SyncStatus copyWith({bool? online, int? pending, bool? syncing}) =>
      SyncStatus(online: online ?? this.online, pending: pending ?? this.pending, syncing: syncing ?? this.syncing);
}

/// Komunikaty dla użytkownika (SnackBar).
enum SyncNotice { savedOffline, synced, rejected }

/// Nowe wydarzenie od innego członka grupy (powiadomienie w aplikacji).
class GroupActivity {
  GroupActivity(this.event, this.actorId);
  final CalendarEvent event;
  final String actorId;
}

/// Synchronizacja offline-first:
/// 1. lokalne zmiany czekają w kolejce (FIFO) i są wysyłane w tle (z ponawianiem i backoffem),
/// 2. zmiany z serwera przychodzą przez WebSocket oraz `GET /sync` (po reconnect / starcie),
/// 3. konflikt: wygrywa serwer, odrzucona wersja lokalna trafia do `conflict_log_rows`.
class SyncService {
  SyncService({required this.db, required this.api, required this.realtime, Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final AppDatabase db;
  final ApiClient api;
  final RealtimeClient realtime;
  final Connectivity _connectivity;

  static const _cursorKey = 'sync_cursor';
  static const _batchSize = 100;

  final status = ValueNotifier(const SyncStatus());
  final _notices = StreamController<SyncNotice>.broadcast();
  final _activity = StreamController<GroupActivity>.broadcast();
  Stream<SyncNotice> get notices => _notices.stream;
  Stream<GroupActivity> get activity => _activity.stream;

  String? _userId;
  final _subs = <StreamSubscription<dynamic>>[];
  Timer? _retryTimer;
  int _retryAttempt = 0;
  Future<void>? _running;
  bool _again = false;
  bool _pullRequested = false;
  bool _wasOffline = false;

  bool get isStarted => _userId != null;

  Future<void> start(String userId) async {
    if (_userId == userId) return;
    await stop();
    _userId = userId;
    _subs
      ..add(db.watchPendingCount().listen((n) => status.value = status.value.copyWith(pending: n)))
      ..add(realtime.messages.listen(_onRealtime))
      ..add(_connectivity.onConnectivityChanged.listen((results) {
        if (!results.contains(ConnectivityResult.none)) {
          realtime.connect();
          kick(pull: true);
        } else {
          _setOnline(false);
        }
      }));
    realtime.connect();
    kick(pull: true);
  }

  Future<void> stop() async {
    _userId = null;
    _retryTimer?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    realtime.disconnect();
    await _running;
  }

  /// Uruchamia wysyłkę kolejki (i opcjonalnie pobranie zmian). Bezpieczne do wielokrotnego wołania.
  void kick({bool pull = false}) {
    if (_userId == null) return;
    _pullRequested |= pull;
    if (_running != null) {
      _again = true;
      return;
    }
    _running = _run().whenComplete(() {
      _running = null;
      if (_again) {
        _again = false;
        kick();
      }
    });
  }

  /// Wymusza pełny cykl i czeka na jego koniec (np. pull-to-refresh).
  Future<void> syncNow() async {
    kick(pull: true);
    while (_running != null) {
      await _running;
    }
  }

  Future<void> _run() async {
    status.value = status.value.copyWith(syncing: true);
    try {
      final flushed = await _flush();
      if (!flushed) return;
      if (_pullRequested) {
        _pullRequested = false;
        await _pull();
      }
      _setOnline(true);
      _retryAttempt = 0;
      if (_wasOffline && status.value.pending == 0) {
        _wasOffline = false;
        _notices.add(SyncNotice.synced);
      }
    } on ApiException catch (e) {
      if (e.isRetryable) {
        _scheduleRetry();
      } else {
        debugPrint('Sync error: $e');
      }
    } finally {
      status.value = status.value.copyWith(syncing: false);
    }
  }

  void _setOnline(bool online) {
    if (status.value.online == online) return;
    status.value = status.value.copyWith(online: online);
  }

  void _scheduleRetry() {
    _setOnline(false);
    if (!_wasOffline) {
      _wasOffline = true;
      if (status.value.pending > 0) _notices.add(SyncNotice.savedOffline);
    }
    _retryTimer?.cancel();
    final seconds = min(60, pow(2, _retryAttempt++).toInt() * 2);
    _retryTimer = Timer(Duration(seconds: seconds), () => kick(pull: true));
  }

  // --- Wysyłanie kolejki ---

  /// Zwraca false, gdy przerwano z powodu braku sieci.
  Future<bool> _flush() async {
    while (_userId != null) {
      final ops = await db.pendingOps();
      if (ops.isEmpty) return true;
      final first = ops.first;
      try {
        if (first.kind == OpKind.createEvent || first.kind == OpKind.deleteEvent) {
          final batch = ops.takeWhile((o) => o.kind == first.kind).take(_batchSize).toList();
          await (first.kind == OpKind.createEvent ? _sendCreates(batch) : _sendDeletes(batch));
        } else {
          await _sendSingle(first);
          await db.removeOp(first.id);
        }
      } on ApiException catch (e) {
        if (e.isRetryable) {
          await db.bumpAttempts(first.id, first.attempts + 1);
          rethrow;
        }
        await _reject(first, e);
      }
    }
    return false;
  }

  Future<void> _sendCreates(List<OutboxRow> batch) async {
    final payload = batch.map((o) => jsonDecode(o.payload)).toList();
    final List<dynamic> created;
    try {
      created = await api.post('/events/batch', {'events': payload}) as List<dynamic>;
    } on ApiException catch (e) {
      // Jedno błędne wydarzenie nie może blokować reszty — przy błędzie walidacji wysyłamy pojedynczo.
      if (e.isRetryable || batch.length == 1) rethrow;
      for (final op in batch) {
        try {
          final event = await api.post('/events', jsonDecode(op.payload));
          await db.removeOp(op.id);
          await _applyServerEvent((event as Map).cast<String, dynamic>());
        } on ApiException catch (single) {
          if (single.isRetryable) rethrow;
          await _reject(op, single);
        }
      }
      return;
    }
    for (final op in batch) {
      await db.removeOp(op.id);
    }
    for (final json in created) {
      await _applyServerEvent((json as Map).cast<String, dynamic>());
    }
  }

  Future<void> _sendDeletes(List<OutboxRow> batch) async {
    final res = await api.post('/events/batch-delete', {'ids': batch.map((o) => o.entityId).toList()}) as Map;
    for (final op in batch) {
      await db.removeOp(op.id);
    }
    for (final id in (res['forbidden'] as List? ?? const []).cast<String>()) {
      await db.logConflict(id, OpKind.deleteEvent, '{}', 'FORBIDDEN');
      await _refetchEvent(id);
    }
  }

  Future<void> _sendSingle(OutboxRow op) async {
    final payload = jsonDecode(op.payload) as Map<String, dynamic>;
    switch (op.kind) {
      case OpKind.updateEvent:
        await _applyServerEvent(await api.patch('/events/${op.entityId}', payload) as Map<String, dynamic>, op.id);
      case OpKind.putException:
        await _applyServerEvent(
          await api.put('/events/${op.entityId}/exceptions/${payload['date']}', payload['body'] as Object)
              as Map<String, dynamic>,
          op.id,
        );
      case OpKind.deleteException:
        await _applyServerEvent(
          await api.delete('/events/${op.entityId}/exceptions/${payload['date']}') as Map<String, dynamic>,
          op.id,
        );
      case OpKind.updateSettings:
        await api.patch('/me', payload);
    }
  }

  /// Serwer odrzucił zmianę (brak uprawnień, walidacja) → zapis w logu konfliktów i przywrócenie stanu serwera.
  Future<void> _reject(OutboxRow op, ApiException e) async {
    await db.removeOp(op.id);
    if (op.kind == OpKind.updateSettings) return;
    final local = await db.eventById(op.entityId);
    await db.logConflict(op.entityId, op.kind, local == null ? op.payload : jsonEncode(local.event.toJson()), e.code);
    await _refetchEvent(op.entityId);
    _notices.add(SyncNotice.rejected);
  }

  Future<void> _refetchEvent(String id) async {
    try {
      final json = await api.get('/events/$id') as Map<String, dynamic>;
      await db.removeOpsFor(id);
      await db.upsertEvent(CalendarEvent.fromJson(json), status: 'synced');
    } on ApiException catch (e) {
      if (e.status == 404) {
        await db.removeOpsFor(id);
        await db.deleteEvent(id);
      } else {
        rethrow;
      }
    }
  }

  /// Zapisuje wersję z serwera, chyba że w kolejce czekają kolejne lokalne zmiany tego wydarzenia.
  Future<void> _applyServerEvent(Map<String, dynamic> json, [int? sentOpId]) async {
    final event = CalendarEvent.fromJson(json);
    if (sentOpId != null) await db.removeOp(sentOpId);
    if (await db.hasOpsFor(event.id)) return;
    await db.upsertEvent(event, status: 'synced');
  }

  // --- Pobieranie zmian ---

  Future<void> _pull() async {
    final cursor = await db.getValue(_cursorKey);
    final res = await api.get('/sync', query: {'since': ?cursor}) as Map<String, dynamic>;
    final groups = (res['groups'] as List).map((g) => Group.fromJson((g as Map).cast<String, dynamic>())).toList();
    final events = (res['events'] as List).map((e) => CalendarEvent.fromJson((e as Map).cast<String, dynamic>())).toList();
    final deleted = (res['deletedEventIds'] as List).cast<String>();
    final full = res['full'] as bool? ?? false;

    await db.transaction(() async {
      await db.replaceGroups(groups);
      for (final id in deleted) {
        await db.removeOpsFor(id); // usunięte na serwerze → lokalne zmiany tracą sens
        await db.deleteEvent(id);
      }
      for (final e in events) {
        if (await db.hasOpsFor(e.id)) continue;
        await db.upsertEvent(e, status: 'synced');
      }
      if (full) {
        final serverIds = events.map((e) => e.id).toSet();
        for (final local in await db.allEvents()) {
          if (!serverIds.contains(local.event.id) && !local.isPending && !await db.hasOpsFor(local.event.id)) {
            await db.deleteEvent(local.event.id);
          }
        }
      }
      await db.setValue(_cursorKey, res['serverTime'] as String);
    });
  }

  // --- Realtime ---

  Future<void> _onRealtime(RealtimeMessage message) async {
    switch (message) {
      case RealtimeReady():
        _setOnline(true);
        kick(pull: true);
      case RealtimeDisconnected():
        break;
      case EventUpserted(:final event, :final actorId):
        final parsed = CalendarEvent.fromJson(event);
        final existing = await db.eventById(parsed.id);
        if (await db.hasOpsFor(parsed.id)) return;
        if (existing != null && existing.event.version >= parsed.version && !existing.isPending) return;
        await db.upsertEvent(parsed, status: 'synced');
        if (existing == null && actorId != null && actorId != _userId && parsed.groupId != null) {
          _activity.add(GroupActivity(parsed, actorId));
        }
      case EventDeleted(:final id):
        await db.removeOpsFor(id);
        await db.deleteEvent(id);
      case GroupsChanged():
        kick(pull: true);
      case GroupRemoved(:final groupId):
        await db.removeGroup(groupId);
        kick(pull: true);
    }
  }

  void dispose() {
    stop();
    _notices.close();
    _activity.close();
    status.dispose();
  }
}
