import 'dart:convert';
import 'dart:io';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/scouting/data/scouting_photos.dart';
import 'package:bagmitra/features/scouting/data/scouting_repository.dart';
import 'package:bagmitra/features/scouting/domain/scouting_record.dart';
import 'package:bagmitra/features/voice/domain/speech.dart';
import 'package:bagmitra/sync/transport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;

ScoutingRecord seen(
  String id, {
  String item = 'psylla',
  String severity = 'medium',
  DateTime? on,
  String? note,
  String? photo,
}) => ScoutingRecord(
  id: id,
  plotId: 'p1',
  observedOn: on ?? DateTime(2026, 10, 10),
  item: item,
  severity: severity,
  note: note,
  photoPath: photo,
);

/// Hands out a made-up photo instead of opening the camera, and remembers what was kept.
class FakePhotos implements ScoutingPhotos {
  FakePhotos({
    this.picked = '/tmp/picked.jpg',
    this.fails = false,
    this.keepFails = false,
  });

  final String? picked;
  final bool fails;
  final bool keepFails;
  final sources = <PhotoSource>[];
  final kept = <String, String>{};
  final discarded = <String>[];

  @override
  Future<String?> pick(PhotoSource source) async {
    sources.add(source);
    if (fails) throw StateError('camera busy');
    return picked;
  }

  @override
  Future<String> keep(String pickedPath, String recordId) async {
    if (keepFails) throw const FileSystemException('disk full');
    final path = '/docs/scouting_photos/$recordId.jpg';
    kept[pickedPath] = path;
    return path;
  }

  @override
  Future<void> discard(String path) async => discarded.add(path);
}

Future<List<OutboxEntry>> outbox(AppDatabase db) => (db.select(
  db.outboxEntries,
)..where((t) => t.entity.equals(ScoutingRepository.entity))).get();

Future<void> seedScouting(AppDatabase db) async {
  await seedPlot(db);
  final repo = ScoutingRepository(db);
  await repo.save(seen('s1', note: 'नवीन फुटीवर', photo: '/nope/s1.jpg'));
  await repo.save(
    seen(
      's2',
      item: 'fruit_drop',
      severity: 'high',
      on: DateTime(2026, 10, 12),
    ),
  );
}

void main() {
  test('the payload matches the API contract and never carries the photo', () {
    final r = seen('s1', note: 'note', photo: '/docs/s1.jpg');
    final p = r.toPayload();
    expect(p['observed_on'], '2026-10-10');
    expect(p['item'], 'psylla');
    expect(p['severity'], 'medium');
    expect(p.containsKey('photo_path'), isFalse);
    expect(p.values, isNot(contains('/docs/s1.jpg')));
    final back = ScoutingRecord.fromPayload('s1', p);
    expect(back.toPayload(), p);
    expect(back.photoPath, isNull);
  });

  test(
    'repository queues writes atomically and keeps the photo local',
    () async {
      final db = memoryDb();
      addTearDown(db.close);
      final photos = FakePhotos();
      final repo = ScoutingRepository(
        db,
        clock: TestClock().call,
        photos: photos,
      );
      await repo.save(seen('s1', photo: '/docs/s1.jpg'));
      await repo.save(seen('s2', on: DateTime(2026, 10, 11), severity: 'none'));
      final list = await repo.watchForPlot('p1').first;
      expect([for (final r in list) r.id], ['s2', 's1']); // newest first
      expect(list.last.photoPath, '/docs/s1.jpg');
      expect(await repo.watchForPlot('other').first, isEmpty);

      final queued = await outbox(db);
      expect(queued, hasLength(2));
      expect(queued.every((e) => e.state == OutboxState.pending), isTrue);
      expect(queued.first.payload, isNot(contains('photo')));
      expect(jsonDecode(queued.first.payload), seen('s1').toPayload());

      // A server echo (or an edit from another phone) keeps the photo on this phone.
      await repo.applyRemote(
        RemoteChange(
          entity: ScoutingRepository.entity,
          entityId: 's1',
          data: seen('s1', severity: 'high').toPayload(),
          updatedAt: DateTime.utc(2026, 10, 12),
        ),
      );
      final s1 = (await repo.watchForPlot('p1').first).firstWhere(
        (r) => r.id == 's1',
      );
      expect(s1.severity, 'high');
      expect(s1.photoPath, '/docs/s1.jpg');

      await repo.applyRemote(
        RemoteChange(
          entity: ScoutingRepository.entity,
          entityId: 's3',
          data: seen('s3').toPayload(),
          updatedAt: DateTime.utc(2026, 10, 12),
        ),
      );
      expect(await repo.watchForPlot('p1').first, hasLength(3));

      // Tombstone from the server: the row and its photo go.
      await repo.applyRemote(
        RemoteChange(
          entity: ScoutingRepository.entity,
          entityId: 's1',
          data: const {},
          updatedAt: DateTime.utc(2026, 10, 13),
          deleted: true,
        ),
      );
      expect(photos.discarded, ['/docs/s1.jpg']);

      // A local delete is queued for the server.
      await repo.delete('s2');
      expect(
        [for (final r in await repo.watchForPlot('p1').first) r.id],
        ['s3'],
      );
      final last = (await outbox(db)).last;
      expect(last.op, 'delete');
      expect(last.entityId, 's2');
      expect(photos.discarded, hasLength(1)); // s2 had no photo
    },
  );

  test('device photos are copied into the app folder and removed', () async {
    final root = await Directory.systemTemp.createTemp('scouting');
    addTearDown(() => root.delete(recursive: true));
    final picked = File('${root.path}/cache/image_picker_1.jpg')
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);
    final photos = DeviceScoutingPhotos(documents: () async => root);
    final kept = await photos.keep(picked.path, 'r1');
    expect(kept, '${root.path}/scouting_photos/r1.jpg');
    expect(File(kept).readAsBytesSync(), [1, 2, 3]);
    final noExt = File('${root.path}/cache/shot')..writeAsBytesSync([4]);
    expect(
      await photos.keep(noExt.path, 'r2'),
      '${root.path}/scouting_photos/r2.jpg',
    );
    await photos.discard(kept);
    expect(File(kept).existsSync(), isFalse);
    await photos.discard(kept); // already gone: no error
    expect(DeviceScoutingPhotos.maxWidth, 1280);
    expect(DeviceScoutingPhotos.imageQuality, 70);
  });

  testWidgets('the log lists what was seen, newest first', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/scouting',
      seed: seedScouting,
    );
    await settle(tester);
    expect(find.text('Scouting log'), findsOneWidget);
    expect(find.text('Fruit drop'), findsOneWidget);
    expect(find.text('Psylla'), findsOneWidget);
    expect(find.textContaining('High ·'), findsOneWidget);
    expect(find.textContaining('Medium ·'), findsOneWidget);
    expect(find.text('नवीन फुटीवर'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Fruit drop')).dy,
      lessThan(tester.getTopLeft(find.text('Psylla')).dy),
    );
    expect(find.byType(Image), findsOneWidget); // s1's photo (file gone: icon)
    await tester.tap(find.text('Add scouting'));
    await settle(tester);
    expect(find.text('What did you look at?'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('an empty log says so; the plot screen opens it', (tester) async {
    await pumpApp(tester, initialLocation: '/plots/p1', seed: seedPlot);
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('open-scouting')),
      100,
    );
    await tester.tap(find.byKey(const Key('open-scouting')));
    await settle(tester);
    expect(find.text('पाहणी नोंद'), findsOneWidget);
    expect(
      find.text('अजून पाहणी नोंदवलेली नाही. या बागेत काय दिसले ते नोंदवा.'),
      findsOneWidget,
    );
    await unmountApp(tester);
  });

  testWidgets('saving needs what was seen and how much', (tester) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/scouting/new',
      seed: seedPlot,
      photos: FakePhotos(),
    );
    await settle(tester);
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Choose one'), findsNWidgets(2));
    await tester.tap(find.text('Leaf miner'));
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Choose one'), findsOneWidget);
    expect(await tester.runAsync(() => outbox(db)), isEmpty);
    await unmountApp(tester);
  });

  testWidgets('grower records an observation offline without a photo', (
    tester,
  ) async {
    final photos = FakePhotos();
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/scouting/new',
      seed: seedPlot,
      photos: photos,
      recognizer: FakeRecognizer(
        words: const [SpeechResult('few on new flush', isFinal: true)],
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Psylla'));
    await tester.tap(find.text('Low'));
    await tester.tap(find.byKey(const Key('voice-mic')));
    await settle(tester);
    expect(find.text('few on new flush'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await settle(tester);
    final entries = (await tester.runAsync(() => outbox(db)))!;
    final p = jsonDecode(entries.single.payload) as Map<String, Object?>;
    expect(p['item'], 'psylla');
    expect(p['severity'], 'low');
    expect(p['observed_on'], '2026-10-13');
    expect(p['note'], 'few on new flush');
    expect(entries.single.state, OutboxState.pending);
    final row = (await tester.runAsync(
      () => db.select(db.scoutingRecords).getSingle(),
    ))!;
    expect(row.photoPath, isNull);
    expect(photos.sources, isEmpty);
    await unmountApp(tester);
  });

  testWidgets('grower adds one photo; it is kept on the phone only', (
    tester,
  ) async {
    final photos = FakePhotos();
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/scouting/new',
      seed: seedPlot,
      photos: photos,
    );
    await settle(tester);
    await tester.tap(find.text('Gummosis / bark'));
    await tester.tap(find.text('High'));
    // Pick from the gallery, change our mind, then take one with the camera.
    await tester.tap(find.text('Gallery'));
    await settle(tester);
    expect(find.text('Remove photo'), findsOneWidget);
    await tester.tap(find.text('Remove photo'));
    await settle(tester);
    await tester.ensureVisible(find.text('Camera'));
    await tester.pump();
    await tester.tap(find.text('Camera'));
    await settle(tester);
    expect(photos.sources, [PhotoSource.gallery, PhotoSource.camera]);
    await tester.tap(find.text('Save'));
    await settle(tester);
    final row = (await tester.runAsync(
      () => db.select(db.scoutingRecords).getSingle(),
    ))!;
    expect(row.photoPath, '/docs/scouting_photos/${row.id}.jpg');
    expect(photos.kept.keys, ['/tmp/picked.jpg']);
    final payload = (await tester.runAsync(() => outbox(db)))!.single.payload;
    expect(payload, isNot(contains('photo')));
    expect(payload, isNot(contains('/docs/')));
    expect((jsonDecode(payload) as Map)['item'], 'gummosis_bark');
    await unmountApp(tester);
  });

  testWidgets('a cancelled or failed photo leaves the form as it was', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/scouting/new',
      seed: seedPlot,
      photos: FakePhotos(fails: true),
    );
    await settle(tester);
    await tester.ensureVisible(find.text('Camera'));
    await tester.pump();
    await tester.tap(find.text('Camera'));
    await settle(tester);
    expect(find.text('Could not get the photo. Try again.'), findsOneWidget);
    expect(find.text('Remove photo'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('a photo that cannot be kept saves nothing and says so', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/scouting/new',
      seed: seedPlot,
      photos: FakePhotos(keepFails: true),
    );
    await settle(tester);
    await tester.tap(find.text('Die-back'));
    await tester.tap(find.text('Not seen'));
    await tester.ensureVisible(find.text('Camera'));
    await tester.pump();
    await tester.tap(find.text('Camera'));
    await settle(tester);
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Could not get the photo. Try again.'), findsOneWidget);
    expect(await tester.runAsync(() => outbox(db)), isEmpty);
    await unmountApp(tester);
  });
}
