import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/features/scouting/data/photo_backup.dart';
import 'package:bagmitra/features/scouting/data/scouting_repository.dart';
import 'package:bagmitra/sync/outbox.dart';
import 'package:bagmitra/sync/transport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;
import 'scouting_test.dart' show outbox, seen;

const key1 = 'u1/s1.jpg';

/// Answers like the API and the bucket would, and remembers every call.
class FakeApi implements PhotoBackupApi {
  final calls = <String>[];
  Object? uploadUrlError;
  Object? putError;
  Object? downloadError;
  List<int> served = const [9, 9];

  @override
  Future<PhotoUploadTicket> uploadUrl(String recordId, int sizeBytes) async {
    calls.add('upload-url $recordId $sizeBytes');
    if (uploadUrlError case final e?) throw e;
    return PhotoUploadTicket(
      Uri.parse('https://store.test/up/$recordId'),
      'u1/$recordId.jpg',
    );
  }

  @override
  Future<void> put(Uri url, List<int> bytes) async {
    calls.add('put $url');
    if (putError case final e?) throw e;
  }

  @override
  Future<Uri> downloadUrl(String recordId) async {
    calls.add('download-url $recordId');
    if (downloadError case final e?) throw e;
    return Uri.parse('https://store.test/get/$recordId');
  }

  @override
  Future<List<int>> get(Uri url) async {
    calls.add('get $url');
    return served;
  }
}

class FakeFiles implements PhotoFiles {
  final files = <String, List<int>>{'/docs/s1.jpg': List.filled(1000, 1)};

  @override
  Future<List<int>?> read(String path) async => files[path];

  @override
  Future<String> store(String recordId, List<int> bytes) async {
    final path = '/docs/scouting_photos/$recordId.jpg';
    files[path] = bytes;
    return path;
  }
}

class FakeNetwork implements NetworkCheck {
  FakeNetwork({this.wifi = true});
  bool wifi;
  @override
  Future<bool> onWifi() async => wifi;
}

class Rig {
  Rig({bool wifi = true}) : network = FakeNetwork(wifi: wifi) {
    repo = ScoutingRepository(db, clock: clock.call);
    backup = ScoutingPhotoBackup(
      repo: repo,
      api: api,
      files: files,
      outbox: Outbox(db, clock: clock.call),
      prefs: PhotoBackupPrefs(db),
      network: network,
      clock: clock.call,
      random: Random(1),
      log: logs.add,
    );
  }

  final db = memoryDb();
  final clock = TestClock();
  final api = FakeApi();
  final files = FakeFiles();
  final FakeNetwork network;
  final logs = <String>[];
  late final ScoutingRepository repo;
  late final ScoutingPhotoBackup backup;

  /// The sync engine pushed everything queued.
  Future<void> synced() => db.delete(db.outboxEntries).go();
}

Future<Rig> rigWithPhoto({bool wifi = true}) async {
  final rig = Rig(wifi: wifi);
  addTearDown(rig.db.close);
  await rig.repo.save(seen('s1', photo: '/docs/s1.jpg'));
  return rig;
}

void main() {
  test('uploads only after the record synced, then queues the key', () async {
    final rig = await rigWithPhoto();
    expect(await rig.backup.uploadPending(), 0); // record still in the outbox
    expect(rig.api.calls, isEmpty);

    await rig.synced();
    expect(await rig.backup.uploadPending(), 1);
    expect(rig.api.calls, [
      'upload-url s1 1000',
      'put https://store.test/up/s1',
    ]);
    final r = (await rig.repo.find('s1'))!;
    expect(r.photoKey, key1);
    expect(r.backedUp, isTrue);
    expect(r.photoPath, '/docs/s1.jpg');
    final queued = (await outbox(rig.db)).single;
    final payload = jsonDecode(queued.payload) as Map<String, Object?>;
    expect(payload['photo_key'], key1);
    expect(payload['item'], 'psylla');
    expect(queued.payload, isNot(contains('/docs/')));

    // Done: nothing more to upload.
    await rig.synced();
    expect(await rig.backup.uploadPending(), 0);
    expect(rig.api.calls, hasLength(2));
  });

  test('Wi-Fi only unless mobile data is allowed', () async {
    final rig = await rigWithPhoto(wifi: false);
    await rig.synced();
    expect(await rig.backup.uploadPending(), 0);
    expect(rig.api.calls, isEmpty);
    final prefs = PhotoBackupPrefs(rig.db);
    expect(await prefs.mobileData(), isFalse);
    await prefs.setMobileData(true);
    expect(await rig.backup.uploadPending(), 1);
    await prefs.setMobileData(false);
    expect(await prefs.mobileData(), isFalse);
  });

  test('a failed upload is retried after a backoff', () async {
    final rig = await rigWithPhoto();
    await rig.synced();
    rig.api.putError = const PhotoBackupFailedException('upload http 500');
    expect(await rig.backup.uploadPending(), 0);
    expect(rig.logs.single, contains('upload http 500'));
    rig.api.putError = null;
    expect(await rig.backup.uploadPending(), 0); // not due yet
    expect(rig.api.calls, hasLength(2));
    rig.clock.advance(const Duration(minutes: 2));
    expect(await rig.backup.uploadPending(), 1);
    expect((await rig.repo.find('s1'))!.photoKey, key1);
  });

  test('503 (not configured) stops quietly until the next start', () async {
    final rig = await rigWithPhoto();
    await rig.repo.save(seen('s2', photo: '/docs/s1.jpg'));
    await rig.synced();
    rig.api.uploadUrlError = const PhotoBackupOffException();
    expect(await rig.backup.uploadPending(), 0);
    expect(rig.backup.off, isTrue);
    expect(rig.api.calls, ['upload-url s1 1000']); // s2 not even tried
    expect(rig.logs, isEmpty);
    rig.clock.advance(const Duration(days: 1));
    expect(await rig.backup.uploadPending(), 0);
    final other = seen('s3').withPhoto(key: 'u1/s3.jpg');
    expect(await rig.backup.localPhoto(other), isNull);
    expect(rig.api.calls, hasLength(1));
  });

  test('a refused or missing photo is not retried', () async {
    final rig = await rigWithPhoto();
    await rig.repo.save(seen('s2', photo: '/gone/s2.jpg'));
    await rig.synced();
    rig.api.uploadUrlError = const PhotoBackupRefusedException('http 413');
    expect(await rig.backup.uploadPending(), 0);
    rig.api.uploadUrlError = null;
    rig.clock.advance(const Duration(days: 1));
    expect(await rig.backup.uploadPending(), 0);
    expect(rig.api.calls, ['upload-url s1 1000']);
    expect(rig.logs, hasLength(2));
    expect(rig.logs.last, contains('file gone'));
  });

  test('another phone downloads a backed-up photo once and keeps it', () async {
    final rig = Rig();
    addTearDown(rig.db.close);
    await rig.repo.applyRemote(
      RemoteChange(
        entity: ScoutingRepository.entity,
        entityId: 's1',
        data: seen('s1').withPhoto(key: key1).toPayload(),
        updatedAt: DateTime.utc(2026, 10, 12),
      ),
    );
    final remote = (await rig.repo.find('s1'))!;
    expect(remote.photoKey, key1);
    expect(remote.photoPath, isNull);
    // Nothing to upload: it is already backed up.
    expect(await rig.repo.photosToBackUp(), isEmpty);

    final path = await rig.backup.localPhoto(remote);
    expect(path, '/docs/scouting_photos/s1.jpg');
    expect(rig.files.files[path], [9, 9]);
    expect(rig.api.calls, ['download-url s1', 'get https://store.test/get/s1']);
    final cached = (await rig.repo.find('s1'))!;
    expect(cached.photoPath, path);
    expect(await rig.backup.localPhoto(cached), path);
    expect(rig.api.calls, hasLength(2));
    expect(await outbox(rig.db), isEmpty); // the local copy is never synced

    // A server echo keeps the downloaded file.
    await rig.repo.applyRemote(
      RemoteChange(
        entity: ScoutingRepository.entity,
        entityId: 's1',
        data: seen('s1', severity: 'high').withPhoto(key: key1).toPayload(),
        updatedAt: DateTime.utc(2026, 10, 13),
      ),
    );
    expect((await rig.repo.find('s1'))!.photoPath, path);
  });

  test('a failed download gives no photo and can be tried again', () async {
    final rig = Rig();
    addTearDown(rig.db.close);
    final r = seen('s1').withPhoto(key: key1);
    expect(await rig.backup.localPhoto(seen('s9')), isNull); // no photo at all
    rig.api.downloadError = const PhotoBackupFailedException('network');
    expect(await rig.backup.localPhoto(r), isNull);
    rig.api.downloadError = const PhotoBackupRefusedException('not found');
    expect(await rig.backup.localPhoto(r), isNull);
    expect(rig.logs, hasLength(2));
    rig.api.downloadError = const PhotoBackupOffException();
    expect(await rig.backup.localPhoto(r), isNull);
    expect(rig.backup.off, isTrue);
  });

  test('a record deleted before its photo key lands stays deleted', () async {
    final rig = await rigWithPhoto();
    await rig.repo.markBackedUp('nope', 'u1/nope.jpg');
    expect(await outbox(rig.db), hasLength(1)); // only the original save
  });

  test('Wi-Fi is recognised from interface names', () {
    expect(looksLikeWifi(['lo', 'wlan0']), isTrue);
    expect(looksLikeWifi(['en0', 'pdp_ip0']), isTrue);
    expect(looksLikeWifi(['rmnet_data0', 'ccmni1', 'pdp_ip0']), isFalse);
    expect(looksLikeWifi(const []), isFalse);
    expect(const InterfaceNetworkCheck().onWifi(), completion(isA<bool>()));
  });

  test('device files are read and stored in the photo folder', () async {
    final root = await Directory.systemTemp.createTemp('photo_files');
    addTearDown(() => root.delete(recursive: true));
    final files = DevicePhotoFiles(documents: () async => root);
    final path = await files.store('r1', [1, 2, 3]);
    expect(path, '${root.path}/scouting_photos/r1.jpg');
    expect(await files.read(path), [1, 2, 3]);
    expect(await files.read('${root.path}/missing.jpg'), isNull);
  });

  group('HttpPhotoBackupApi', () {
    late List<http.Request> seenRequests;

    HttpPhotoBackupApi apiWith(http.Response Function(http.Request) reply) {
      seenRequests = [];
      final client = MockClient((r) async {
        seenRequests.add(r);
        return reply(r);
      });
      return HttpPhotoBackupApi(
        createApi(
          baseUrl: Uri.parse('http://api.test'),
          token: () => 't',
          httpClient: client,
        ),
        client: client,
      );
    }

    http.Response json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

    test('asks for URLs and moves the bytes', () async {
      final api = apiWith(
        (r) => switch (r.url.path) {
          '/v1/scouting/s1/photo-upload-url' => json({
            'upload_url': 'https://store.test/up?token=u',
            'photo_key': key1,
            'expires_in': 7200,
            'content_type': 'image/jpeg',
            'max_bytes': 2097152,
          }),
          '/v1/scouting/s1/photo-url' => json({
            'url': 'https://store.test/get?token=d',
            'photo_key': key1,
            'expires_in': 300,
          }),
          '/get' => http.Response.bytes([7, 7], 200),
          _ => http.Response('', 200),
        },
      );
      final ticket = await api.uploadUrl('s1', 1234);
      expect(ticket.photoKey, key1);
      expect(ticket.uploadUrl.toString(), 'https://store.test/up?token=u');
      expect(jsonDecode(seenRequests.last.body), {
        'content_type': 'image/jpeg',
        'size_bytes': 1234,
      });
      expect(seenRequests.last.headers['Authorization'], 'Bearer t');
      await api.put(ticket.uploadUrl, [1, 2]);
      expect(seenRequests.last.method, 'PUT');
      expect(seenRequests.last.headers['Content-Type'], 'image/jpeg');
      expect(seenRequests.last.bodyBytes, [1, 2]);
      final url = await api.downloadUrl('s1');
      expect(await api.get(url), [7, 7]);
    });

    test('maps server answers to stop / skip / retry', () async {
      Future<Object?> error(
        int status,
        Future<void> Function(HttpPhotoBackupApi) call,
      ) async {
        final api = apiWith(
          (_) => json({
            'error': {'code': 'x', 'message': 'x', 'request_id': 'r'},
          }, status),
        );
        try {
          await call(api);
        } on Object catch (e) {
          return e;
        }
        return null;
      }

      Future<void> up(HttpPhotoBackupApi a) => a.uploadUrl('s1', 1);
      Future<void> down(HttpPhotoBackupApi a) => a.downloadUrl('s1');
      Future<void> put(HttpPhotoBackupApi a) =>
          a.put(Uri.parse('https://store.test/up'), [1]);
      Future<void> get(HttpPhotoBackupApi a) =>
          a.get(Uri.parse('https://store.test/get'));
      expect(await error(503, up), isA<PhotoBackupOffException>());
      expect(await error(503, down), isA<PhotoBackupOffException>());
      expect(await error(413, up), isA<PhotoBackupRefusedException>());
      expect(await error(404, down), isA<PhotoBackupRefusedException>());
      expect(await error(502, up), isA<PhotoBackupFailedException>());
      expect(await error(500, put), isA<PhotoBackupFailedException>());
      expect(await error(404, get), isA<PhotoBackupRefusedException>());
      expect(await error(500, get), isA<PhotoBackupFailedException>());
      expect((await error(500, put)).toString(), contains('upload http 500'));
    });

    test('network trouble is a retry', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('offline'),
      );
      final api = HttpPhotoBackupApi(
        createApi(
          baseUrl: Uri.parse('http://api.test'),
          token: () => null,
          httpClient: client,
        ),
        client: client,
      );
      await expectLater(
        api.uploadUrl('s1', 1),
        throwsA(isA<PhotoBackupFailedException>()),
      );
      await expectLater(
        api.get(Uri.parse('https://store.test/get')),
        throwsA(isA<PhotoBackupFailedException>()),
      );
      final slow = HttpPhotoBackupApi(
        createApi(baseUrl: Uri.parse('http://api.test'), token: () => null),
        client: MockClient(
          (_) => Future.delayed(
            const Duration(seconds: 1),
            () => http.Response('', 200),
          ),
        ),
        timeout: const Duration(milliseconds: 10),
      );
      await expectLater(
        slow.put(Uri.parse('https://store.test/up'), [1]),
        throwsA(
          isA<PhotoBackupFailedException>().having(
            (e) => e.reason,
            'reason',
            'timeout',
          ),
        ),
      );
    });
  });

  testWidgets('the log marks backed-up photos and fetches them on view', (
    tester,
  ) async {
    final api = FakeApi();
    final files = FakeFiles();
    late final ScoutingPhotoBackup backup;
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/scouting',
      seed: (db) async {
        await seedPlot(db);
        final repo = ScoutingRepository(db);
        // Backed up from this phone, and one from another phone (no file here yet).
        await repo.save(seen('s1', photo: '/docs/s1.jpg').withPhoto(key: key1));
        await repo.applyRemote(
          RemoteChange(
            entity: ScoutingRepository.entity,
            entityId: 's2',
            data: seen(
              's2',
              item: 'fruit_drop',
            ).withPhoto(key: 'u1/s2.jpg').toPayload(),
            updatedAt: DateTime.utc(2026, 10, 12),
          ),
        );
        await repo.save(seen('s3', item: 'die_back', photo: '/docs/s3.jpg'));
      },
      overrides: [
        scoutingPhotoBackupProvider.overrideWith((ref) {
          final db = ref.watch(databaseProvider);
          return backup = ScoutingPhotoBackup(
            repo: ref.watch(scoutingRepositoryProvider),
            api: api,
            files: files,
            outbox: Outbox(db),
            prefs: PhotoBackupPrefs(db),
            network: FakeNetwork(),
          );
        }),
      ],
    );
    await settle(tester);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await settle(tester);
    expect(find.byKey(const Key('photo-backed-up')), findsNWidgets(2));
    expect(
      tester
          .widget<Icon>(find.byKey(const Key('photo-backed-up')).first)
          .semanticLabel,
      'Photo backed up',
    );
    expect(backup.off, isFalse);
    expect(api.calls, contains('download-url s2'));
    final s2 = await tester.runAsync(() => ScoutingRepository(db).find('s2'));
    expect(s2?.photoPath, '/docs/scouting_photos/s2.jpg');
    await unmountApp(tester);
  });

  testWidgets('settings: photos on mobile data is off until turned on', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/settings',
    );
    await settle(tester);
    expect(find.text('Back up photos on mobile data'), findsOneWidget);
    final toggle = find.byKey(const Key('photo-backup-mobile-data'));
    await tester.ensureVisible(toggle);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    await tester.tap(toggle);
    await settle(tester);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    expect(
      await tester.runAsync(() => PhotoBackupPrefs(db).mobileData()),
      isTrue,
    );
    await unmountApp(tester);
  });
}
