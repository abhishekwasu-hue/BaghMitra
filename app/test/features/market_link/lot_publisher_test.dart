import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/accounts/domain/fair_price.dart';
import 'package:bagmitra/features/market_link/data/lot_publisher.dart';
import 'package:bagmitra/features/market_link/data/market_lot_repository.dart';
import 'package:bagmitra/features/scouting/data/photo_backup.dart';
import 'package:bagmitra/sync/outbox.dart';
import 'package:bagmitra/sync/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_db.dart';
import 'market_lot_repository_test.dart' show sampleLot, samplePhoto;

class FakeLotApi implements LotApi {
  final uploads = <String>[];
  final changes = <String>[];
  String? failWith;
  String orchard = 'inside';

  @override
  Future<String> upload(String photoId, List<int> bytes) async {
    uploads.add(photoId);
    return 'u1/$photoId.jpg';
  }

  @override
  Future<ServerLotState> change(String lotId, String action) async {
    if (failWith != null) throw LotApiException(failWith!);
    changes.add('$action:$lotId');
    return ServerLotState(
      action == 'close' ? 'closed' : 'published',
      DateTime.utc(2026, 11, 7, 6),
      orchard,
    );
  }
}

class FakeFiles implements PhotoFiles {
  bool gone = false;
  @override
  Future<List<int>?> read(String path) async => gone ? null : [1, 2, 3];
  @override
  Future<String> store(String recordId, List<int> bytes) async => '/x';
}

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

  test("the day's mandi price: local market first, nothing on another day", () {
    final day = DateTime(2026, 10, 13);
    final prices = [
      MandiPrice(
        market: 'Azadpur',
        day: day,
        modalRsPerQuintal: 5200,
        isMajor: true,
      ),
      MandiPrice(
        market: 'Warud',
        day: day,
        modalRsPerQuintal: 3300,
        isLocal: true,
      ),
    ];
    expect(mandiPriceOn(day, prices)!.market, 'Warud');
    expect(mandiPriceOn(DateTime(2026, 10, 12), prices), isNull);
  });

  group('publisher', () {
    late FakeLotApi api;
    late FakeFiles files;
    late List<String> syncs;
    var offline = false;

    LotPublisher publisher() => LotPublisher(
      repo: repo,
      api: api,
      files: files,
      outbox: outbox,
      sync: () async {
        syncs.add('sync');
        if (offline) return const SyncRunResult(offline: true);
        // The fake server takes everything queued.
        await db.delete(db.outboxEntries).go();
        return const SyncRunResult();
      },
    );

    setUp(() async {
      api = FakeLotApi();
      files = FakeFiles();
      syncs = [];
      offline = false;
      await repo.save(sampleLot());
      await repo.savePhoto(samplePhoto('f1'));
      await repo.savePhoto(samplePhoto('f2', key: 'u1/f2.jpg'));
    });

    test(
      'uploads the photos not yet uploaded, sends the keys, publishes',
      () async {
        expect(await publisher().publish('l1'), PublishOutcome.published);
        expect(api.uploads, ['f1']);
        expect(api.changes, ['publish:l1']);
        expect(syncs, hasLength(2));
        expect((await repo.find('l1'))!.status, 'published');
        expect((await repo.photosOf('l1')).map((p) => p.photoKey), [
          'u1/f1.jpg',
          'u1/f2.jpg',
        ]);
        expect((await repo.find('l1'))!.awaitingCheck, isFalse);
        expect(await publisher().close('l1'), PublishOutcome.closed);
        expect((await repo.find('l1'))!.status, 'closed');
      },
    );

    test('offline, a gone file and server refusals say why', () async {
      offline = true;
      expect(await publisher().publish('l1'), PublishOutcome.offline);
      expect(api.changes, isEmpty);
      offline = false;
      files.gone = true;
      expect(await publisher().publish('l1'), PublishOutcome.photoMissing);
      files.gone = false;
      for (final (code, outcome) in [
        ('lot_photos_needed', PublishOutcome.photosNeeded),
        ('terms_not_accepted', PublishOutcome.notAccepted),
        ('lot_not_draft', PublishOutcome.failed),
      ]) {
        api.failWith = code;
        expect(await publisher().publish('l1'), outcome);
      }
      expect((await repo.find('l1'))!.status, 'draft');
    });

    test(
      'photos away from the mapped orchard: published, waits for a check',
      () async {
        api.orchard = 'outside';
        expect(await publisher().publish('l1'), PublishOutcome.orchardCheck);
        final lot = (await repo.find('l1'))!;
        expect(lot.status, 'published');
        expect(lot.awaitingCheck, isTrue);
      },
    );

    test('a write the server has not taken stops the publish', () async {
      final p = LotPublisher(
        repo: repo,
        api: api,
        files: files,
        outbox: outbox,
        sync: () async => const SyncRunResult(),
      );
      expect(await p.publish('l1'), PublishOutcome.failed);
      expect(api.uploads, isEmpty);
    });
  });
}
