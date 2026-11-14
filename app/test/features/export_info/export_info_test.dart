import 'dart:convert';
import 'dart:io';

import 'package:bagmitra/core/config.dart';
import 'package:bagmitra/features/app_update/data/app_update_providers.dart';
import 'package:bagmitra/features/export_info/data/export_info_config.dart';
import 'package:bagmitra/features/export_info/presentation/export_info_screen.dart';
import 'package:bagmitra/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/sources.dart';
import '../directory/directory_test.dart' show mockClipboard;
import '../plots/plots_screen_test.dart' show settle;

/// A test build with the market-link module on (MARKET_LINK=true).
const linkOn = AppConfig(
  productName: 'BagMitra',
  apiBaseUrl: 'http://localhost:8000',
  supabaseUrl: '',
  supabaseAnonKey: '',
  devGallery: true,
  testBuild: '',
  speechEngine: 'on_device',
  marketLink: true,
);

/// UN Comtrade (and sites that republish it) bar commercial reuse: never a source here.
final _comtrade = RegExp('comtrade|trendeconomy', caseSensitive: false);

/// No price is stored (foreign prices wait for the publisher's reuse terms).
final _price = RegExp(
  r'US\$|\bTk\b|NPR|₹|/kg|प्रति किलो',
  caseSensitive: false,
);

/// The export asset read from disk, so the page renders in one pump.
final exportInfoAsset = exportInfoConfigProvider.overrideWithValue(
  ExportInfoConfig(bundle: FileAssetBundle()),
);

Map<String, dynamic> _raw() =>
    jsonDecode(File(ExportInfoConfig.asset).readAsStringSync())
        as Map<String, dynamic>;

Future<void> _pump(
  WidgetTester tester, {
  Locale locale = const Locale('mr'),
  List<Uri>? opened,
  bool opens = true,
}) async {
  await pumpApp(
    tester,
    locale: locale,
    config: linkOn,
    initialLocation: '/market/export',
    overrides: [
      exportInfoAsset,
      urlOpenerProvider.overrideWithValue((u) async {
        opened?.add(u);
        return opens;
      }),
    ],
  );
  await settle(tester);
}

/// Scrolls [finder] into view and taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await settle(tester);
  await tester.tap(finder);
  await settle(tester);
}

void main() {
  group('export information asset', () {
    test('every fact names a known source and the day it was read', () async {
      final raw = _raw();
      final facts = [
        for (final list in (raw['crops'] as Map).values) ...list as List,
        ...raw['rules'] as List,
      ].cast<Map<String, dynamic>>();
      expect(facts, isNotEmpty);
      final sources = (raw['sources'] as Map).cast<String, dynamic>();
      final sections = (raw['sections'] as List).cast<String>();
      for (final f in facts) {
        final id = f['id'];
        expect(sources.keys, contains(f['source']), reason: '$id source');
        expect(
          DateTime.tryParse(f['read'] as String? ?? ''),
          isNotNull,
          reason: '$id read date',
        );
        expect(sections, contains(f['section']), reason: '$id section');
        for (final lang in ['en', 'mr', 'hi']) {
          final text = (f['text'] as Map)[lang] as String?;
          expect(text?.trim(), isNotEmpty, reason: '$id $lang');
          expect(text, isNot(matches(_price)), reason: '$id: no prices');
        }
        // Marathi uses व्यवहार for a deal (glossary), never सौदा.
        expect((f['text'] as Map)['mr'], isNot(contains('सौदा')));
      }
      expect(facts.map((f) => f['id']).toSet(), hasLength(facts.length));
    });

    test('no source or link is UN Comtrade data', () {
      final raw = _raw()..remove('_note');
      expect(jsonEncode(raw), isNot(matches(_comtrade)));
    });

    test('sources and links are https pages; links were checked', () async {
      final info = await ExportInfoConfig(bundle: FileAssetBundle()).load();
      for (final s in info.sources.values) {
        expect(s.title.trim(), isNotEmpty);
        if (s.url case final url?) expect(url, startsWith('https://'));
      }
      expect(info.links.map((l) => l.id), [
        'apeda_exporters',
        'hortinet',
        'dgft_iec',
        'kalimati',
      ]);
      for (final l in info.links) {
        expect(l.url, startsWith('https://'), reason: l.id);
        for (final lang in ['en', 'mr', 'hi']) {
          expect(l.labelIn(lang).trim(), isNotEmpty);
        }
      }
    });

    test('santra and mosambi are covered; rules apply to both', () async {
      final info = await ExportInfoConfig(bundle: FileAssetBundle()).load();
      expect(info.crops.keys, containsAll(['santra', 'mosambi']));
      final rules = info.factsFor('mosambi', 'rules').map((f) => f.id);
      expect(
        rules,
        containsAll([
          'rule_hortinet',
          'rule_packhouse',
          'rule_residue',
          'rule_phyto',
        ]),
      );
      expect(info.factsFor('mosambi', 'destinations'), isEmpty);
      expect(info.factsFor('santra', 'season').map((f) => f.id), [
        'season_ambia',
        'season_mrig',
      ]);
      expect(
        info.factsFor('santra', 'specs').first.textIn('xx'),
        startsWith('150–225 g'),
      );
    });
  });

  group('export information page', () {
    testWidgets('only in builds with the market-link flag', (tester) async {
      await pumpApp(tester, initialLocation: '/market/export');
      await settle(tester);
      expect(find.byType(ExportInfoScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      await unmountApp(tester);

      await pumpApp(tester, initialLocation: '/more');
      await settle(tester);
      expect(
        find.byKey(const Key('more-export-info'), skipOffstage: false),
        findsNothing,
      );
      await unmountApp(tester);
    });

    testWidgets('reached from "more" when the flag is on', (tester) async {
      await pumpApp(
        tester,
        config: linkOn,
        initialLocation: '/more',
        overrides: [exportInfoAsset],
      );
      await settle(tester);
      final entry = find.byKey(const Key('more-export-info'));
      await tapVisible(tester, entry);
      expect(find.byType(ExportInfoScreen), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('sections are folded; each fact shows its source and date', (
      tester,
    ) async {
      await _pump(tester, locale: const Locale('en'));
      expect(
        find.text(
          'For information. The export deal is between you and '
          'the exporter.',
        ),
        findsOneWidget,
      );
      expect(find.text('Where it goes · 4'), findsOneWidget);
      expect(find.byKey(const Key('export-fact-season_mrig')), findsNothing);
      await tester.tap(find.byKey(const Key('export-section-season')));
      await settle(tester);
      final mrig = find.byKey(const Key('export-fact-season_mrig'));
      expect(mrig, findsOneWidget);
      await openAllSources(tester, within: mrig);
      expect(
        find.descendant(of: mrig, matching: find.textContaining('8 Dec 2025')),
        findsOneWidget,
      );
      // Publisher only; no "read <date>" line (owner 2026-11-14).
      expect(
        find.descendant(of: mrig, matching: find.text('FreshPlaza')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: mrig, matching: find.textContaining(' · read ')),
        findsNothing,
      );
      await unmountApp(tester);
    });

    testWidgets('mosambi shows the shared rules only', (tester) async {
      await _pump(tester);
      await tester.tap(find.byKey(const Key('export-crop-mosambi')));
      await settle(tester);
      expect(
        find.byKey(const Key('export-section-destinations')),
        findsNothing,
      );
      expect(find.byKey(const Key('export-section-rules')), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('an official page opens in the browser', (tester) async {
      final opened = <Uri>[];
      await _pump(tester, opened: opened);
      final link = find.byKey(const Key('export-link-dgft_iec'));
      await tapVisible(tester, link);
      expect(
        opened.single.toString(),
        'https://www.dgft.gov.in/CP/?opt=view-any-ice',
      );
      await unmountApp(tester);
    });

    testWidgets('with no browser the link is copied', (tester) async {
      final copied = mockClipboard(tester);
      await _pump(tester, opens: false);
      final link = find.byKey(const Key('export-link-kalimati'));
      await tapVisible(tester, link);
      expect(copied(), 'https://kalimatimarket.gov.np/price');
      expect(find.byType(SnackBar), findsOneWidget);
      await unmountApp(tester);
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('fits a 360 dp phone at x$scale, every section open', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _pump(tester);
        tester.view.physicalSize = const Size(360, 800) * 3;
        await settle(tester);
        for (final s in ['rules', 'specs', 'season', 'destinations']) {
          final section = find.byKey(Key('export-section-$s'));
          await tester.scrollUntilVisible(
            section,
            s == 'rules' ? 200 : -200,
            scrollable: find.byType(Scrollable).first,
          );
          await settle(tester);
          await tester.tap(section);
          await settle(tester);
        }
        await openAllSources(tester);
        await settle(tester);
        expect(tester.takeException(), isNull);
        await unmountApp(tester);
      });
    }
  });
}
