import 'dart:convert';

import 'package:bagmitra/features/lookalikes/data/lookalike_cards.dart';
import 'package:bagmitra/features/scouting/domain/scouting_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;

// No chemical, dose or treatment wording anywhere on a card (owner rule: "get it checked").
const _enBanned = [
  'spray',
  'fungicide',
  'insecticide',
  'pesticide',
  'copper',
  'bordeaux',
  'sulphur',
  'sulfur',
  'neem',
  'dose',
  'ppm',
  'ml/',
  'g/l',
  'kg/',
  'apply',
  'treat',
  'control',
  'cure',
];
const _mrBanned = ['फवार', 'कीटकनाशक', 'बुरशीनाशक', 'मात्रा', 'उपाय'];
const _hiBanned = ['छिड़क', 'कीटनाशक', 'फफूंदनाशक', 'मात्रा', 'उपचार'];

void _expectClean(Map<String, String> text, String what) {
  for (final lang in ['en', 'mr', 'hi']) {
    expect(text[lang]?.trim(), isNotEmpty, reason: '$what has no $lang');
  }
  final en = text['en']!.toLowerCase();
  for (final w in _enBanned) {
    expect(en.contains(w), isFalse, reason: '$what en contains "$w"');
  }
  for (final w in _mrBanned) {
    expect(text['mr']!.contains(w), isFalse, reason: '$what mr has "$w"');
  }
  for (final w in _hiBanned) {
    expect(text['hi']!.contains(w), isFalse, reason: '$what hi has "$w"');
  }
}

/// Serves one asset from memory, so a test can feed the loader a small config.
class _OneAsset extends CachingAssetBundle {
  _OneAsset(this.json);

  final Map<String, Object?> json;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(utf8.encode(jsonEncode(json)));
}

void main() {
  late LookalikeCardsData data;

  setUpAll(() async {
    data = await LookalikeCardsConfig(bundle: FileAssetBundle()).load();
  });

  test('every card is translated, sourced, linked to scouting and clean', () {
    expect(data.isDraft, isTrue, reason: 'not expert-reviewed yet');
    expect(data.cards.length, greaterThanOrEqualTo(6));
    expect(data.cards.map((c) => c.id).toSet(), hasLength(data.cards.length));
    for (final c in data.cards) {
      _expectClean(c.title, '${c.id} title');
      _expectClean(c.see, '${c.id} see');
      _expectClean(c.confusedWith, '${c.id} confused_with');
      _expectClean(c.confirm, '${c.id} confirm');
      expect(scoutingItems, contains(c.scoutingItem), reason: c.id);
      expect(c.sourceKeys, isNotEmpty, reason: '${c.id} cites nothing');
      for (final k in c.sourceKeys) {
        expect(data.sources[k], isNotNull, reason: '${c.id} cites unknown $k');
      }
    }
    for (final s in data.sources.values) {
      expect(s.url, startsWith('https://'));
      expect(s.title, isNotEmpty);
    }
  });

  test('the cards cover the common Nagpur mandarin / mosambi confusions', () {
    expect(data.cards.map((c) => c.id), [
      'greening_vs_deficiency',
      'gummosis_vs_bark',
      'die_back_causes',
      'fruit_drop_types',
      'psylla_vs_leaf_miner',
      'mites_thrips_scarring',
    ]);
    // Every card ends in "only a lab or an expert can confirm".
    for (final c in data.cards) {
      final en = c.confirm['en']!.toLowerCase();
      expect(en.contains('lab') || en.contains('expert'), isTrue, reason: c.id);
    }
  });

  test('a card citing an unverified or missing source is a draft', () async {
    final loaded = await LookalikeCardsConfig(
      bundle: _OneAsset({
        'status': 'reviewed',
        'sources': {
          'A': {'title': 'A', 'url': 'https://a.example', 'verified': true},
          'B': {'title': 'B', 'url': 'https://b.example', 'verified': false},
        },
        'cards': [
          for (final (id, keys) in [
            ('ok', ['A']),
            ('unverified', ['A', 'B']),
            ('missing', ['Z']),
          ])
            {
              'id': id,
              'scouting_item': 'other',
              'title': {'en': id},
              'see': {'en': 'see'},
              'confused_with': {'en': 'with'},
              'confirm': {'en': 'lab'},
              'sources': keys,
            },
        ],
      }),
    ).load();
    expect(loaded.isDraft, isFalse);
    expect(
      [for (final c in loaded.cards) c.isDraftIn(loaded.sources)],
      [false, true, true],
    );
    // Missing languages fall back to English.
    expect(loaded.cards.first.text(loaded.cards.first.title, 'mr'), 'ok');
  });

  testWidgets('cards show what to look for and link to scouting and labs', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/scouting',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('open-lookalikes')));
    await settle(tester);
    expect(find.text('Look-alike symptoms'), findsOneWidget);
    expect(
      find.text('Yellow leaves: greening (HLB) or a nutrient shortage?'),
      findsOneWidget,
    );
    expect(find.text('What you may see'), findsWidgets);
    expect(find.text('Can be confused with'), findsWidgets);
    expect(find.text('Who can confirm it'), findsWidgets);

    // "Log this" opens the scouting form with the card's item already picked.
    final log = find.byKey(const Key('lookalike-log-psylla_vs_leaf_miner'));
    await tester.scrollUntilVisible(log, 300);
    await tester.ensureVisible(log);
    await tester.pumpAndSettle();
    await tester.tap(log);
    await settle(tester);
    expect(find.text('Add scouting'), findsWidgets);
    final psylla = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Psylla'),
    );
    expect(psylla.selected, isTrue);
    await tester.pageBack();
    await settle(tester);

    final labs = find.byKey(const Key('lookalike-labs-psylla_vs_leaf_miner'));
    await tester.ensureVisible(labs);
    await tester.pumpAndSettle();
    await tester.tap(labs);
    await settle(tester);
    expect(find.text('Labs and experts'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('without a plot the cards show no "log this" button', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/lookalikes',
    );
    await settle(tester);
    expect(
      find.text('Yellow leaves: greening (HLB) or a nutrient shortage?'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('lookalike-log-greening_vs_deficiency')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('lookalike-labs-greening_vs_deficiency')),
      findsOneWidget,
    );
    await unmountApp(tester);
  });

  testWidgets('with plots but none named, the first plot is used', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/lookalikes',
      seed: seedPlot,
    );
    await settle(tester);
    expect(
      find.byKey(const Key('lookalike-log-greening_vs_deficiency')),
      findsOneWidget,
    );
    await unmountApp(tester);
  });
}
