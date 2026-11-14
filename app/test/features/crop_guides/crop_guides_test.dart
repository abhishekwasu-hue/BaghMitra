import 'dart:convert';
import 'dart:io';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/crop_guides/data/crop_guides.dart';
import 'package:bagmitra/features/feed/data/feed_cache.dart';
import 'package:bagmitra/features/plots/data/plot_repository.dart';
import 'package:bagmitra/features/plots/domain/plot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/sources.dart';
import '../feed/feed_data_test.dart'
    show FakeFeedRepository, feedBody, feedJson;
import '../plots/other_crops_test.dart' show seedCotton;
import '../plots/plots_screen_test.dart' show settle;

/// Owner 2026-11-14 (पीक मार्गदर्शक, Q161): the bundled crop guides, their rules (no doses,
/// the expert-advice note, nothing banned or restricted: api tests/test_grower_doses.py) and
/// where the app shows them.

final _raw = File('assets/config/crop_guides.json').readAsStringSync();
final _json = jsonDecode(_raw) as Map<String, dynamic>;
final _data = parseCropGuides(_raw);

Iterable<CropGuideItem> get _items =>
    _data.guides.expand((g) => g.sections).expand((s) => s.items);

Future<void> _seedMustardNews(AppDatabase db) => db.writeMeta(
  FeedCache.keyFor('mr'),
  jsonEncode({
    'saved_at': '2026-10-12T06:00:00.000Z',
    'page': feedBody([
      {
        ...feedJson(
          'n1',
          type: 'news',
          trust: 'news',
          grNumber: null,
          department: null,
          publishedAt: '2026-10-11T06:00:00Z',
        ),
        'title': 'रब्बी हंगामासाठी बियाणे उपलब्ध',
        'summary':
            'कृषी विभागाकडे हरभरा व मोहरीचे बियाणे अनुदानावर उपलब्ध आहे.',
      },
    ]),
  }),
);

Future<void> _seedSantra(AppDatabase db) => PlotRepository(db)
    .save(const Plot(id: 's1', name: 'बाग १', crop: 'santra', areaSqM: 4046));

void main() {
  group('data', () {
    test('the owner\'s eight crops, each a crops.json field crop', () {
      expect(_data.guides.map((g) => g.crop), [
        'cotton',
        'soybean',
        'tur',
        'gram',
        'moong',
        'urad',
        'mustard',
        'linseed',
      ]);
      final catalog = jsonDecode(
        File('assets/config/crops.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final crops = (catalog['crops'] as List).cast<Map<String, dynamic>>();
      final field = {
        for (final c in crops)
          if (c['category'] == 'field') c['slug'],
      };
      for (final g in _data.guides) {
        expect(field, contains(g.crop), reason: g.crop);
        for (final lang in ['mr', 'hi', 'en']) {
          expect(g.labels[lang], isNotEmpty, reason: '${g.crop} $lang');
          expect(g.names[lang], isNotEmpty, reason: '${g.crop} $lang');
        }
        expect(g.aiWritten, isTrue, reason: 'AI wrote the text: tag shown');
      }
    });

    test('sections are known, in stage order, never empty', () {
      for (final g in _data.guides) {
        final keys = [for (final s in g.sections) s.key];
        expect(keys, [
          for (final k in CropGuidesData.sectionKeys)
            if (keys.contains(k)) k,
        ], reason: g.crop);
        for (final s in g.sections) {
          expect(s.items, isNotEmpty, reason: '${g.crop} ${s.key}');
        }
      }
      for (final k in CropGuidesData.sectionKeys) {
        for (final lang in ['mr', 'hi', 'en']) {
          expect(_data.sectionLabels[k]?[lang], isNotEmpty, reason: '$k $lang');
        }
      }
    });

    test('every line is in mr, hi and en, cites known sources and keeps its '
        'source passage', () {
      final ids = <String>{};
      final raw = {
        for (final c in (_json['crops'] as List).cast<Map<String, dynamic>>())
          for (final s in (c['sections'] as List).cast<Map<String, dynamic>>())
            for (final i in (s['items'] as List).cast<Map<String, dynamic>>())
              i['id'] as String: i,
      };
      for (final i in _items) {
        expect(ids.add(i.id), isTrue, reason: 'duplicate ${i.id}');
        for (final lang in ['mr', 'hi', 'en']) {
          expect(i.labels[lang]?.trim(), isNotEmpty, reason: '${i.id} $lang');
        }
        expect(i.sourceKeys, isNotEmpty, reason: i.id);
        for (final k in i.sourceKeys) {
          expect(_data.sources, contains(k), reason: '${i.id} $k');
        }
        expect(
          (raw[i.id]!['quote'] as String).trim(),
          isNotEmpty,
          reason: i.id,
        );
      }
      for (final s in _data.sources.values) {
        expect(s.url, startsWith('https://'));
        expect(s.publisher, isNotEmpty);
        expect(s.checked, isNotNull);
      }
    });

    // Doses, the expert-advice note and banned / crop-restricted names are checked by the
    // shared rules of api kb/dose_rules.py (owner Q160), in api tests/test_grower_doses.py,
    // over every line of this file: one definition of "dose" and one note text.
    test('input lines are marked', () {
      expect(_items.where((i) => i.input), isNotEmpty);
    });
  });

  group('names in a text', () {
    CropGuide guide(String crop) => _data.forCrop(crop)!;

    test('mr / hi / en names and Marathi case endings match', () {
      expect(mentionsCrop('मोहरी पिकावर मावा', guide('mustard')), isTrue);
      expect(mentionsCrop('कापसाचे दर वाढले', guide('cotton')), isTrue);
      expect(mentionsCrop('तुरीचे भाव', guide('tur')), isTrue);
      expect(mentionsCrop('हरभऱ्यावर घाटेअळी', guide('gram')), isTrue);
      expect(mentionsCrop('जवसाची पेरणी', guide('linseed')), isTrue);
      expect(mentionsCrop('उडदाचे पीक', guide('urad')), isTrue);
      expect(mentionsCrop('मूग व उडीद', guide('moong')), isTrue);
      expect(mentionsCrop('सरसों की बुवाई', guide('mustard')), isTrue);
      expect(mentionsCrop('Green gram prices rise', guide('moong')), isTrue);
      expect(mentionsCrop('Soybean MSP', guide('soybean')), isTrue);
    });

    test('a name inside another word does not match', () {
      expect(mentionsCrop('नवी रचना', guide('gram')), isFalse);
      expect(mentionsCrop('A new program for farmers', guide('gram')), isFalse);
      expect(mentionsCrop('Saturday market', guide('tur')), isFalse);
      expect(mentionsCrop('संत्रा बागेत पाणी', guide('cotton')), isFalse);
    });

    test('mentionedIn keeps guide order', () {
      expect(_data.mentionedIn('हरभरा व मोहरीचे बियाणे').map((g) => g.crop), [
        'gram',
        'mustard',
      ]);
    });
  });

  group('screens', () {
    testWidgets('guide screen: stage cards, sources one tap away, AI tag', (
      tester,
    ) async {
      await pumpApp(tester, initialLocation: '/crop-guide/mustard');
      await settle(tester);
      expect(find.text('मोहरी: पीक मार्गदर्शक'), findsOneWidget);
      expect(find.byKey(const Key('crop-guide-sowing')), findsOneWidget);
      expect(find.text('पेरणीची वेळ व पद्धत'), findsOneWidget);
      final guide = _data.forCrop('mustard')!;
      final first = guide.sections.first.items.first;
      expect(find.byKey(Key('crop-guide-item-${first.id}')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('crop-guide-ai-tag')),
        300,
      );
      expect(find.text('AI ने निर्मित'), findsOneWidget);
      await openAllSources(tester);
      await settle(tester);
      expect(
        find.text(_data.sources['PDKV-LM']!.url, skipOffstage: false),
        findsWidgets,
      );
      await unmountApp(tester);
    });

    testWidgets('a cotton block shows the guide tile; it opens the guide', (
      tester,
    ) async {
      await pumpApp(tester, initialLocation: '/plots/c1', seed: seedCotton);
      await settle(tester);
      final tile = find.byKey(const Key('open-crop-guide'));
      await tester.scrollUntilVisible(tile, 200);
      expect(find.text('पीक मार्गदर्शक'), findsOneWidget);
      await tester.tap(tile);
      await settle(tester);
      expect(find.text('कापूस: पीक मार्गदर्शक'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('a santra block has no crop guide tile', (tester) async {
      await pumpApp(tester, initialLocation: '/plots/s1', seed: _seedSantra);
      await settle(tester);
      expect(find.byKey(const Key('open-crop-guide')), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('a feed item that names gram and mustard has both buttons', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initialLocation: '/feed/n1',
        seed: _seedMustardNews,
        overrides: [
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository(null)),
        ],
      );
      await settle(tester);
      final mustard = find.byKey(const Key('crop-guide-link-mustard'));
      expect(find.byKey(const Key('crop-guide-link-gram')), findsOneWidget);
      expect(find.byKey(const Key('crop-guide-link-cotton')), findsNothing);
      await tester.scrollUntilVisible(mustard, 200);
      expect(find.text('मोहरी: लागवड ते काढणी मार्गदर्शक'), findsOneWidget);
      await tester.tap(mustard);
      await settle(tester);
      expect(find.text('मोहरी: पीक मार्गदर्शक'), findsOneWidget);
      await unmountApp(tester);
    });
  });
}
