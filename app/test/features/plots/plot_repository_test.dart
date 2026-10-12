import 'dart:convert';
import 'dart:math';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/plots/data/plot_repository.dart';
import 'package:bagmitra/features/plots/domain/plot.dart';
import 'package:bagmitra/sync/outbox.dart';
import 'package:bagmitra/sync/sync_engine.dart';
import 'package:bagmitra/sync/transport.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/test_db.dart';

const _square = {
  'type': 'Polygon',
  'coordinates': [
    [
      [78.58, 21.27],
      [78.59, 21.27],
      [78.59, 21.28],
      [78.58, 21.27],
    ],
  ],
};

Plot _plot(String id, {String name = 'Bag 1'}) => Plot(
  id: id,
  name: name,
  crop: 'santra',
  areaSqM: 4 * Plot.sqMPerAcre,
  variety: 'nagpur',
  plantingYear: 2014,
  treeCount: 440,
  rowSpacingM: 6,
  plantSpacingM: 6,
  irrigationType: 'drip',
  waterSource: 'well',
  soilType: 'black_medium',
  centroidLat: 21.275,
  centroidLon: 78.585,
  boundary: _square,
);

void main() {
  test('payload round-trips and area converts to acres', () {
    final p = _plot('p1');
    final back = Plot.fromPayload(
      'p1',
      jsonDecode(jsonEncode(p.toPayload())) as Map<String, Object?>,
    );
    expect(back.toPayload(), p.toPayload());
    expect(back.areaAcres, closeTo(4, 1e-9));
  });

  test(
    'save and delete write locally and queue mutations atomically',
    () async {
      final db = memoryDb();
      final clock = TestClock();
      final repo = PlotRepository(db, clock: clock.call);
      final id = repo.newId();

      await repo.save(_plot(id));
      final [saved] = await repo.watchAll().first;
      expect(saved.boundary, _square);
      expect(saved.treeCount, 440);

      await repo.delete(id);
      expect(await repo.watchAll().first, isEmpty);
      final queued = await db.select(db.outboxEntries).get();
      expect(queued.map((e) => (e.entity, e.op)), [
        ('plot', 'upsert'),
        ('plot', 'delete'),
      ]);
      await db.close();
    },
  );

  test('server tombstone removes the local plot', () async {
    final db = memoryDb();
    final repo = PlotRepository(db);
    await repo.applyRemote(
      RemoteChange(
        entity: 'plot',
        entityId: 'p9',
        data: _plot('p9').toPayload(),
        updatedAt: DateTime.utc(2026),
      ),
    );
    expect(await repo.watchAll().first, hasLength(1));
    await repo.applyRemote(
      RemoteChange(
        entity: 'plot',
        entityId: 'p9',
        data: const {},
        updatedAt: DateTime.utc(2026, 2),
        deleted: true,
      ),
    );
    expect(await repo.watchAll().first, isEmpty);
    await db.close();
  });

  test('offline create + delete on another device reach this device', () async {
    final server = FakeSyncServer()..online = false;
    final clock = TestClock();
    final dbA = memoryDb();
    final dbB = memoryDb();
    SyncEngine engine(PlotRepository repo, AppDatabase dbX) => SyncEngine(
      db: dbX,
      transport: server,
      appliers: {PlotRepository.entity: repo.applyRemote},
      outbox: Outbox(dbX, clock: clock.call),
      clock: clock.call,
      random: Random(1),
    );
    final repoA = PlotRepository(dbA, clock: clock.call);
    final repoB = PlotRepository(dbB, clock: clock.call);
    final a = engine(repoA, dbA);
    final b = engine(repoB, dbB);

    final id = repoA.newId();
    await repoA.save(_plot(id, name: 'Bag 2'));
    expect((await a.sync()).offline, isTrue);

    server.online = true;
    clock.advance(const Duration(minutes: 5));
    await a.sync();
    await b.sync();
    expect((await repoB.watchAll().first).single.name, 'Bag 2');

    clock.advance(const Duration(minutes: 1));
    await repoA.delete(id);
    await a.sync();
    await b.sync();
    expect(await repoB.watchAll().first, isEmpty);
    expect(server.row('plot', id), isNull);

    for (final e in [a, b]) {
      await e.dispose();
    }
    await dbA.close();
    await dbB.close();
  });
}
