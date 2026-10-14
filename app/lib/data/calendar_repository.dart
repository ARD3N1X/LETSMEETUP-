import 'package:uuid/uuid.dart';

import 'local/database.dart';
import 'models.dart';
import 'remote/api_client.dart';

/// Operacje kolejki offline.
class OpKind {
  static const createEvent = 'event.create';
  static const updateEvent = 'event.update';
  static const deleteEvent = 'event.delete';
  static const putException = 'exception.put';
  static const deleteException = 'exception.delete';
  static const updateSettings = 'settings.update';
}

/// Wydarzenia: zapis lokalny natychmiast (optimistic UI) + kolejka do serwera.
/// Grupy: wymagają połączenia (kod zaproszenia i członkostwo weryfikuje serwer).
class CalendarRepository {
  CalendarRepository(this.db, this.api, {required this.onLocalChange});

  final AppDatabase db;
  final ApiClient api;

  /// Wywoływane po każdej lokalnej zmianie — uruchamia synchronizację w tle.
  final void Function() onLocalChange;

  static const _uuid = Uuid();
  static String newId() => _uuid.v4();

  // --- Wydarzenia ---

  Future<void> createEvent(CalendarEvent event, {int? reminderMinutes}) async {
    await db.transaction(() async {
      await db.upsertEvent(event, status: 'pending', reminderMinutes: reminderMinutes, keepReminder: false);
      await db.enqueue(OpKind.createEvent, event.id, event.toCreatePayload());
    });
    onLocalChange();
  }

  Future<void> createEvents(List<CalendarEvent> events) async {
    await db.transaction(() async {
      for (final e in events) {
        await db.upsertEvent(e, status: 'pending');
        await db.enqueue(OpKind.createEvent, e.id, e.toCreatePayload());
      }
    });
    onLocalChange();
  }

  Future<void> updateEvent(CalendarEvent before, CalendarEvent after, {int? reminderMinutes, bool reminderChanged = false}) async {
    final patch = after.diff(before);
    await db.transaction(() async {
      final local = await db.eventById(after.id);
      await db.upsertEvent(
        after,
        status: patch.isEmpty ? (local?.syncStatus ?? 'synced') : 'pending',
        reminderMinutes: reminderMinutes,
        keepReminder: !reminderChanged,
      );
      if (patch.isNotEmpty) await db.enqueue(OpKind.updateEvent, after.id, patch);
    });
    if (patch.isNotEmpty) onLocalChange();
  }

  Future<void> deleteEvent(String id) => deleteEvents([id]);

  Future<void> deleteEvents(List<String> ids) async {
    await db.transaction(() async {
      for (final id in ids) {
        await db.deleteEvent(id);
        await db.enqueue(OpKind.deleteEvent, id, const {});
      }
    });
    onLocalChange();
  }

  /// Zmiana pojedynczego wystąpienia serii (override) lub jego odwołanie.
  Future<void> putException(CalendarEvent event, EventException exception) async {
    final others = event.exceptions.where((x) => x.date != exception.date);
    final updated = event.copyWith(exceptions: [...others, exception]);
    await db.transaction(() async {
      await db.upsertEvent(updated, status: 'pending');
      await db.enqueue(OpKind.putException, event.id, {
        'date': exception.toJson()['date'],
        'body': {
          'cancelled': exception.cancelled,
          'title': exception.title,
          'color': exception.color,
          'startAt': exception.startAt?.toIso8601String(),
          'endAt': exception.endAt?.toIso8601String(),
        },
      });
    });
    onLocalChange();
  }

  Future<void> deleteException(CalendarEvent event, DateTime date) async {
    final updated = event.copyWith(exceptions: event.exceptions.where((x) => x.date != date).toList());
    await db.transaction(() async {
      await db.upsertEvent(updated, status: 'pending');
      await db.enqueue(OpKind.deleteException, event.id, {'date': EventException(date: date).toJson()['date']});
    });
    onLocalChange();
  }

  Future<void> setReminder(String eventId, int? minutes) async {
    final local = await db.eventById(eventId);
    if (local == null) return;
    await db.upsertEvent(local.event, status: local.syncStatus, reminderMinutes: minutes, keepReminder: false);
  }

  Future<void> setGroupVisible(String groupId, bool visible) => db.setVisibility(groupId, visible);

  // --- Grupy (online) ---

  Future<Group> _saveGroup(dynamic json) async {
    final group = Group.fromJson((json as Map).cast<String, dynamic>());
    await db.upsertGroup(group);
    return group;
  }

  Future<Group> createGroup({required String name, String? description, required String color}) async =>
      _saveGroup(await api.post('/groups', {'name': name, 'description': description, 'color': color}));

  Future<Group> joinGroup(String code) async {
    final group = await _saveGroup(await api.post('/groups/join', {'code': code}));
    onLocalChange(); // dociągnij wydarzenia nowej grupy
    return group;
  }

  Future<Group> updateGroup(String id, {String? name, String? description, String? color}) async => _saveGroup(
        await api.patch('/groups/$id', {
          'name': ?name,
          'description': ?description,
          'color': ?color,
        }),
      );

  Future<Group> regenerateInviteCode(String id) async => _saveGroup(await api.post('/groups/$id/invite-code'));

  Future<Group> setMemberRole(String groupId, String userId, GroupRole role) async =>
      _saveGroup(await api.patch('/groups/$groupId/members/$userId', {'role': role.name}));

  Future<Group> removeMember(String groupId, String userId) async =>
      _saveGroup(await api.delete('/groups/$groupId/members/$userId'));

  Future<void> leaveGroup(String id) async {
    await api.post('/groups/$id/leave');
    await db.removeGroup(id);
  }

  Future<void> deleteGroup(String id, String password) async {
    await api.delete('/groups/$id', {'password': password});
    await db.removeGroup(id);
  }
}
