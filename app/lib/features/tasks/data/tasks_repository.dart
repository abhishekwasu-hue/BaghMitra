import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../data/local/database.dart';
import '../../../sync/outbox.dart';
import '../../../sync/transport.dart';
import '../domain/farm_task.dart';

/// Offline-first farm tasks: each write lands locally and in the outbox atomically; server
/// changes (including tombstones) apply through the sync engine.
class TasksRepository {
  TasksRepository(
    this._db, {
    Outbox? outbox,
    Clock clock = systemClock,
    this._uuid = const Uuid(),
  }) : _outbox = outbox ?? Outbox(_db, clock: clock),
       _clock = clock;

  static const entity = 'farm_task';

  final AppDatabase _db;
  final Outbox _outbox;
  final Clock _clock;
  final Uuid _uuid;

  String newId() => _uuid.v4();

  /// Every task, soonest due first.
  Stream<List<FarmTask>> watchAll() =>
      (_db.select(_db.farmTasks)..orderBy([(t) => OrderingTerm.asc(t.dueOn)]))
          .watch()
          .map((rows) => [for (final r in rows) _toDomain(r)]);

  /// The task made from [source] (e.g. a lab test's "next test due"), if any.
  Future<FarmTask?> findBySource(String source) async {
    final row =
        await (_db.select(_db.farmTasks)
              ..where((t) => t.source.equals(source))
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<void> save(FarmTask task) {
    final now = _clock();
    return _write(
      task.id,
      task.toPayload(),
      () =>
          _db.into(_db.farmTasks).insertOnConflictUpdate(_companion(task, now)),
      now,
    );
  }

  /// Ticks a task done (today) or back to open.
  Future<void> setDone(FarmTask task, {required bool done}) =>
      save(task.withDone(done ? dateOnly(_clock()) : null));

  Future<void> delete(String id) => _write(
    id,
    const {},
    () => (_db.delete(_db.farmTasks)..where((t) => t.id.equals(id))).go(),
    _clock(),
    op: 'delete',
  );

  Future<void> applyRemote(RemoteChange c) async {
    if (c.deleted) {
      await (_db.delete(
        _db.farmTasks,
      )..where((t) => t.id.equals(c.entityId))).go();
    } else {
      await _db
          .into(_db.farmTasks)
          .insertOnConflictUpdate(
            _companion(FarmTask.fromPayload(c.entityId, c.data), c.updatedAt),
          );
    }
  }

  Future<void> _write(
    String id,
    Map<String, Object?> payload,
    Future<Object?> Function() local,
    DateTime now, {
    String op = 'upsert',
  }) => _db.transaction(() async {
    await local();
    await _outbox.enqueue(
      entity: entity,
      entityId: id,
      payload: payload,
      clientUpdatedAt: now,
      op: op,
    );
  });

  static FarmTasksCompanion _companion(FarmTask t, DateTime at) =>
      FarmTasksCompanion.insert(
        id: t.id,
        plotId: Value(t.plotId),
        baharCycleId: Value(t.baharCycleId),
        title: t.title,
        kind: t.kind,
        dueOn: t.dueOn,
        doneOn: Value(t.doneOn),
        source: Value(t.source),
        note: Value(t.note),
        clientUpdatedAt: at.toUtc(),
      );

  static FarmTask _toDomain(FarmTaskRow r) => FarmTask(
    id: r.id,
    plotId: r.plotId,
    baharCycleId: r.baharCycleId,
    title: r.title,
    kind: r.kind,
    dueOn: r.dueOn,
    doneOn: r.doneOn,
    source: r.source,
    note: r.note,
  );
}
