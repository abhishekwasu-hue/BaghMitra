import 'dart:convert';
import 'dart:io';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/insurance/data/claim_kit_repository.dart';
import 'package:bagmitra/features/insurance/data/insurance_repository.dart';
import 'package:bagmitra/features/insurance/domain/claim_kit.dart';
import 'package:bagmitra/features/insurance/domain/insurance_policy.dart';
import 'package:bagmitra/features/insurance/presentation/insurance_screens.dart';
import 'package:bagmitra/features/scouting/data/scouting_photos.dart';
import 'package:bagmitra/sync/transport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;
import '../scouting/scouting_test.dart' show FakePhotos;

InsurancePolicy policy(
  String id, {
  String scheme = 'rwbcis',
  String season = 'ambia',
  int? year = 2027,
  int? premium,
}) => InsurancePolicy(
  id: id,
  plotId: 'p1',
  scheme: scheme,
  season: season,
  seasonYear: year,
  insurerName: 'Example Insurance',
  policyNumber: 'APP-1',
  premiumPaidPaise: premium,
  enrolledOn: DateTime(2026, 10, 2),
);

InsuranceDeadline deadline(String id, {String? season, int inDays = 10}) =>
    InsuranceDeadline(
      itemId: id,
      title: 'हवामान आधारित फळपीक विमा योजना',
      dueDate: DateTime(2026, 10, 13).add(Duration(days: inDays)),
      url: 'https://example.org/n.pdf',
      season: season,
    );

Future<List<OutboxEntry>> outbox(AppDatabase db) => (db.select(
  db.outboxEntries,
)..where((t) => t.entity.equals(InsuranceRepository.entity))).get();

Future<void> seedPolicy(AppDatabase db) async {
  await seedPlot(db);
  await InsuranceRepository(db).save(policy('i1', premium: 123400));
}

void main() {
  test('the policy payload matches the API contract', () {
    final p = policy('i1', premium: 123400).toPayload();
    expect(p, {
      'plot_id': 'p1',
      'scheme': 'rwbcis',
      'season': 'ambia',
      'season_year': 2027,
      'insurer_name': 'Example Insurance',
      'policy_number': 'APP-1',
      'sum_insured_paise': null,
      'premium_paid_paise': 123400,
      'enrolled_on': '2026-10-02',
      'note': null,
    });
    expect(InsurancePolicy.fromPayload('i1', p).toPayload(), p);
  });

  test('policies are queued for sync and server changes apply', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final repo = InsuranceRepository(db, clock: TestClock().call);
    await repo.save(policy('i1'));
    await repo.save(policy('i2', season: 'mrig', year: 2028));
    expect(
      [for (final p in await repo.watchForPlot('p1').first) p.id],
      ['i2', 'i1'],
    );
    final queued = await outbox(db);
    expect(queued, hasLength(2));
    expect(jsonDecode(queued.first.payload), policy('i1').toPayload());

    await repo.applyRemote(
      RemoteChange(
        entity: InsuranceRepository.entity,
        entityId: 'i3',
        data: policy('i3', scheme: 'pmfby').toPayload(),
        updatedAt: DateTime.utc(2026, 10, 12),
      ),
    );
    expect((await repo.find('i3'))!.scheme, 'pmfby');
    await repo.applyRemote(
      RemoteChange(
        entity: InsuranceRepository.entity,
        entityId: 'i3',
        data: const {},
        updatedAt: DateTime.utc(2026, 10, 13),
        deleted: true,
      ),
    );
    expect(await repo.find('i3'), isNull);
    await repo.delete('i1');
    final last = (await outbox(db)).last;
    expect((last.op, last.entityId), ('delete', 'i1'));
  });

  test('deadlines show only for a matching bahar and before the date', () {
    final today = DateTime(2026, 10, 13);
    final all = [
      deadline('a', season: 'ambia'),
      deadline('m', season: 'mrig'),
      deadline('any'),
      deadline('past', inDays: -1),
    ];
    expect(
      [
        for (final d in deadlinesFor(all, [policy('i1')], today)) d.itemId,
      ],
      ['a', 'any'],
    );
    expect(
      [for (final d in deadlinesFor(all, const [], today)) d.itemId],
      ['a', 'm', 'any'],
    );
    expect(deadlinesFor(const [], [policy('i1')], today), isEmpty);
    expect(deadline('t', inDays: 0).appliesTo('ambia', today), isTrue);
  });

  test('a photo stamp gives date, time and GPS in Latin digits', () {
    final at = DateTime(2026, 10, 28, 14, 5);
    final p = ClaimPhoto(
      id: 'f1',
      path: '/x.jpg',
      takenAt: at,
      lat: 21.1458,
      lon: 79.0882,
      accuracyM: 12.4,
    );
    expect(
      p.stamp(noGps: '-'),
      '2026-10-28 14:05 · 21.14580, 79.08820 (±12 m)',
    );
    expect(
      ClaimPhoto(id: 'f2', path: '/y.jpg', takenAt: at).stamp(noGps: 'no GPS'),
      '2026-10-28 14:05 · no GPS',
    );
  });

  test('claim kits stay local and drop the files they no longer use', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final photos = FakePhotos();
    final repo = ClaimKitRepository(
      db,
      clock: TestClock().call,
      photos: photos,
    );
    final a = ClaimPhoto(
      id: 'f1',
      path: '/c/f1.jpg',
      takenAt: DateTime.utc(2026),
    );
    final b = ClaimPhoto(
      id: 'f2',
      path: '/c/f2.jpg',
      takenAt: DateTime.utc(2026, 1, 2),
      lat: 21,
      lon: 79,
    );
    await repo.save(
      ClaimKit(
        id: 'k1',
        plotId: 'p1',
        lossOn: DateTime(2026, 10, 12),
        note: 'गारपीट',
        done: const {'photos', 'inform_72h'},
        photos: [a, b],
      ),
    );
    final kit = (await repo.find('k1'))!;
    expect(kit.done, {'inform_72h', 'photos'});
    expect([for (final p in kit.photos) p.id], ['f1', 'f2']);
    expect(kit.photos.last.lat, 21);
    expect(await db.select(db.outboxEntries).get(), isEmpty);

    await repo.save(
      ClaimKit(id: 'k1', plotId: 'p1', lossOn: kit.lossOn, photos: [b]),
    );
    expect(photos.discarded, ['/c/f1.jpg']);
    expect((await repo.watchAll().first).single.photos.single.id, 'f2');

    await repo.delete('k1');
    expect(photos.discarded, ['/c/f1.jpg', '/c/f2.jpg']);
    expect(await repo.watchAll().first, isEmpty);
    expect(await repo.find('k1'), isNull);
  });

  test('loss photos are kept in their own folder', () async {
    final root = await Directory.systemTemp.createTemp('claim');
    addTearDown(() => root.delete(recursive: true));
    final picked = File('${root.path}/cache/p.jpg')
      ..createSync(recursive: true)
      ..writeAsBytesSync([1]);
    final photos = DeviceScoutingPhotos(
      documents: () async => root,
      folderName: 'claim_photos',
    );
    expect(
      await photos.keep(picked.path, 'f1'),
      '${root.path}/claim_photos/f1.jpg',
    );
  });

  testWidgets('a plot without policy or loss record shows the empty state', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/insurance',
      seed: seedPlot,
    );
    await settle(tester);
    expect(
      find.textContaining('Add the crop insurance you took for this plot'),
      findsOne,
    );
    expect(find.textContaining('Enrolment deadline'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('policies and only published, matching deadlines are shown', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/insurance',
      seed: seedPolicy,
      overrides: [
        insuranceDeadlinesProvider.overrideWith(
          (ref, lang) async => [
            deadline('a', season: 'ambia'),
            deadline('m', season: 'mrig'),
          ],
        ),
      ],
    );
    await settle(tester);
    expect(find.byKey(const Key('policy-i1')), findsOne);
    expect(find.textContaining('Weather-based fruit crop'), findsOne);
    expect(find.text('Premium paid ₹1,234'), findsOne);
    expect(find.byKey(const Key('deadline-a')), findsOne);
    expect(find.byKey(const Key('deadline-m')), findsNothing);
    expect(find.text('Enrolment deadline: 23 Oct 2026'), findsOne);
    await unmountApp(tester);
  });

  testWidgets('grower records a policy; amounts stay empty unless typed', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/insurance',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('add-policy')));
    await settle(tester);
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Choose one'), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('choice-pmfby')));
    await tester.tap(find.byKey(const Key('choice-mrig')));
    await tester.enterText(find.byKey(const Key('policy-number')), 'PM-77');
    await tester.enterText(find.byKey(const Key('policy-premium')), '1,500');
    await tester.tap(find.text('Save'));
    await settle(tester);
    final saved = await tester.runAsync(
      () => InsuranceRepository(db).watchForPlot('p1').first,
    );
    final p = saved!.single;
    expect((p.scheme, p.season, p.policyNumber), ('pmfby', 'mrig', 'PM-77'));
    expect(p.premiumPaidPaise, 150000);
    expect(p.sumInsuredPaise, isNull);
    expect(p.enrolledOn, isNull);
    expect(find.byKey(Key('policy-${p.id}')), findsOne);

    await tester.tap(find.byKey(Key('policy-${p.id}')));
    await settle(tester);
    expect(find.text('PM-77'), findsOne);
    await tester.tap(find.byKey(const Key('delete-policy')));
    await settle(tester);
    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect(find.byKey(Key('policy-${p.id}')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('the plot screen opens crop insurance', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('open-insurance')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('open-insurance')));
    await settle(tester);
    expect(find.text('Crop insurance'), findsWidgets);
    await unmountApp(tester);
  });
}
