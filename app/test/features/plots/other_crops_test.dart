// Owner 2026-11-14 (OPEN_QUESTIONS Q158): santra and mosambi stay the special crops; every
// other crop ("इतर पिके") uses the same records, without the citrus features.
import 'dart:convert';
import 'dart:io';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/plots/data/crop_catalog.dart';
import 'package:bagmitra/features/plots/data/plot_repository.dart';
import 'package:bagmitra/features/plots/domain/plot.dart';
import 'package:bagmitra/features/scouting/domain/scouting_record.dart';
import 'package:bagmitra/sync/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../home/home_seed.dart' show realConfig;
import 'plots_screen_test.dart' show settle;

/// A located cotton block: records only, no bahar.
Future<void> seedCotton(AppDatabase db) => PlotRepository(db).save(
  const Plot(
    id: 'c1',
    name: 'शेत १',
    crop: 'cotton',
    areaSqM: 5 * Plot.sqMPerAcre,
    centroidLat: 21.2468,
    centroidLon: 77.7512,
  ),
);

/// A vegetable block whose crop name the grower typed.
Future<void> seedBrinjal(AppDatabase db) => PlotRepository(db).save(
  const Plot(
    id: 'v1',
    name: 'Plot 2',
    crop: 'vegetables',
    variety: 'Brinjal',
    areaSqM: 1 * Plot.sqMPerAcre,
  ),
);

Future<CropCatalogData> _catalog() =>
    CropCatalog(bundle: FileAssetBundle()).loadAll();

/// Every crop name and crop group the PPQS restriction list (spray check) names.
Set<String> _restrictionNames() {
  final json = jsonDecode(
    File('../api/src/bagmitra_api/kb/seed_data/restrictions.json')
        .readAsStringSync(),
  ) as Map<String, Object?>;
  return {
    for (final r
        in (json['restrictions']! as List<Object?>)
            .cast<Map<String, Object?>>()) ...[
      for (final c in (r['crops']! as List<Object?>).cast<String>())
        c.toLowerCase(),
      ...(r['crop_groups']! as List<Object?>).cast<String>(),
    ],
  };
}

/// Scrolls the block form until [finder] is built and on screen.
Future<void> _show(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await settle(tester);
}

void main() {
  group('catalog', () {
    test(
      'santra and mosambi are the primary crops, the citrus-feature ones',
      () async {
        final data = await _catalog();
        final primary = [
          for (final c in data.crops)
            if (c.primary) c.slug,
        ];
        expect(primary, ['santra', 'mosambi']);
        expect(primary.toSet(), citrusFeatureCrops);
      },
    );

    test(
      'the owner\'s list is there, grouped, labelled in mr / hi / en',
      () async {
        final data = await _catalog();
        final bySlug = {for (final c in data.crops) c.slug: c};
        expect(data.categories.map((g) => g.key), [
          'fruit',
          'field',
          'vegetable',
          'flower',
          'other',
        ]);
        expect(data.categories.map((g) => g.label('mr')), [
          'फळपिके',
          'शेतपिके',
          'भाजीपाला',
          'फुलझाडे',
          'इतर',
        ]);
        String mr(String slug) => bySlug[slug]!.label('mr');
        expect(
          [
            for (final s in [
              'pomegranate',
              'banana',
              'grapes',
              'mango',
              'guava',
              'lemon',
              'papaya',
              'custard_apple',
              'sapota',
              'ber',
              'aonla',
              'other_fruit',
            ])
              (mr(s), bySlug[s]!.category),
          ],
          [
            for (final n in [
              'डाळिंब',
              'केळी',
              'द्राक्ष',
              'आंबा',
              'पेरू',
              'लिंबू',
              'पपई',
              'सीताफळ',
              'चिकू',
              'बोर',
              'आवळा',
              'इतर फळपीक',
            ])
              (n, 'fruit'),
          ],
        ); // fmt: skip
        expect(
          [
            for (final s in [
              'cotton',
              'soybean',
              'tur',
              'gram',
              'moong',
              'urad',
            ])
              (mr(s), bySlug[s]!.category),
          ],
          [
            for (final n in ['कापूस', 'सोयाबीन', 'तूर', 'हरभरा', 'मूग', 'उडीद'])
              (n, 'field'),
          ],
        );
        expect(bySlug['vegetables']!.category, 'vegetable');
        expect(bySlug['flowers']!.category, 'flower');
        expect(bySlug['other']!.category, 'other');
        final slug = RegExp(r'^[a-z][a-z0-9_]{1,31}$'); // api sync Slug
        final categories = data.categories.map((g) => g.key).toSet();
        for (final c in data.crops) {
          expect(slug.hasMatch(c.slug), isTrue, reason: c.slug);
          expect(categories, contains(c.category), reason: c.slug);
          for (final lang in ['mr', 'hi', 'en']) {
            expect(c.labels[lang], isNotEmpty, reason: '${c.slug} $lang');
          }
        }
        expect(
          [
            for (final c in data.crops)
              if (c.nameTyped) c.slug,
          ],
          ['other_fruit', 'vegetables', 'flowers', 'other'],
        );
      },
    );

    test(
      'spray-check names only where the restriction list names the crop',
      () async {
        final names = _restrictionNames();
        final data = await _catalog();
        for (final c in data.crops.where((c) => !c.primary)) {
          for (final n in [...c.labelAliases, ...c.groups]) {
            expect(names, contains(n), reason: '${c.slug}: $n');
          }
        }
        final bySlug = {for (final c in data.crops) c.slug: c};
        expect(bySlug['soybean']!.labelAliases, ['soybean']);
        expect(bySlug['grapes']!.labelAliases, ['grape']);
        expect(bySlug['vegetables']!.groups, ['vegetable']);
        expect(bySlug['cotton']!.labelAliases, isEmpty);
        expect(bySlug['lemon']!.labelAliases, isEmpty);
      },
    );

    test('a typed crop name is shown instead of the crop label', () {
      const crops = [
        CropOption('vegetables', {'en': 'Vegetable crop'}, nameTyped: true),
        CropOption('cotton', {'en': 'Cotton'}),
      ];
      Plot plot(String crop, String? variety) =>
          Plot(id: 'x', name: 'x', crop: crop, areaSqM: 1, variety: variety);
      expect(
        plotCropName(plot('vegetables', 'Brinjal'), crops, 'en'),
        'Brinjal',
      );
      expect(
        plotCropName(plot('vegetables', ' '), crops, 'en'),
        'Vegetable crop',
      );
      expect(plotCropName(plot('cotton', 'Bt'), crops, 'en'), 'Cotton');
      expect(plotCropName(plot('unknown', null), crops, 'en'), 'unknown');
    });
  });

  group('crop picker', () {
    testWidgets('two big choices, then "other crops" opens the sections', (
      tester,
    ) async {
      await pumpApp(tester, initialLocation: '/plots/new');
      await settle(tester);
      expect(find.byKey(const Key('crop-santra')), findsOneWidget);
      expect(find.byKey(const Key('crop-mosambi')), findsOneWidget);
      expect(find.text('इतर पिके'), findsOneWidget);
      expect(find.byKey(const Key('crop-cotton')), findsNothing);

      await tester.tap(find.byKey(const Key('other-crops')));
      await settle(tester);
      for (final h in ['फळपिके', 'शेतपिके', 'भाजीपाला', 'फुलझाडे', 'इतर']) {
        expect(find.text(h), findsOneWidget, reason: h);
      }
      expect(find.byKey(const Key('crop-cotton')), findsOneWidget);
      expect(find.byKey(const Key('crop-pomegranate')), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('cotton saves as its slug with no crop-name field', (
      tester,
    ) async {
      final db = await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: '/plots/new',
      );
      await settle(tester);
      await tester.enterText(find.byKey(const Key('plot-name')), 'Field 1');
      await tester.tap(find.byKey(const Key('other-crops')));
      await settle(tester);
      await _show(tester, find.byKey(const Key('crop-cotton')));
      await tester.tap(find.byKey(const Key('crop-cotton')));
      await settle(tester);
      expect(find.text('Other crops: Cotton'), findsOneWidget);
      await _show(tester, find.byKey(const Key('plot-acres')));
      await tester.enterText(find.byKey(const Key('plot-acres')), '5');
      await _show(tester, find.byKey(const Key('plot-year')));
      expect(find.byKey(const Key('plot-crop-name')), findsNothing);
      expect(find.byKey(const Key('plot-variety')), findsOneWidget);
      await tester.tap(find.text('Save'));
      await settle(tester);
      final queued = await tester.runAsync(
        () => db.select(db.outboxEntries).get(),
      );
      expect(queued!.single.payload, contains('"crop":"cotton"'));
      expect(queued.single.payload, contains('"variety":null'));
      await unmountApp(tester);
    });

    testWidgets('vegetables ask for the crop name, saved as the variety', (
      tester,
    ) async {
      final db = await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: '/plots/new',
      );
      await settle(tester);
      await tester.enterText(find.byKey(const Key('plot-name')), 'Plot 2');
      await tester.tap(find.byKey(const Key('other-crops')));
      await settle(tester);
      await _show(tester, find.byKey(const Key('crop-vegetables')));
      await tester.tap(find.byKey(const Key('crop-vegetables')));
      await settle(tester);
      await _show(tester, find.byKey(const Key('plot-crop-name')));
      expect(find.byKey(const Key('plot-crop-name')), findsOneWidget);
      await _show(tester, find.byKey(const Key('plot-acres')));
      await tester.enterText(find.byKey(const Key('plot-acres')), '1');
      await _show(tester, find.byKey(const Key('plot-year')));
      expect(find.byKey(const Key('plot-variety')), findsNothing);
      await _show(tester, find.byKey(const Key('plot-crop-name')));
      await tester.tap(find.text('Save'));
      await settle(tester);
      expect(find.text('Type the crop name'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('plot-crop-name')),
        'Brinjal',
      );
      await tester.tap(find.text('Save'));
      await settle(tester);
      final queued = await tester.runAsync(
        () => db.select(db.outboxEntries).get(),
      );
      expect(queued!.single.payload, contains('"crop":"vegetables"'));
      expect(queued.single.payload, contains('"variety":"Brinjal"'));
      // The list shows the typed name, not "Vegetable crop".
      expect(find.text('Brinjal'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('editing a vegetable block opens the list with its name', (
      tester,
    ) async {
      await pumpApp(
        tester,
        locale: const Locale('en'),
        initialLocation: '/plots/v1/edit',
        seed: seedBrinjal,
      );
      await settle(tester);
      expect(find.text('Other crops: Vegetable crop'), findsOneWidget);
      expect(find.text('Vegetables'), findsOneWidget);
      await _show(tester, find.byKey(const Key('plot-crop-name')));
      final field = tester.widget<TextFormField>(
        find.byKey(const Key('plot-crop-name')),
      );
      expect(field.controller!.text, 'Brinjal');
      await unmountApp(tester);
    });
  });

  group('a cotton block', () {
    testWidgets(
      'has the records, and no bahar, irrigation guide or practices',
      (tester) async {
        await pumpApp(tester, initialLocation: '/plots/c1', seed: seedCotton);
        await settle(tester);
        expect(find.text('कापूस'), findsOneWidget);
        for (final k in [
          'open-records',
          'open-irrigation-guide',
          'open-practices',
        ]) {
          expect(find.byKey(Key(k)), findsNothing, reason: k);
        }
        for (final k in [
          'open-sprays',
          'open-field-log',
          'open-accounts',
          'open-labour',
          'open-harvest',
          'open-scouting',
          'open-insurance',
          'open-lab-tests',
        ]) {
          await _show(tester, find.byKey(Key(k)));
          expect(find.byKey(Key(k)), findsOneWidget, reason: k);
        }
        await unmountApp(tester);
      },
    );

    testWidgets('home shows the block card, not the bahar card', (
      tester,
    ) async {
      await pumpApp(
        tester,
        config: realConfig,
        // The sync engine is not under test here; a settled status keeps it out.
        syncStatus: const SyncStatus(connectivity: Connectivity.online),
        seed: seedCotton,
      );
      await settle(tester);
      expect(find.byKey(const Key('home-start-bahar')), findsNothing);
      expect(find.byKey(const Key('home-stage')), findsNothing);
      expect(find.byKey(const Key('home-plot-card')), findsOneWidget);
      expect(find.text('शेत १'), findsWidgets);
      expect(find.textContaining('कापूस · ५ एकर'), findsOneWidget);
      await tester.tap(find.text('नोंदी उघडा'));
      await settle(tester);
      expect(find.byKey(const Key('open-sprays')), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets(
      'scouting has no citrus pest list, photo check or look-alikes',
      (tester) async {
        await pumpApp(
          tester,
          initialLocation: '/plots/c1/scouting',
          seed: seedCotton,
        );
        await settle(tester);
        expect(find.byKey(const Key('photo-check-open')), findsNothing);
        expect(find.byKey(const Key('open-lookalikes')), findsNothing);
        await tester.tap(find.text('पाहणी नोंदवा'));
        await settle(tester);
        expect(
          find.byType(ChoiceChip),
          findsNWidgets(1 + scoutingSeverities.length),
        );
        expect(find.text('सायला'), findsNothing);
        await unmountApp(tester);
      },
    );

    testWidgets('the spray log has no citrus label information button', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialLocation: '/plots/c1/sprays',
        seed: seedCotton,
      );
      await settle(tester);
      expect(find.byKey(const Key('open-labels')), findsNothing);
      await unmountApp(tester);
    });
  });
}
