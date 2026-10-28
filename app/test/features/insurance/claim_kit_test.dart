import 'dart:convert';
import 'dart:typed_data';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/insurance/data/claim_kit_repository.dart';
import 'package:bagmitra/features/insurance/data/claim_pdf.dart';
import 'package:bagmitra/features/insurance/domain/claim_kit.dart';
import 'package:bagmitra/features/plots/data/location_service.dart';
import 'package:bagmitra/features/plots/domain/geo.dart';
import 'package:bagmitra/features/weather/data/plot_weather_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/boundary_screen_test.dart' show ScriptedLocation;
import '../plots/plots_screen_test.dart' show settle;
import '../scouting/scouting_test.dart' show FakePhotos;

/// A real 1 x 1 PNG, so the PDF library can embed it like a kept photo.
final onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

final gps = ScriptedLocation([
  LocationReading.at(const LatLon(21.1458, 79.0882), accuracyM: 8),
]);

Future<void> seedClaim(AppDatabase db) async {
  await seedPlot(db, lat: 21.1458, lon: 79.0882);
  await ClaimKitRepository(db).save(
    ClaimKit(
      id: 'k1',
      plotId: 'p1',
      lossOn: DateTime(2026, 10, 12),
      note: 'रात्री गारपीट, फळगळ',
      done: const {'inform_72h', 'photos'},
      photos: [
        ClaimPhoto(
          id: 'f1',
          path: '/nope/f1.jpg',
          takenAt: DateTime(2026, 10, 12, 7, 30),
          lat: 21.1458,
          lon: 79.0882,
          accuracyM: 8,
        ),
      ],
    ),
  );
}

void main() {
  test('the PDF has a summary page and one page per readable photo', () async {
    final pdf = await claimKitPdf(
      summaryPng: onePixelPng,
      photos: [
        (bytes: onePixelPng, caption: '2026-10-28 14:05 · 21.1, 79.0'),
        (bytes: Uint8List.fromList([1, 2, 3]), caption: 'broken'),
      ],
    );
    expect(ascii.decode(pdf.take(5).toList()), '%PDF-');
    expect(latin1.decode(pdf), contains('/Count 2'));
  });

  testWidgets('grower builds a claim kit with stamped photos and shares it', (
    tester,
  ) async {
    final sharer = RecordingSharer();
    final photos = FakePhotos(picked: '/tmp/loss.jpg');
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/claim-kit?plot=p1',
      seed: (db) => seedPlot(db, lat: 21.1458, lon: 79.0882),
      sharer: sharer,
      location: gps,
      overrides: [
        claimPhotosProvider.overrideWithValue(photos),
        claimPhotoBytesProvider.overrideWithValue((_) async => onePixelPng),
      ],
    );
    await settle(tester);
    expect(find.text('No photos yet.'), findsOne);
    expect(find.byKey(const Key('claim-check-policy')), findsOne);
    await tester.tap(find.byKey(const Key('claim-camera')));
    await settle(tester);
    expect(find.textContaining('21.14580, 79.08820 (±8 m)'), findsOne);
    expect(photos.kept.keys, ['/tmp/loss.jpg']);

    await tester.enterText(
      find.byKey(const Key('claim-note')),
      'Hail at night',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('check-panchnama')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('check-panchnama')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('claim-share')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    await settle(tester);

    final file = sharer.shared.single;
    expect(file.fileName, 'bagmitra-claim-p1-2026-10-13.pdf');
    expect(file.mimeType, 'application/pdf');
    expect(latin1.decode(file.bytes), contains('/Count 2'));
    final kits = await tester.runAsync(
      () => ClaimKitRepository(db).watchAll().first,
    );
    final kit = kits!.single;
    expect(kit.note, 'Hail at night');
    expect(kit.done, {'panchnama'});
    expect(kit.photos.single.lat, 21.1458);
    // Only the seeded plot is queued: the kit itself never goes to the server.
    final queued = await tester.runAsync(() => db.select(db.outboxEntries).get());
    expect([for (final e in queued!) e.entity], ['plot']);
    await unmountApp(tester);
  });

  testWidgets('a plot must be picked; a photo without GPS says so', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/claim-kit',
      seed: seedPlot,
      location: ScriptedLocation([
        const LocationReading.problem(LocationProblem.denied),
      ]),
      overrides: [claimPhotosProvider.overrideWithValue(FakePhotos())],
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('claim-gallery')));
    await settle(tester);
    expect(find.textContaining('GPS not available'), findsOne);
    await tester.tap(find.byKey(const Key('claim-save')));
    await settle(tester);
    expect(find.text('Pick a plot'), findsOne);
    await unmountApp(tester);
  });

  testWidgets('a saved kit reopens from the plot and can be deleted', (
    tester,
  ) async {
    final photos = FakePhotos();
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/insurance',
      seed: seedClaim,
      overrides: [claimPhotosProvider.overrideWithValue(photos)],
    );
    await settle(tester);
    expect(find.text('Loss on 12 Oct 2026 · photos: 1'), findsOne);
    await tester.tap(find.byKey(const Key('claim-k1')));
    await settle(tester);
    expect(find.text('रात्री गारपीट, फळगळ'), findsOne);
    expect(find.textContaining('2026-10-12 07:30'), findsOne);
    await tester.tap(find.byKey(const Key('delete-claim')));
    await settle(tester);
    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect(photos.discarded, ['/nope/f1.jpg']);
    expect(find.byKey(const Key('claim-k1')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('a storm alert links to the claim kit for its plot', (
    tester,
  ) async {
    Future<void> seed(AppDatabase db) async {
      await seedPlot(db, lat: 21.1458, lon: 79.0882);
      await db.writeMeta(
        PlotWeatherCache.keyFor('p1', 'en'),
        jsonEncode({
          'saved_at': '2026-10-13T05:00:00Z',
          'weather': {
            'days': <Object>[],
            'stale': false,
            'alerts': [
              {
                'rule_key': 'hail_thunderstorm',
                'first_day': '2026-10-14',
                'value': 95,
                'units': null,
                'text': 'Thunderstorm expected, hail possible.',
                'source': 'Open-Meteo weather_code',
                'status': 'draft',
                'action': 'claim_kit',
              },
            ],
          },
        }),
      );
    }

    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1',
      seed: seed,
    );
    await settle(tester);
    final link = find.byKey(const Key('alert-claim-kit-hail_thunderstorm'));
    expect(link, findsOne);
    await tester.tap(link);
    await settle(tester);
    expect(find.text('Claim kit'), findsOne);
    expect(find.text('बाग १'), findsOne); // the alert's plot is picked
    await unmountApp(tester);
  });
}
