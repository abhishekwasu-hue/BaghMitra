import 'dart:convert';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/market_link/data/market_lot_repository.dart';
import 'package:bagmitra/features/market_link/domain/market_lot.dart';
import 'package:bagmitra/sync/outbox.dart';
import 'package:bagmitra/sync/transport.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_db.dart';

MarketLot sampleLot({String id = 'l1', String status = 'draft'}) => MarketLot(
  id: id,
  plotId: 'p1',
  crop: 'santra',
  variety: 'nagpuri',
  quantityT: 12.5,
  quality: 'मोठी · ए ग्रेड · रंग चांगला',
  harvestFrom: DateTime(2026, 12, 2),
  harvestTo: DateTime(2026, 12, 20),
  basis: 'per_quintal',
  askingRatePaise: 300000,
  status: status,
);

LotPhoto samplePhoto(String id, {String lotId = 'l1', String? key}) => LotPhoto(
  id: id,
  lotId: lotId,
  capturedAt: DateTime.utc(2026, 11, 7, 5, 30),
  lat: 21.1458,
  lon: 79.0882,
  photoPath: '/docs/market_lot_photos/$id.jpg',
  photoKey: key,
);

void main() {
  late AppDatabase db;
  late MarketLotRepository repo;
  late Outbox outbox;

  setUp(() {
    db = memoryDb();
    outbox = Outbox(db, clock: () => DateTime.utc(2026, 11, 7, 6));
    repo = MarketLotRepository(
      db,
      outbox: outbox,
      clock: () => DateTime.utc(2026, 11, 7, 6),
    );
  });
  tearDown(() => db.close());

  test('the lot payload holds only the grower fields (no server fields, no '
      'commission or income key)', () {
    final payload = sampleLot().toPayload();
    expect(payload.keys.toSet(), {
      'plot_id',
      'bahar_cycle_id',
      'quantity_t',
      'quality',
      'harvest_from',
      'harvest_to',
      'basis',
      'asking_rate_paise',
    });
    expect(payload['harvest_from'], '2026-12-02');
    expect(
      jsonEncode(payload),
      isNot(matches(RegExp('commission|brokerage|income|dalali'))),
    );
    expect(samplePhoto('f1').toPayload().keys.toSet(), {
      'lot_id',
      'captured_at',
      'lat',
      'lon',
      'photo_key',
    });
  });

  test(
    'saving queues the lot, then its photos; server state comes back',
    () async {
      await repo.save(sampleLot());
      await repo.savePhoto(samplePhoto('f1'));
      final queued = await db.select(db.outboxEntries).get();
      expect(queued.map((e) => e.entity), ['market_lot', 'market_lot_photo']);
      await repo.keepServerState(
        'l1',
        status: 'published',
        publishedAt: DateTime.utc(2026, 11, 7, 6),
      );
      expect((await repo.find('l1'))!.status, 'published');
      expect(await db.select(db.outboxEntries).get(), hasLength(2));

      await repo.applyRemoteLot(
        RemoteChange(
          entity: 'market_lot',
          entityId: 'l2',
          data: {
            ...sampleLot(id: 'l2').toPayload(),
            'crop': 'santra',
            'variety': null,
            'status': 'closed',
            'published_at': '2026-11-07T06:00:00Z',
          },
          updatedAt: DateTime.utc(2026, 11, 7),
        ),
      );
      expect((await repo.find('l2'))!.status, 'closed');
      await repo.applyRemotePhoto(
        RemoteChange(
          entity: 'market_lot_photo',
          entityId: 'f1',
          data: samplePhoto('f1', key: 'u1/f1.jpg').toPayload(),
          updatedAt: DateTime.utc(2026, 11, 7),
        ),
      );
      final [photo] = await repo.photosOf('l1');
      expect(photo.photoKey, 'u1/f1.jpg');
      // A server upsert keeps the file on this phone.
      expect(photo.photoPath, '/docs/market_lot_photos/f1.jpg');
    },
  );

  test('deleting a draft deletes its photos too', () async {
    await repo.save(sampleLot());
    await repo.savePhoto(samplePhoto('f1'));
    await repo.delete('l1');
    expect(await repo.find('l1'), isNull);
    expect(await repo.photosOf('l1'), isEmpty);
    final ops = [
      for (final e in await db.select(db.outboxEntries).get())
        '${e.entity}:${e.op}',
    ];
    expect(ops, contains('market_lot_photo:delete'));
    expect(ops.last, 'market_lot:delete');
  });
}
