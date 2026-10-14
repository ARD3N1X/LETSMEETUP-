import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letsmeetup/data/calendar_repository.dart';
import 'package:letsmeetup/data/local/database.dart';
import 'package:letsmeetup/data/models.dart';
import 'package:letsmeetup/data/remote/api_client.dart';
import 'package:letsmeetup/data/remote/realtime_client.dart';
import 'package:letsmeetup/services/sync_service.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectivity extends Mock implements Connectivity {}

/// Udawany serwer: zapamiętuje żądania, odpowiada jak backend.
class FakeApi extends ApiClient {
  FakeApi() : super(TokenStore());

  bool offline = false;
  final calls = <String>[];
  final serverEvents = <String, Map<String, dynamic>>{};
  Map<String, dynamic> syncResponse = {
    'serverTime': '2026-08-14T10:00:00.000Z',
    'full': false,
    'groups': <dynamic>[],
    'events': <dynamic>[],
    'deletedEventIds': <dynamic>[],
  };
  ApiException? rejectPatch;

  void _check(String call) {
    calls.add(call);
    if (offline) throw ApiException(code: 'NETWORK', message: 'offline', isNetwork: true);
  }

  Map<String, dynamic> _stored(Map<String, dynamic> payload, {int version = 1}) => {
        ...payload,
        'createdById': 'me',
        'exceptions': <dynamic>[],
        'version': version,
        'updatedAt': '2026-08-14T10:00:00.000Z',
      };

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    _check('GET $path');
    if (path == '/sync') return syncResponse;
    final id = path.split('/').last;
    final event = serverEvents[id];
    if (event == null) throw ApiException(code: 'EVENT_NOT_FOUND', message: '', status: 404);
    return event;
  }

  @override
  Future<dynamic> post(String path, [Object? body]) async {
    _check('POST $path');
    final map = body as Map<String, dynamic>;
    if (path == '/events/batch') {
      return [
        for (final e in (map['events'] as List).cast<Map<String, dynamic>>()) serverEvents[e['id'] as String] = _stored(e),
      ];
    }
    if (path == '/events/batch-delete') {
      final ids = (map['ids'] as List).cast<String>();
      ids.forEach(serverEvents.remove);
      return {'deleted': ids, 'forbidden': <String>[]};
    }
    return {'ok': true};
  }

  @override
  Future<dynamic> patch(String path, Object body) async {
    _check('PATCH $path');
    if (rejectPatch != null) throw rejectPatch!;
    final id = path.split('/').last;
    final current = serverEvents[id]!;
    return serverEvents[id] = {...current, ...(body as Map<String, dynamic>), 'version': (current['version'] as int) + 1};
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late FakeApi api;
  late SyncService sync;
  late CalendarRepository repo;

  CalendarEvent newEvent(String id, {String? groupId}) => CalendarEvent(
        id: id,
        title: 'Spotkanie $id',
        createdById: 'me',
        groupId: groupId,
        startAt: DateTime.utc(2026, 8, 14, 8),
        endAt: DateTime.utc(2026, 8, 14, 9),
        allDay: false,
        color: '#87CEEB',
      );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    api = FakeApi();
    final connectivity = MockConnectivity();
    when(() => connectivity.onConnectivityChanged).thenAnswer((_) => const Stream.empty());
    sync = SyncService(db: db, api: api, realtime: RealtimeClient(api), connectivity: connectivity);
    repo = CalendarRepository(db, api, onLocalChange: sync.kick);
    await sync.start('me');
    await sync.syncNow();
  });

  tearDown(() async {
    await sync.stop();
    await db.close();
  });

  test('offline changes are queued and sent in one batch when back online', () async {
    api.offline = true;
    await repo.createEvents([newEvent('a'), newEvent('b')]);
    await sync.syncNow();

    expect(sync.status.value.online, isFalse);
    expect((await db.pendingOps()).length, 2);
    expect((await db.eventById('a'))!.isPending, isTrue, reason: 'optimistic UI shows the event immediately');

    api.offline = false;
    api.calls.clear();
    await sync.syncNow();

    expect(api.calls.where((c) => c == 'POST /events/batch'), hasLength(1));
    expect(await db.pendingOps(), isEmpty);
    expect((await db.eventById('a'))!.isPending, isFalse);
    expect(sync.status.value.online, isTrue);
  });

  test('updates send only changed fields', () async {
    final event = newEvent('a');
    await repo.createEvent(event);
    await sync.syncNow();
    await repo.updateEvent(event, event.copyWith(title: 'Nowy tytuł'));
    await sync.syncNow();

    expect(api.calls, contains('PATCH /events/a'));
    expect(api.serverEvents['a']!['title'], 'Nowy tytuł');
    expect((await db.eventById('a'))!.event.version, 2);
  });

  test('server rejection restores the server version and logs the conflict', () async {
    final event = newEvent('a');
    await repo.createEvent(event);
    await sync.syncNow();

    api.rejectPatch = ApiException(code: 'NOT_EVENT_OWNER', message: '', status: 403);
    await repo.updateEvent(event, event.copyWith(title: 'Nie wolno'));
    await sync.syncNow();

    final local = await db.eventById('a');
    expect(local!.event.title, 'Spotkanie a');
    expect(local.isPending, isFalse);
    expect(await db.select(db.conflictLogRows).get(), hasLength(1));
  });

  test('pull applies deletions and drops events of groups the user left', () async {
    await db.upsertEvent(newEvent('private'), status: 'synced');
    await db.upsertEvent(newEvent('g1-event', groupId: 'g1'), status: 'synced');
    await db.upsertEvent(newEvent('deleted'), status: 'synced');

    api.syncResponse = {
      'serverTime': '2026-08-14T11:00:00.000Z',
      'full': false,
      'groups': <dynamic>[], // użytkownik nie należy już do g1
      'events': [newEvent('fresh').toJson()],
      'deletedEventIds': ['deleted'],
    };
    await sync.syncNow();

    final ids = (await db.allEvents()).map((e) => e.event.id).toSet();
    expect(ids, {'private', 'fresh'});
    expect(await db.getValue('sync_cursor'), '2026-08-14T11:00:00.000Z');
  });

  test('pull does not overwrite events with unsent local changes', () async {
    api.offline = true;
    await repo.createEvent(newEvent('a').copyWith(title: 'Lokalnie'));
    api.offline = false;
    api.syncResponse = {
      ...api.syncResponse,
      'events': [newEvent('a').copyWith(title: 'Z serwera').toJson()],
    };
    // Kolejka zostaje wysłana przed pobraniem zmian (push lokalnych, potem apply remote).
    await sync.syncNow();
    expect(api.calls.indexOf('POST /events/batch'), lessThan(api.calls.lastIndexOf('GET /sync')));
  });
}
