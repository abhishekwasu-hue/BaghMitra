import 'dart:convert';

import 'package:bagmitra/features/bahar/data/bahar_catalog.dart';
import 'package:bagmitra/features/bahar/data/bahar_repository.dart';
import 'package:bagmitra/features/bahar/domain/bahar_cycle.dart';
import 'package:bagmitra/sync/transport.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';

BaharCycle cycle(String id, {String plotId = 'p1'}) => BaharCycle(
  id: id,
  plotId: plotId,
  bahar: 'ambia',
  seasonYear: 2027,
  status: 'planned',
  planned: {'flowering': DateTime.utc(2027, 2, 10)},
);

void main() {
  test('payload matches the API contract and round-trips', () {
    final c = cycle('b1');
    final payload = c.toPayload();
    expect(payload['planned'], {'flowering': '2027-02-10'});
    expect(payload['actual'], <String, String>{});
    expect(payload['template_id'], isNull);
    final back = BaharCycle.fromPayload(
      'b1',
      jsonDecode(jsonEncode(payload)) as Map<String, Object?>,
    );
    expect(back.toPayload(), payload);
  });

  test('save queues a bahar_cycle mutation; remote changes apply', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final repo = BaharRepository(db, clock: TestClock().call);
    await repo.save(cycle('b1'));
    final queued = await db.select(db.outboxEntries).get();
    expect(queued.single.entity, 'bahar_cycle');
    expect(jsonDecode(queued.single.payload), cycle('b1').toPayload());
    expect(await repo.watchForPlot('p1').first, hasLength(1));
    expect(await repo.watchForPlot('p2').first, isEmpty);

    await repo.applyRemote(
      RemoteChange(
        entity: 'bahar_cycle',
        entityId: 'b2',
        data: cycle('b2', plotId: 'p2').toPayload(),
        updatedAt: DateTime.utc(2026, 10, 13),
      ),
    );
    expect(await repo.watchForPlot('p2').first, hasLength(1));
    await repo.applyRemote(
      RemoteChange(
        entity: 'bahar_cycle',
        entityId: 'b2',
        data: const {},
        deleted: true,
        updatedAt: DateTime.utc(2026, 10, 14),
      ),
    );
    expect(await repo.watchForPlot('p2').first, isEmpty);
  });

  test('catalog lists bahars per crop and the manual stages', () async {
    final catalog = await BaharCatalog(bundle: FileAssetBundle()).load();
    expect(catalog.forCrop('santra').map((b) => b.slug), contains('ambia'));
    expect(catalog.stages.map((s) => s.key), contains('flowering'));
    expect(catalog.stages.first.label('mr'), isNotEmpty);
  });
}
