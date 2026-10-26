import 'package:bagmitra/features/practices/data/practice_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;

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
  'imidacloprid',
  'carbendazim',
  'mancozeb',
  'ml/l',
  'g/l',
];
const _mrBanned = ['फवार', 'कीटकनाशक', 'बुरशीनाशक'];
const _hiBanned = ['छिड़क', 'कीटनाशक', 'फफूंदनाशक'];

void _expectClean(Map<String, String> labels, String what) {
  for (final lang in ['en', 'mr', 'hi']) {
    expect(labels[lang]?.trim(), isNotEmpty, reason: '$what has no $lang');
  }
  final en = labels['en']!.toLowerCase();
  for (final w in _enBanned) {
    expect(en.contains(w), isFalse, reason: '$what en contains "$w"');
  }
  for (final w in _mrBanned) {
    expect(labels['mr']!.contains(w), isFalse, reason: '$what mr has "$w"');
  }
  for (final w in _hiBanned) {
    expect(labels['hi']!.contains(w), isFalse, reason: '$what hi has "$w"');
  }
}

void main() {
  late PracticeCardsData data;

  setUpAll(() async {
    data = await PracticeCardsConfig(bundle: FileAssetBundle()).load();
  });

  test('every practice is sourced, translated and free of chemical advice', () {
    expect(data.isDraft, isTrue);
    expect(data.sections, hasLength(13));
    final items = [for (final s in data.sections) ...s.items];
    expect(items, hasLength(70));
    expect(items.map((i) => i.id).toSet(), hasLength(70));
    for (final s in data.sections) {
      _expectClean(s.labels, 'section ${s.key}');
    }
    for (final i in items) {
      _expectClean(i.labels, 'item ${i.id}');
      expect(i.source, isNotEmpty, reason: 'item ${i.id} source');
      expect(i.sourceKeys, isNotEmpty, reason: 'item ${i.id} source keys');
      for (final k in i.sourceKeys) {
        expect(data.sources, contains(k), reason: 'item ${i.id} cites $k');
      }
      expect(i.evidence, isNotEmpty, reason: 'item ${i.id} evidence');
      for (final e in i.evidence) {
        expect(PracticeCardsData.evidenceKinds, contains(e));
      }
    }
    for (final s in data.sources.values) {
      expect(s.title, isNotEmpty);
      expect(Uri.parse(s.url).isScheme('https'), isTrue, reason: s.url);
    }
    expect(data.gaps, isNotEmpty);
    for (final (n, g) in data.gaps.indexed) {
      _expectClean(g, 'gap $n');
    }
  });

  test('labels fall back to English', () {
    const item = PracticeItem(
      id: 1,
      labels: {'en': 'Mulch'},
      source: 'N1',
      sourceKeys: ['N1'],
      evidence: ['official'],
    );
    expect(item.label('hi'), 'Mulch');
  });

  testWidgets('grower opens practices from a block and sees sources', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('open-practices')));
    await tester.tap(find.byKey(const Key('open-practices')));
    await settle(tester);

    expect(find.text('Orchard practices'), findsOneWidget);
    // Owner 2026-10-26 (Q30): no draft banner; sources show under each practice instead.
    expect(find.textContaining('Draft'), findsNothing);
    expect(find.textContaining('not yet checked'), findsNothing);

    await tester.tap(find.text('Nursery hygiene'));
    await settle(tester);
    expect(
      find.textContaining('Soil solarisation of nursery beds'),
      findsOneWidget,
    );
    expect(find.textContaining('P1 Plant Pathology recs'), findsWidgets);
    expect(find.textContaining('PDKV: AICRP'), findsWidgets);
    expect(find.text('University'), findsWidgets);

    final sourcesLine = find.byKey(const Key('practices-sources'));
    await tester.scrollUntilVisible(sourcesLine, 300);
    expect(
      find.text(
        'Sources: NHB and Dr. PDKV, Akola. Details under each practice.',
      ),
      findsOneWidget,
    );
    await unmountApp(tester);
  });

  testWidgets('practices render in Marathi', (tester) async {
    await pumpApp(tester, initialLocation: '/practices');
    await settle(tester);
    await tester.tap(find.text('रोपवाटिकेची स्वच्छता'));
    await settle(tester);
    expect(
      find.text(
        'रोपवाटिकेचे वाफे पारदर्शक प्लास्टिकने ४५ दिवस झाकून उन्हात तापवा.',
      ),
      findsOneWidget,
    );
    expect(find.text('विद्यापीठ'), findsWidgets);
    await unmountApp(tester);
  });
}
