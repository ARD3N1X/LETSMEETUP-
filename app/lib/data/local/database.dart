import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models.dart';

part 'database.g.dart';

/// Wydarzenia (pełny JSON z serwera + kolumny do filtrowania/indeksów).
@TableIndex(name: 'idx_events_start', columns: {#startAt})
@TableIndex(name: 'idx_events_group', columns: {#groupId})
class EventRows extends Table {
  TextColumn get id => text()();
  TextColumn get data => text()();
  TextColumn get groupId => text().nullable()();
  DateTimeColumn get startAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(0))();

  /// `synced` lub `pending` (lokalna zmiana czeka w kolejce).
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  /// Przypomnienie ustawione na tym urządzeniu: null = domyślne, -1 = brak.
  IntColumn get reminderMinutes => integer().nullable()();
  DateTimeColumn get lastModifiedLocally => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class GroupRows extends Table {
  TextColumn get id => text()();
  TextColumn get data => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Widoczność grup w kalendarzu — wyłącznie lokalna (nie trafia na serwer).
class GroupVisibilityRows extends Table {
  TextColumn get groupId => text()();
  BoolColumn get visible => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {groupId};
}

/// Kolejka zmian do wysłania (FIFO).
class OutboxRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()();
  TextColumn get entityId => text()();
  TextColumn get payload => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Lokalne wersje odrzucone przez serwer — do ręcznego przejrzenia (rekomendacja 9.4).
class ConflictLogRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityId => text()();
  TextColumn get kind => text()();
  TextColumn get localData => text()();
  TextColumn get reason => text()();
  DateTimeColumn get createdAt => dateTime()();
}

class KvRows extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class LocalEvent {
  const LocalEvent(this.event, this.syncStatus, this.reminderMinutes);
  final CalendarEvent event;
  final String syncStatus;
  final int? reminderMinutes;
  bool get isPending => syncStatus == 'pending';
}

@DriftDatabase(tables: [EventRows, GroupRows, GroupVisibilityRows, OutboxRows, ConflictLogRows, KvRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'letsmeetup'));

  @override
  int get schemaVersion => 1;

  // --- Wydarzenia ---

  static LocalEvent _toLocal(EventRow row) => LocalEvent(
        CalendarEvent.fromJson(jsonDecode(row.data) as Map<String, dynamic>),
        row.syncStatus,
        row.reminderMinutes,
      );

  Stream<List<LocalEvent>> watchEvents() => select(eventRows).watch().map((rows) => rows.map(_toLocal).toList());

  Future<List<LocalEvent>> allEvents() async => (await select(eventRows).get()).map(_toLocal).toList();

  Future<LocalEvent?> eventById(String id) async {
    final row = await (select(eventRows)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toLocal(row);
  }

  Future<void> upsertEvent(CalendarEvent event, {required String status, int? reminderMinutes, bool keepReminder = true}) async {
    final existing = await (select(eventRows)..where((t) => t.id.equals(event.id))).getSingleOrNull();
    await into(eventRows).insertOnConflictUpdate(EventRowsCompanion.insert(
      id: event.id,
      data: jsonEncode(event.toJson()),
      groupId: Value(event.groupId),
      startAt: event.startAt,
      version: Value(event.version),
      syncStatus: Value(status),
      reminderMinutes: Value(keepReminder && reminderMinutes == null ? existing?.reminderMinutes : reminderMinutes),
      lastModifiedLocally: Value(status == 'pending' ? DateTime.now() : existing?.lastModifiedLocally),
    ));
  }

  Future<void> deleteEvent(String id) => (delete(eventRows)..where((t) => t.id.equals(id))).go();

  Future<void> setEventStatus(String id, String status) =>
      (update(eventRows)..where((t) => t.id.equals(id))).write(EventRowsCompanion(syncStatus: Value(status)));

  // --- Grupy ---

  Stream<List<Group>> watchGroups() => (select(groupRows)..orderBy([(t) => OrderingTerm(expression: t.name.lower())]))
      .watch()
      .map((rows) => rows.map((r) => Group.fromJson(jsonDecode(r.data) as Map<String, dynamic>)).toList());

  Future<void> upsertGroup(Group group) => into(groupRows).insertOnConflictUpdate(
        GroupRowsCompanion.insert(id: group.id, data: jsonEncode(group.json), name: group.name),
      );

  /// Zastępuje listę grup; usuwa wydarzenia grup, do których użytkownik już nie należy.
  Future<void> replaceGroups(List<Group> groups) => transaction(() async {
        final ids = groups.map((g) => g.id).toList();
        await (delete(groupRows)..where((t) => t.id.isNotIn(ids))).go();
        for (final g in groups) {
          await upsertGroup(g);
        }
        await (delete(eventRows)..where((t) => t.groupId.isNotNull() & t.groupId.isNotIn(ids))).go();
        await (delete(groupVisibilityRows)..where((t) => t.groupId.isNotIn(ids))).go();
      });

  Future<void> removeGroup(String groupId) => transaction(() async {
        await (delete(groupRows)..where((t) => t.id.equals(groupId))).go();
        await (delete(eventRows)..where((t) => t.groupId.equals(groupId))).go();
      });

  // --- Widoczność ---

  Stream<Map<String, bool>> watchVisibility() => select(groupVisibilityRows)
      .watch()
      .map((rows) => {for (final r in rows) r.groupId: r.visible});

  Future<void> setVisibility(String groupId, bool visible) => into(groupVisibilityRows)
      .insertOnConflictUpdate(GroupVisibilityRowsCompanion.insert(groupId: groupId, visible: Value(visible)));

  // --- Kolejka ---

  Future<void> enqueue(String kind, String entityId, Map<String, dynamic> payload) =>
      into(outboxRows).insert(OutboxRowsCompanion.insert(
        kind: kind,
        entityId: entityId,
        payload: jsonEncode(payload),
        createdAt: DateTime.now(),
      ));

  Future<List<OutboxRow>> pendingOps() => (select(outboxRows)..orderBy([(t) => OrderingTerm(expression: t.id)])).get();

  Stream<int> watchPendingCount() => outboxRows.count().watchSingle();

  Future<void> removeOp(int id) => (delete(outboxRows)..where((t) => t.id.equals(id))).go();

  Future<void> removeOpsFor(String entityId) => (delete(outboxRows)..where((t) => t.entityId.equals(entityId))).go();

  Future<void> bumpAttempts(int id, int attempts) =>
      (update(outboxRows)..where((t) => t.id.equals(id))).write(OutboxRowsCompanion(attempts: Value(attempts)));

  Future<bool> hasOpsFor(String entityId) async =>
      (await (select(outboxRows)..where((t) => t.entityId.equals(entityId))).get()).isNotEmpty;

  Future<void> logConflict(String entityId, String kind, String localData, String reason) =>
      into(conflictLogRows).insert(ConflictLogRowsCompanion.insert(
        entityId: entityId,
        kind: kind,
        localData: localData,
        reason: reason,
        createdAt: DateTime.now(),
      ));

  // --- Klucz-wartość ---

  Future<String?> getValue(String key) async =>
      (await (select(kvRows)..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setValue(String key, String? value) async {
    if (value == null) {
      await (delete(kvRows)..where((t) => t.key.equals(key))).go();
    } else {
      await into(kvRows).insertOnConflictUpdate(KvRowsCompanion.insert(key: key, value: value));
    }
  }

  /// Wylogowanie: dane użytkownika nie mogą zostać na urządzeniu.
  Future<void> clearAll() => transaction(() async {
        for (final table in allTables) {
          await delete(table).go();
        }
      });
}
