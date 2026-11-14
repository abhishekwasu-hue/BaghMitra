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

/// Owner 2026-11-14 (पीक मार्गदर्शक, Q160): the bundled crop guides, their rules (no doses,
/// the expert-advice note, nothing banned or restricted) and where the app shows them.

final _raw = File('assets/config/crop_guides.json').readAsStringSync();
final _json = jsonDecode(_raw) as Map<String, dynamic>;
final _data = parseCropGuides(_raw);

const _note = {
  'en': '(follow expert advice)',
  'mr': '(तज्ज्ञांच्या सल्ल्याने करावे)',
  'hi': '(विशेषज्ञ की सलाह से करें)',
};

/// Words that make a line an input recommendation (fertiliser, pesticide, organic input).
const _inputWords = {
  'en': [
    'fertiliser',
    'fertilizer',
    'manure',
    'fym',
    'compost',
    'urea',
    'dap',
    'npk',
    'rhizobium',
    'psb',
    'azotobacter',
    'trichoderma',
    'neem',
    'azadirachtin',
    'sulphur',
    'zinc',
    'borax',
    'gypsum',
    'potassium nitrate',
    'herbicide',
    'fungicide',
    'insecticide',
    'pesticide',
    'spray',
    'seed treatment',
    'metarhizium',
    'beauveria',
    'verticillium',
    'bacillus',
    'trichogramma',
    'thiram',
    'carbendazim',
    'copper',
    'salicylic',
    'dashparni',
    'extract',
  ],
  'mr': [
    'खत',
    'कंपोस्ट',
    'युरिया',
    'रायझोबियम',
    'पीएसबी',
    'ट्रायकोडर्मा',
    'निंबोळी',
    'गंधक',
    'जस्त',
    'बोरॅक्स',
    'जिप्सम',
    'तणनाशक',
    'कीटकनाशक',
    'बुरशीनाशक',
    'फवारणी',
    'बीजप्रक्रिया',
    'अर्क',
  ],
  'hi': [
    'खाद',
    'कम्पोस्ट',
    'यूरिया',
    'राइजोबियम',
    'पीएसबी',
    'ट्राइकोडर्मा',
    'नीम',
    'गंधक',
    'जिंक',
    'बोरेक्स',
    'जिप्सम',
    'खरपतवारनाशी',
    'कीटनाशी',
    'फफूंदनाशी',
    'छिड़काव',
    'बीजोपचार',
    'अर्क',
  ],
}; // fmt: skip

const _digits =
    r'[0-9०-९]+(?:[.,][0-9०-९]+)?(?:\s*[-–]\s*[0-9०-९]+(?:[.,][0-9०-९]+)?)?';

/// A number with a dose unit, or a per-area rate; a percent that names a crop stage (50%
/// flowering) is a stage, not a dose.
final _dose = RegExp(
  '$_digits\\s*(?:kgs?\\b|kg/|g\\b|gm\\b|grams?\\b|ml\\b|l\\b|lit\\b|litres?\\b|liters?\\b|'
  'ppm\\b|t/ha|tonnes?\\b|q/ha|quintals?\\b|किलो|कि\\.ग्रॅ|ग्रॅम|ग्राम|मिली|मि\\.ली\\.|लिटर|लीटर|'
  'टन|पीपीएम|%(?!\\s*(?:flower|फुलो|फूल))|टक्के(?!\\s*फुलो)|प्रतिशत(?!\\s*फूल)|per ?cent\\b(?!\\s*flower))'
  '|per acre|per hectare|/ha\\b|हेक्टरी|एकरी|प्रति हेक्टर|प्रति एकर|प्रति हेक्टेयर|प्रति एकड़',
  caseSensitive: false,
);

bool _namesInput(String lang, String text) {
  final t = text.toLowerCase();
  return _inputWords[lang]!.any(
    (w) => lang == 'en'
        ? RegExp('(?<![a-z])${RegExp.escape(w)}').hasMatch(t)
        : t.contains(w),
  );
}

/// Every ingredient of the PPQS banned / refused / withdrawn / restricted list (the list the
/// spray check uses), and its synonyms.
List<String> _restricted() {
  final json = jsonDecode(
    File('../api/src/bagmitra_api/kb/seed_data/restrictions.json')
        .readAsStringSync(),
  ) as Map<String, Object?>;
  return [
    for (final r
        in (json['restrictions']! as List<Object?>)
            .cast<Map<String, Object?>>()) ...[
      (r['active_ingredient']! as String).toLowerCase(),
      for (final s in (r['synonyms'] as List<Object?>? ?? const []))
        (s! as String).toLowerCase(),
    ],
  ];
}

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
      final crops =
          (jsonDecode(
                    File('assets/config/crops.json').readAsStringSync(),
                  )['crops']
                  as List)
              .cast<Map<String, dynamic>>();
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

    test(
      'doses guard: an input line names no dose and ends with the expert note; '
      'a line that names an input is an input line',
      () {
        final misses = <String>[];
        for (final i in _items) {
          for (final lang in ['en', 'mr', 'hi']) {
            final text = i.label(lang);
            if (_namesInput(lang, text) && !i.input) {
              misses.add('${i.id} $lang names an input but is not `input`');
            }
            if (!i.input) continue;
            if (!text.trimRight().endsWith(_note[lang]!)) {
              misses.add('${i.id} $lang does not end with the expert note');
            }
            for (final m in _dose.allMatches(text)) {
              misses.add('${i.id} $lang dose "${m.group(0)}"');
            }
          }
        }
        expect(misses, isEmpty);
      },
    );

    test('the doses guard catches doses and rates', () {
      for (final bad in [
        'urea 25 kg per hectare',
        'imidacloprid 0.5 ml/l',
        'neem seed extract 5%',
        'एकरी २ किलो युरिया',
        'हेक्टरी खत द्या',
        '१० मिली प्रति १० लिटर पाणी',
        'नीम तेल 5 मिली प्रति लीटर',
        'azadirachtin 300 ppm',
        'spray 2 g in 10 liter',
      ]) {
        expect(_dose.hasMatch(bad), isTrue, reason: bad);
      }
      for (final ok in [
        'at 50% flowering, 15 days later',
        '५०% फुलोऱ्यावर, १५ दिवसांनी',
        'two sprays a fortnight apart',
        'from 55 days after germination',
      ]) {
        expect(_dose.hasMatch(ok), isFalse, reason: ok);
      }
      expect(_namesInput('mr', 'शेणखत द्या'), isTrue);
      expect(_namesInput('en', 'Give FYM'), isTrue);
      expect(_namesInput('en', 'Sow at 45 x 10 cm'), isFalse);
    });

    test('no banned or restricted pesticide (PPQS list of the spray check) is named', () {
      final names = _restricted();
      expect(names, contains('dinocap'), reason: 'the list is read');
      final misses = <String>[];
      for (final i in _items) {
        final text = '${i.label('en')} ${i.source}'.toLowerCase();
        for (final n in names) {
          if (RegExp('(?<![a-z])${RegExp.escape(n)}(?![a-z])').hasMatch(text)) {
            misses.add('${i.id}: $n');
          }
        }
      }
      expect(misses, isEmpty);
      // The source that listed banned fungicides is kept, the names are not.
      final omitted = [
        for (final c in (_json['crops'] as List).cast<Map<String, dynamic>>())
          for (final s in (c['sections'] as List).cast<Map<String, dynamic>>())
            for (final i in (s['items'] as List).cast<Map<String, dynamic>>())
              ...((i['omitted'] as List?) ?? const []),
      ];
      for (final o in omitted) {
        expect(names, contains(o), reason: '$o is on the list');
      }
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
