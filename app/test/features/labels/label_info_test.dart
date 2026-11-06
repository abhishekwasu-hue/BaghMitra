import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/features/app_update/data/app_update_providers.dart';
import 'package:bagmitra/features/labels/data/label_claims_cache.dart';
import 'package:bagmitra/features/labels/data/label_targets.dart';
import 'package:bagmitra/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_db.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;
import '../scouting/scouting_test.dart' show seedScouting;

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
    // One heading per target (the grower's name for it), both anthracnose claims under it;
    // the target as printed stays on every row.
    const anthracnose = 'Anthracnose, twig blight, dieback';
    expect(find.text(anthracnose), findsOneWidget);
    expect(find.text('Fruit fly'), findsOneWidget);
    expect(find.text('Target on label: Anthracnose'), findsNWidgets(2));
    final heading = tester.getTopLeft(find.text(anthracnose)).dy;
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

  group('WP4 label details (owner Q57)', () {
    Map<String, Object?> detailed() => {
      'kind': 'label_information',
      'claims': [
        {
          ...claim(ai: 'Chem A', target: 'Foot rot', dose: '500 g/ha', phi: 30),
          'category': 'chemical',
          'dilution': '500-1000',
          'page_ref': 'p. 9',
          'description': 'Contact fungicide.',
          'brand_names': ['Alpha', 'beta', 'Zeta'],
          'maker_url': 'https://maker.example/a',
          'photo_url': null,
        },
        {
          ...claim(ai: 'Bio B', target: 'Gummosis', dose: '2.5 kg/ha'),
          'category': 'bio',
          'dilution': '5 liter/tree',
        },
      ],
      'blocked': [
        {
          'active_ingredient': 'Banned C',
          'formulation': '20% EC',
          'target': 'Gummosis',
          'label_crop': 'Citrus',
          'reason': 'banned',
          'notification': 'S.O. 1(E)',
        },
      ],
    };

    Future<List<Uri>> open(WidgetTester tester, String location) async {
      final opened = <Uri>[];
      await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: location,
        overrides: [
          urlOpenerProvider.overrideWithValue((u) async {
            opened.add(u);
            return true;
          }),
        ],
        seed: (db) async {
          await seedPlot(db);
          await db.writeMeta(
            LabelClaimsCache.keyFor('santra'),
            jsonEncode({
              'saved_at': '2026-11-06T06:00:00.000Z',
              'response': detailed(),
            }),
          );
        },
      );
      await settle(tester);
      return opened;
    }

    testWidgets('dose and dilution bold; bio apart; banned red; maker link', (
      tester,
    ) async {
      final opened = await open(tester, '/plots/p1/labels?target=gummosis');
      expect(find.byKey(const Key('label-target-heading')), findsOneWidget);
      final dose = tester.widget<Text>(
        find.byKey(const Key('label-dose')).first,
      );
      expect(dose.data, '500 g/ha');
      expect(dose.style!.fontWeight, FontWeight.w700);
      final dilution = tester.widget<Text>(
        find.byKey(const Key('label-dilution')).first,
      );
      expect(dilution.data, 'Water on label: 500-1000 L per hectare');
      // A cell with its own unit is shown exactly as printed, without "L per hectare".
      expect(find.text('Water on label: 5 liter/tree'), findsOneWidget);
      expect(dilution.style!.fontWeight, FontWeight.w700);
      expect(find.byKey(const Key('label-bio-gummosis')), findsOneWidget);
      expect(find.text('Chemical'), findsOneWidget);
      // Bio row is under the bio heading, after the chemical row.
      expect(
        tester.getTopLeft(find.text('Bio B 25% SC')).dy,
        greaterThan(tester.getTopLeft(find.text('Chem A 25% SC')).dy),
      );
      expect(
        find.text('Brand names (A–Z, a plain list): Alpha, beta, Zeta'),
        findsOneWidget,
      );
      expect(find.text('Contact fungicide.'), findsOneWidget);
      expect(find.text('Page in source: p. 9'), findsOneWidget);
      expect(
        find.text('Read the label on the packet before spraying.'),
        findsOneWidget,
      );
      final general = find.textContaining('General information');
      await tester.scrollUntilVisible(
        general,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(general, findsOneWidget);

      final box = tester.widget<DecoratedBox>(
        find.byKey(const Key('label-blocked-Banned C')),
      );
      final danger = Theme.of(
        tester.element(find.byKey(const Key('label-blocked-Banned C'))),
      ).extension<BmColors>()!.danger;
      expect((box.decoration as BoxDecoration).border!.top.color, danger);
      expect(find.text('Banned: do not use'), findsOneWidget);
      final banned = tester.widget<Text>(find.text('Banned C 20% EC'));
      expect(banned.style!.color, danger);

      await tester.ensureVisible(find.byKey(const Key('label-maker-page')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('label-maker-page')));
      expect(opened.single, Uri.parse('https://maker.example/a'));
      await unmountApp(tester);
    });

    testWidgets('a target without a claim says so plainly', (tester) async {
      await open(tester, '/plots/p1/labels?target=thrips');
      expect(
        find.text('No registered label claim for Thrips on citrus.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('label-dose')), findsNothing);
      await tester.tap(find.byKey(const Key('label-all-targets')));
      await settle(tester);
      expect(find.byKey(const Key('label-group-gummosis')), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('practices, scouting and look-alikes open the target', (
      tester,
    ) async {
      await open(tester, '/practices');
      await tester.tap(find.byKey(const Key('practices-phytophthora')));
      await settle(tester);
      final link = find.byKey(
        const Key('practice-label-phytophthora-gummosis'),
      );
      await tester.ensureVisible(link);
      await tester.pumpAndSettle();
      await tester.tap(link);
      await settle(tester);
      expect(find.byKey(const Key('label-target-heading')), findsOneWidget);
      expect(find.byKey(const Key('label-crop-santra')), findsOneWidget);
      expect(
        find.text('Gummosis, foot rot, root rot (Phytophthora)'),
        findsOneWidget,
      );
      await unmountApp(tester);
    });

    testWidgets('a scouting record links to its pest', (tester) async {
      await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: '/plots/p1/scouting',
        seed: seedScouting,
      );
      await settle(tester);
      // s1 is psylla: one link; s2 is fruit drop: none (no label target).
      expect(find.byKey(const Key('scouting-label-s1-psylla')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith(
                'scouting-label-s2',
              ),
        ),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('scouting-label-s1-psylla')));
      await settle(tester);
      expect(
        find.text('No registered label claim for Citrus psylla on citrus.'),
        findsOneWidget,
      );
      await unmountApp(tester);
    });

    testWidgets('look-alike card links to its pests', (tester) async {
      await open(tester, '/lookalikes?plot=p1');
      final link = find.byKey(
        const Key('lookalike-label-mites_thrips_scarring-thrips'),
      );
      await tester.scrollUntilVisible(
        link,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(link);
      await settle(tester);
      expect(
        find.text('No registered label claim for Thrips on citrus.'),
        findsOneWidget,
      );
      await unmountApp(tester);
    });
  });

  test('printed targets map to keys by whole words', () async {
    final data = await LabelTargetsConfig(bundle: FileAssetBundle()).load();
    expect(data.keyFor('Mites'), 'mites');
    expect(data.keyFor('Termites'), isNull);
    expect(data.keyFor('Foot rot'), 'gummosis');
    expect(data.keyFor('Die-back'), 'anthracnose_dieback');
    expect(data.keyFor('Thrips'), 'thrips');
    expect(data.keyFor('Leaf miner'), 'leaf_miner');
    // Every citrus target printed in the CIB&RC Major Uses documents read so far
    // (api/.../label_claims_citrus.csv, as on 30.09.2026) has a display key.
    const printed = {
      'Gummosis': 'gummosis',
      'Brown rot': 'brown_rot',
      'Scab': 'scab',
      'Leaf spot': 'leaf_spot',
      'Canker': 'canker',
      'Post harvest fruit rot complex of fungi Grey mould Botrytis cinerea '
              'Blue mould Penicillium sp Fruit rot Diplodia sp Colletotrichum '
              'Alternaria':
          'post_harvest_rot',
      'Citrus canker': 'canker',
      'Powdery mildew': 'powdery_mildew',
      'Greasy spot': 'greasy_spot',
      'Twig blight, Sooty mould, Anthracnose fruit rot and Anthracnose leaf '
              'spot':
          'anthracnose_dieback',
      'Bacterial Canker and Alternaria Spot': 'canker',
      'Gemmosis (Foot Rot) (Phytophthora palmivora)': 'gummosis',
      'Phytopthora disease viz, Foot rot/gummosis, Root rot, Crown rot, Leaf '
              'fall and Brown rot':
          'gummosis',
      'Phytophthora foot rot': 'gummosis',
      'Mealybug (Planococcus citri)': 'mealybug',
      'Euphorbia spp., Convolvulus arvensis, Coronopus didymus, Amaranthus '
              'viridis, Oxalis corniculata, Tribulus terrestris, Fumaria '
              'parviflora, Sonchus arvensis':
          'weeds',
      'Cyperus iria, Tribulus Terristris, Digera arvensis, Commelina '
              'nudiflora, Cocumis trigonus':
          'weeds',
    };
    for (final e in printed.entries) {
      expect(data.keyFor(e.key), e.value, reason: e.key);
    }
    // Every link points at a defined key; every key has en, mr and hi names.
    final keys = {for (final t in data.targets) t.key};
    for (final list in [
      ...data.practiceSections.values,
      ...data.scoutingItems.values,
    ]) {
      expect(keys.containsAll(list), isTrue, reason: '$list');
    }
    for (final t in data.targets) {
      expect(t.labels.keys.toSet(), {'en', 'mr', 'hi'}, reason: t.key);
    }
  });
}
