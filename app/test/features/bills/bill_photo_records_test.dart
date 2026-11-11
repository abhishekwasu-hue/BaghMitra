import 'dart:convert';
import 'dart:math';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/accounts/data/accounts_repository.dart';
import 'package:bagmitra/features/accounts/domain/accounts.dart';
import 'package:bagmitra/features/bills/data/bill_photos.dart';
import 'package:bagmitra/features/scouting/data/photo_backup.dart';
import 'package:bagmitra/features/scouting/data/scouting_repository.dart';
import 'package:bagmitra/features/spray/data/spray_repository.dart';
import 'package:bagmitra/features/spray/domain/spray_record.dart';
import 'package:bagmitra/sync/outbox.dart';
import 'package:bagmitra/sync/transport.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/test_db.dart';
import '../scouting/photo_backup_test.dart' show FakeApi, FakeNetwork;
import '../scouting/scouting_test.dart' show FakePhotos;

SprayRecord spray(String id, {String? bill}) => SprayRecord(
  id: id,
  plotId: 'p1',
  sprayedOn: DateTime(2026, 10, 10),
  productName: 'Imida 17.8 SL',
  costPaise: 65000,
  billPhotoPath: bill,
);

Expense expense(String id, {String? bill}) => Expense(
  id: id,
  plotId: 'p1',
  spentOn: DateTime(2026, 10, 10),
  category: 'other',
  amountPaise: 215000,
  billPhotoPath: bill,
);

Future<List<OutboxEntry>> queued(AppDatabase db, String entity) =>
    (db.select(db.outboxEntries)..where((t) => t.entity.equals(entity))).get();

/// The bill photo URL calls, as the API answers them.
class FakeBillApi implements BillPhotoBackupApi {
  final calls = <String>[];

  @override
  Future<PhotoUploadTicket> billUploadUrl(
    BillKind kind,
    String recordId,
    int sizeBytes,
  ) async {
    calls.add('bill-upload-url ${kind.wire} $recordId $sizeBytes');
    return PhotoUploadTicket(
      Uri.parse('https://store.test/up/bill-$recordId'),
      'u1/bill-$recordId.jpg',
    );
  }

  @override
  Future<Uri> billDownloadUrl(BillKind kind, String recordId) async {
    calls.add('bill-download-url ${kind.wire} $recordId');
    return Uri.parse('https://store.test/get/bill-$recordId');
  }
}

class FakeBillFiles implements PhotoFiles {
  final files = <String, List<int>>{
    '/docs/bill_photos/s1.jpg': List.filled(700, 1),
    '/docs/bill_photos/e1.jpg': List.filled(800, 1),
  };

  @override
  Future<List<int>?> read(String path) async => files[path];

  @override
  Future<String> store(String recordId, List<int> bytes) async {
    final path = '/docs/bill_photos/$recordId.jpg';
    files[path] = bytes;
    return path;
  }
}

void main() {
  group('spray record bill photo', () {
    test('the path stays on the phone; the key syncs only once set', () async {
      final db = memoryDb();
      addTearDown(db.close);
      final repo = SprayRepository(db);
      await repo.save(spray('s1', bill: '/docs/bill_photos/s1.jpg'));
      final kept = (await repo.find('s1'))!;
      expect(kept.billPhotoPath, '/docs/bill_photos/s1.jpg');
      expect(kept.hasBillPhoto, isTrue);
      final payload = (await queued(db, SprayRepository.entity)).single.payload;
      expect(payload, isNot(contains('/docs/')));
      expect(payload, isNot(contains('bill_photo')));

      await repo.markBillBackedUp('s1', 'u1/bill-s1.jpg');
      final last = (await queued(db, SprayRepository.entity)).last;
      final sent = jsonDecode(last.payload) as Map<String, Object?>;
      expect(sent['bill_photo_key'], 'u1/bill-s1.jpg');
      expect(sent['product_name'], 'Imida 17.8 SL');
      expect(await repo.billPhotosToBackUp(), isEmpty);
    });

    test(
      'a server change keeps the photo; a delete removes the file',
      () async {
        final db = memoryDb();
        addTearDown(db.close);
        final photos = FakePhotos();
        final repo = SprayRepository(db, photos: photos);
        await repo.save(spray('s1', bill: '/docs/bill_photos/s1.jpg'));
        await repo.applyRemote(
          RemoteChange(
            entity: SprayRepository.entity,
            entityId: 's1',
            data: {
              ...spray('s1').toPayload(),
              'product_name': 'Confidor',
              'bill_photo_key': 'u1/bill-s1.jpg',
            },
            updatedAt: DateTime.utc(2026, 10, 12),
          ),
        );
        final r = (await repo.find('s1'))!;
        expect(r.productName, 'Confidor');
        expect(r.billPhotoPath, '/docs/bill_photos/s1.jpg');
        expect(r.billPhotoKey, 'u1/bill-s1.jpg');

        await repo.delete('s1');
        expect(photos.discarded, ['/docs/bill_photos/s1.jpg']);
        expect(await repo.find('s1'), isNull);
      },
    );
  });

  group('expense bill photo', () {
    test('kept, backed-up key queued, removed with the expense', () async {
      final db = memoryDb();
      addTearDown(db.close);
      final photos = FakePhotos();
      final repo = AccountsRepository(db, photos: photos);
      await repo.saveExpense(expense('e1', bill: '/docs/bill_photos/e1.jpg'));
      expect(
        (await repo.findExpense('e1'))!.billPhotoPath,
        '/docs/bill_photos/e1.jpg',
      );
      expect(await repo.billPhotosToBackUp(), [
        (id: 'e1', path: '/docs/bill_photos/e1.jpg'),
      ]);
      await repo.markBillBackedUp('e1', 'u1/bill-e1.jpg');
      final sent = jsonDecode(
        (await queued(db, AccountsRepository.expenseEntity)).last.payload,
      ) as Map<String, Object?>;
      expect(sent['bill_photo_key'], 'u1/bill-e1.jpg');
      expect(await repo.billPhotoOf('e1'), (
        path: '/docs/bill_photos/e1.jpg',
        key: 'u1/bill-e1.jpg',
      ));

      await repo.applyRemoteExpense(
        RemoteChange(
          entity: AccountsRepository.expenseEntity,
          entityId: 'e1',
          deleted: true,
          data: const {},
          updatedAt: DateTime.utc(2026, 10, 12),
        ),
      );
      expect(photos.discarded, ['/docs/bill_photos/e1.jpg']);
    });
  });

  group('photo backup', () {
    Future<
      ({
        AppDatabase db,
        FakeApi api,
        FakeBillApi bills,
        FakeBillFiles files,
        ScoutingPhotoBackup backup,
        SprayRepository sprays,
        AccountsRepository accounts,
      })
    >
    rig({bool wifi = true}) async {
      final db = memoryDb();
      addTearDown(db.close);
      final clock = TestClock();
      final api = FakeApi();
      final bills = FakeBillApi();
      final files = FakeBillFiles();
      final sprays = SprayRepository(db, clock: clock.call);
      final accounts = AccountsRepository(db, clock: clock.call);
      final backup = ScoutingPhotoBackup(
        repo: ScoutingRepository(db, clock: clock.call),
        api: api,
        files: files,
        outbox: Outbox(db, clock: clock.call),
        prefs: PhotoBackupPrefs(db),
        network: FakeNetwork(wifi: wifi),
        clock: clock.call,
        random: Random(1),
        bills: [
          BillBackupTarget(
            kind: BillKind.spray,
            records: sprays,
            api: bills,
            files: files,
          ),
          BillBackupTarget(
            kind: BillKind.expense,
            records: accounts,
            api: bills,
            files: files,
          ),
        ],
      );
      return (
        db: db,
        api: api,
        bills: bills,
        files: files,
        backup: backup,
        sprays: sprays,
        accounts: accounts,
      );
    }

    test(
      'bill photos ride the scouting backup after their record synced',
      () async {
        final r = await rig();
        await r.sprays.save(spray('s1', bill: '/docs/bill_photos/s1.jpg'));
        await r.accounts.saveExpense(
          expense('e1', bill: '/docs/bill_photos/e1.jpg'),
        );
        expect(await r.backup.uploadPending(), 0); // records still queued
        await r.db.delete(r.db.outboxEntries).go();

        expect(await r.backup.uploadPending(), 2);
        expect(r.bills.calls, [
          'bill-upload-url spray_record s1 700',
          'bill-upload-url expense e1 800',
        ]);
        expect(r.api.calls, [
          'put https://store.test/up/bill-s1',
          'put https://store.test/up/bill-e1',
        ]);
        expect((await r.sprays.find('s1'))!.billPhotoKey, 'u1/bill-s1.jpg');
        expect(
          (await r.accounts.findExpense('e1'))!.billPhotoKey,
          'u1/bill-e1.jpg',
        );
        expect(await r.backup.uploadPending(), 0);
      },
    );

    test('nothing goes on mobile data unless the grower allows it', () async {
      final r = await rig(wifi: false);
      await r.sprays.save(spray('s1', bill: '/docs/bill_photos/s1.jpg'));
      await r.db.delete(r.db.outboxEntries).go();
      expect(await r.backup.uploadPending(), 0);
      await PhotoBackupPrefs(r.db).setMobileData(true);
      expect(await r.backup.uploadPending(), 1);
    });

    test('a backed-up bill photo is downloaded once to be seen', () async {
      final r = await rig();
      await r.db
          .into(r.db.sprayRecords)
          .insert(
            SprayRecordsCompanion.insert(
              id: 's9',
              plotId: 'p1',
              sprayedOn: DateTime(2026, 10, 10),
              productName: 'Imida',
              costPaise: 0,
              clientUpdatedAt: DateTime.utc(2026),
              billPhotoKey: const Value('u1/bill-s9.jpg'),
            ),
          );
      final path = await r.backup.localBillPhoto(BillKind.spray, 's9');
      expect(path, '/docs/bill_photos/s9.jpg');
      expect(r.bills.calls, ['bill-download-url spray_record s9']);
      expect((await r.sprays.find('s9'))!.billPhotoPath, path);
      expect(await r.backup.localBillPhoto(BillKind.spray, 's9'), path);
      expect(r.bills.calls, hasLength(1));
      expect(await r.backup.localBillPhoto(BillKind.expense, 'none'), isNull);
    });
  });

  test('the HTTP client asks the bill photo URLs by kind', () async {
    final seen = <http.Request>[];
    final client = MockClient((r) async {
      seen.add(r);
      return http.Response(
        r.url.path.endsWith('upload-url')
            ? jsonEncode({
                'upload_url': 'https://store.test/up?token=u',
                'photo_key': 'u1/bill-e1.jpg',
                'expires_in': 7200,
                'content_type': 'image/jpeg',
                'max_bytes': 2097152,
              })
            : jsonEncode({
                'url': 'https://store.test/get?token=d',
                'photo_key': 'u1/bill-s1.jpg',
                'expires_in': 300,
              }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = HttpPhotoBackupApi(
      createApi(
        baseUrl: Uri.parse('http://api.test'),
        token: () => 't',
        httpClient: client,
      ),
      client: client,
    );
    final ticket = await api.billUploadUrl(BillKind.expense, 'e1', 800);
    expect(ticket.photoKey, 'u1/bill-e1.jpg');
    final url = await api.billDownloadUrl(BillKind.spray, 's1');
    expect(url.toString(), 'https://store.test/get?token=d');
    expect(
      [for (final r in seen) '${r.method} ${r.url.path}'],
      [
        'POST /v1/bill-photos/expense/e1/upload-url',
        'GET /v1/bill-photos/spray_record/s1/url',
      ],
    );
    expect(jsonDecode(seen.first.body), {
      'content_type': 'image/jpeg',
      'size_bytes': 800,
    });
  });
}
