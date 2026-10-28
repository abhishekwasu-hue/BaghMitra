import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/features/labels/data/label_claims_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;

Map<String, Object?> claim({
  required String ai,
  required String target,
  required String dose,
  int? phi,
  int? interval,
  int? maxSprays,
}) => {
  'active_ingredient': ai,
  'formulation': '25% SC',
  'target': target,
  'dose': dose,
  'interval_days': interval,
  'phi_days': phi,
  'max_sprays': maxSprays,
  'label_crop': 'Citrus',
  'source_key': 'cibrc_major_uses',
  'source_title': 'CIB&RC major uses of pesticides',
  'source_url': 'https://ppqs.gov.in/major-uses',
};

Map<String, Object?> sampleClaims() => {
  'kind': 'label_information',
  'claims': [
    claim(
      ai: 'Azoxystrobin',
      target: 'Anthracnose',
      dose: '1.0 ml/L (500 L water/ha)',
      phi: 14,
      interval: 10,
      maxSprays: 2,
    ),
    claim(ai: 'Spinosad', target: 'Fruit fly', dose: '0.3 ml/L'),
    claim(ai: 'Mancozeb', target: 'Anthracnose', dose: '2 g/L', phi: 7),
  ],
};

void main() {
  test('refresh stores claims for the crop; load works offline', () async {
    final db = memoryDb();
    addTearDown(db.close);
    var online = true;
    final requested = <Uri>[];
    final api = createApi(
      baseUrl: Uri.parse('https://api.example.test'),
      token: () => 't',
      httpClient: MockClient((req) async {
        requested.add(req.url);
        if (!online) throw http.ClientException('offline');
        return http.Response(jsonEncode(sampleClaims()), 200);
      }),
    );
    final cache = LabelClaimsCache(
      db,
      api: api,
      clock: () => DateTime.utc(2026, 10, 26, 6),
    );
    expect(await cache.load('santra'), isNull);
    expect(await cache.refresh('santra'), isTrue);
    expect(requested.single.path, '/v1/reference/label-claims');
    expect(requested.single.queryParameters['crop'], 'santra');

    online = false;
    expect(await cache.refresh('santra'), isFalse);
    final cached = (await cache.load('santra'))!;
    expect(cached.claims, hasLength(3));
    expect(cached.claims.first.dose, '1.0 ml/L (500 L water/ha)');
    expect(cached.savedAt, DateTime.utc(2026, 10, 26, 6));
    expect(await cache.load('mosambi'), isNull);
  });

  testWidgets('spray log opens label information grouped by target', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/sprays',
      seed: (db) async {
        await seedPlot(db);
        await db.writeMeta(
          LabelClaimsCache.keyFor('santra'),
          jsonEncode({
            'saved_at': '2026-10-26T06:00:00.000Z',
            'response': sampleClaims(),
          }),
        );
      },
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('open-labels')));
    await settle(tester);

    expect(find.textContaining('It is not a recommendation'), findsOneWidget);
    expect(find.text('1.0 ml/L (500 L water/ha)'), findsOneWidget);
    expect(find.textContaining('14 days before harvest'), findsOneWidget);
    expect(find.textContaining('10 days'), findsWidgets);
    expect(find.textContaining('Updated'), findsOneWidget);
    // One heading per target, both anthracnose claims under it.
    expect(find.text('Anthracnose'), findsOneWidget);
    expect(find.text('Fruit fly'), findsOneWidget);
    final heading = tester.getTopLeft(find.text('Anthracnose')).dy;
    final fly = tester.getTopLeft(find.text('Fruit fly')).dy;
    expect(
      tester.getTopLeft(find.text('2 g/L')).dy,
      inInclusiveRange(heading, fly),
    );
    expect(find.textContaining('CIB&RC major uses'), findsWidgets);
    await unmountApp(tester);
  });

  testWidgets('empty state keeps the banner and invents nothing', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/labels',
      seed: seedPlot,
    );
    await settle(tester);
    expect(find.textContaining('It is not a recommendation'), findsOneWidget);
    expect(
      find.text(
        'Registered label information appears here once it is available.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('days before harvest'), findsNothing);
    await unmountApp(tester);
  });
}
