import 'dart:io';

import 'package:bagmitra/features/practices/data/practice_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/sources.dart';
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
  // No pointer to where a source gives a chemical remedy, and no research notes (audit C2, C7).
  'product exists',
  'excluded',
  'growth-regulator',
  'chemical control',
  'in source',
  'candidate for',
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

/// Synthetic pesticides, fertilisers and doses that may never appear in an organic / bio text.
const _synthetic = [
  'imidacloprid',
  'thiamethoxam',
  'dimethoate',
  'malathion',
  'monocrotophos',
  'chlorpyri',
  'acephate',
  'abamectin',
  'novaluron',
  'spinosad',
  'quinalphos',
  'dicofol',
  'carbendazim',
  'mancozeb',
  'copper',
  'bordeaux',
  'sulphur',
  'sulfur',
  'streptocycline',
  'tetracycline',
  'urea',
  'phosphate',
  'potash',
  'petroleum',
  'kerosene',
];

void _expectBio(Map<String, String> labels, String what) {
  for (final lang in ['en', 'mr', 'hi']) {
    expect(labels[lang]?.trim(), isNotEmpty, reason: '$what has no $lang');
  }
  final en = labels['en']!.toLowerCase();
  for (final w in _synthetic) {
    expect(en.contains(w), isFalse, reason: '$what en names "$w"');
  }
}

void main() {
  late PracticeCardsData data;

  setUpAll(() async {
    data = await PracticeCardsConfig(bundle: FileAssetBundle()).load();
  });

  test('every practice is sourced, translated and free of chemical advice', () {
    expect(data.isDraft, isTrue);
    expect(data.sections, hasLength(25));
    final items = [for (final s in data.sections) ...s.items];
    expect(items, hasLength(107));
    expect(items.map((i) => i.id).toSet(), hasLength(107));
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

  // Owner 2026-11-10: the "Registered product: the dose comes only from its label" line and
  // the label button already say it once per section; no point repeats it.
  test('no card point repeats the label-screen pointer', () {
    final raw = File('assets/config/practice_cards.json').readAsStringSync();
    for (final clause in [
      'check the label screen',
      'लेबल स्क्रीन पाहा',
      'लेबल स्क्रीन देखें',
    ]) {
      expect(raw.contains(clause), isFalse, reason: clause);
    }
  });

  test(
    'problem profiles are sourced, dated, clean and link to the label screen',
    () {
      final profiled = [
        for (final s in data.sections)
          if (s.profile case final p?) (s, p),
      ];
      // The WP2 gaps closed with a profile (owner decision Q57).
      expect(profiled.map((sp) => sp.$1.key).toSet(), {
        'phytophthora',
        'canker',
        'psylla',
        'greening',
        'powdery_mildew',
        'anthracnose',
        'black_fly',
        'mites',
        'aphids',
        'thrips',
        'mealybug',
        'leaf_miner',
        'fruit_fly',
        'heat_drop',
        'nutrition',
        'mosambi',
      });
      for (final (s, p) in profiled) {
        expect(PracticeProfile.kinds, contains(p.kind), reason: s.key);
        expect(p.checked, isNotNull, reason: '${s.key} has no date read');
        for (final part in [p.symptoms, p.when, p.scouting, p.actionLevel]) {
          if (part == null) continue;
          _expectClean(part.labels, '${s.key} profile');
          expect(part.source, isNotEmpty);
          expect(part.sourceKeys, isNotEmpty, reason: s.key);
        }
        if (p.kind == 'pest' || p.kind == 'disease') {
          expect(p.labelTarget, isNotNull, reason: '${s.key} label link');
        }
        for (final k in p.sourceKeys) {
          expect(data.sources, contains(k), reason: '${s.key} cites $k');
          expect(data.sources[k]!.publisher, isNotNull, reason: k);
          expect(data.sources[k]!.checked, isNotNull, reason: k);
        }
        for (final b in p.bio) {
          _expectBio(b.labels, '${s.key} ${b.id}');
          expect(PracticeBio.kinds, contains(b.kind), reason: b.id);
          expect(b.sourceKeys, isNotEmpty, reason: b.id);
          for (final e in b.evidence) {
            expect(PracticeCardsData.evidenceKinds, contains(e));
          }
          if (b.kind == 'registered') {
            // A registered product is named without a dose or strength: the dose is
            // the label's.
            expect(
              RegExp(r'\d+(?:\.\d+)?\s*(?:%|ppm|ml|g\b|kg|l\b|litre)')
                  .hasMatch(b.labels['en']!),
              isFalse,
              reason: '${b.id} carries a dose',
            );
            expect(b.preparation, isNull, reason: b.id);
          }
          if (b.preparation case final prep?) {
            expect(data.preparations, contains(prep), reason: b.id);
          }
        }
      }
      // Only one published action level was found (mealybug, ICAR-NRC Citrus review).
      expect(
        [
          for (final (s, p) in profiled)
            if (p.actionLevel != null) s.key,
        ],
        ['mealybug'],
      );
      expect(data.preparations.keys, {'nske_5', 'neem_oil_1'});
      for (final prep in data.preparations.values) {
        _expectBio(prep.labels, 'preparation');
        expect(prep.sourceKeys, isNotEmpty);
      }
      final ids = [for (final (_, p) in profiled) ...p.bio.map((b) => b.id)];
      expect(ids.toSet(), hasLength(ids.length));
    },
  );

  test(
    'every figure is a known drawing and its measures are in the practice text',
    () {
      final digits = RegExp(r'[0-9०-९]+');
      int? value(String d) => int.tryParse(
        String.fromCharCodes(
          d.runes.map((r) => r >= 0x966 && r <= 0x96F ? r - 0x966 + 48 : r),
        ),
      );
      Set<int> numbers(String text) => {
        for (final m in digits.allMatches(text)) ?value(m[0]!),
      };
      final phytophthora = data.sections.firstWhere(
        (s) => s.key == 'phytophthora',
      );
      expect(
        phytophthora.profile!.figure?.kind,
        PracticeFigureKind.gummosisTrunk,
      );
      // Batch 2: every card with a symptom text shows a symptom drawing.
      for (final s in data.sections) {
        if (s.profile?.symptoms != null) {
          expect(
            s.profile!.figure,
            isNotNull,
            reason: '${s.key} symptom drawing',
          );
        }
      }
      final drawn = [
        for (final s in data.sections)
          for (final i in s.items)
            if (i.figure case final f?) (i, f),
      ];
      expect(
        [for (final (i, f) in drawn) '${i.id}:${f.kind.name}'],
        containsAll([
          '19:drainageTrench',
          '20:doubleRing',
          '21:pruneCut',
          '22:rootSun',
          '108:barkStrip',
          '24:twiceYearly',
          // Batch 1 (owner 2026-11-09: every card like gummosis).
          '26:stickyTrap',
          '90:budHeight',
          '91:doubleRing',
          '82:trunkBand',
          '39:lureTrap',
          '29:shadySide',
          '88:openCanopy',
          '105:manureRing',
        ]),
      );
      for (final (i, f) in drawn) {
        for (final lang in ['en', 'mr', 'hi']) {
          expect(
            numbers(i.label(lang)),
            containsAll(f.values),
            reason: 'item ${i.id} ($lang) must state ${f.values}',
          );
        }
      }
    },
  );

  testWidgets('the gummosis card shows its drawings', (tester) async {
    await pumpApp(tester, initialLocation: '/practices', seed: seedPlot);
    await settle(tester);
    await tester.tap(find.text('फायटोफ्थोरा: डिंक्या, खोडकूज, मूळकूज'));
    await settle(tester);
    expect(
      find.byKey(const Key('practice-figure-phytophthora')),
      findsOneWidget,
    );
    for (final id in [19, 20, 21, 22, 108, 24]) {
      await tester.scrollUntilVisible(
        find.byKey(Key('practice-figure-$id')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(Key('practice-figure-$id')), findsOneWidget);
    }
    expect(
      find.bySemanticsLabel(RegExp('६० सें.मी., ३० सें.मी. खोल')),
      findsOneWidget,
      reason: 'the trench drawing reads its measures out',
    );
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('batch 1 drawings show on their cards', (tester) async {
    await pumpApp(tester, initialLocation: '/practices', seed: seedPlot);
    await settle(tester);
    for (final (section, id) in [
      ('पिठ्या ढेकूण', 82),
      ('फळमाशी आणि रस शोषणारा पतंग', 39),
    ]) {
      await tester.scrollUntilVisible(
        find.text(section),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(section));
      await settle(tester);
      await tester.scrollUntilVisible(
        find.byKey(Key('practice-figure-$id')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(Key('practice-figure-$id')), findsOneWidget);
    }
    expect(
      find.bySemanticsLabel(
        RegExp('ल्युअर सापळा, ल्युअर दर १५–२० दिवसांनी बदला'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
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
    // Owner 2026-10-26 (Q30): no draft banner; sources sit under each practice instead.
    expect(find.textContaining('Draft'), findsNothing);
    expect(find.textContaining('not yet checked'), findsNothing);

    await tester.tap(find.text('Nursery hygiene'));
    await settle(tester);
    expect(
      find.textContaining('Soil solarisation of nursery beds'),
      findsOneWidget,
    );
    // Sources fold behind one "Sources (n)" header per practice (owner request).
    expect(find.textContaining('P1 Plant Pathology recs'), findsNothing);
    expect(find.byKey(const Key('sources-toggle')), findsWidgets);
    await openAllSources(tester);
    expect(find.textContaining('P1 Plant Pathology recs'), findsWidgets);
    expect(find.textContaining('PDKV: AICRP'), findsWidgets);
    expect(find.text('University'), findsWidgets);

    final sourcesLine = find.byKey(const Key('practices-sources'));
    await tester.scrollUntilVisible(sourcesLine, 300);
    expect(
      find.text(
        'Sources: NHB, NIPHM, ICAR, Dr. PDKV, MPKV, TNAU and others. '
        'Details under each practice.',
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
        'रोग आणि वार्षिक तणांविरुद्ध रोपवाटिकेचे वाफे पारदर्शक पॉलिथिनने ४५ दिवस '
        '(सप्टेंबर–नोव्हेंबर) झाकून उन्हात तापवा.',
      ),
      findsOneWidget,
    );
    expect(find.text('विद्यापीठ'), findsNothing);
    await openAllSources(tester);
    expect(find.text('विद्यापीठ'), findsWidgets);
    await unmountApp(tester);
  });

  testWidgets(
    'a problem section shows its profile, bio list and links in Marathi',
    (tester) async {
      await pumpApp(tester, initialLocation: '/practices', seed: seedPlot);
      await settle(tester);
      final thrips = find.byKey(const Key('practices-thrips'));
      await tester.scrollUntilVisible(thrips, 300);
      await tester.tap(thrips);
      await settle(tester);
      expect(find.byKey(const Key('practices-general-thrips')), findsOneWidget);
      // Owner 2026-11-10: no "general information · confirm with your KVK" line.
      expect(find.textContaining('सर्वसाधारण माहिती'), findsNothing);
      expect(find.textContaining('KVK कडून खात्री'), findsNothing);
      expect(find.textContaining('स्रोत ('), findsWidgets);
      expect(find.text('काय दिसते'), findsOneWidget);
      expect(find.text('पाहणी कशी करावी'), findsOneWidget);
      expect(
        find.byKey(const Key('practices-no-action-thrips')),
        findsOneWidget,
      );
      final link = find.byKey(const Key('practices-labels-thrips'));
      await tester.scrollUntilVisible(link, 200);
      expect(find.text('लेबलप्रमाणे मंजूर औषधे पहा'), findsOneWidget);
      expect(find.byKey(const Key('practices-bio-thrips')), findsOneWidget);
      expect(find.textContaining('नोंदणीकृत उत्पादन'), findsOneWidget);
      await unmountApp(tester);
    },
  );

  testWidgets('a home-made option shows its preparation as published', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/practices',
      seed: seedPlot,
    );
    await settle(tester);
    final miner = find.byKey(const Key('practices-leaf_miner'));
    await tester.scrollUntilVisible(miner, 300);
    await tester.tap(miner);
    await settle(tester);
    final prep = find.byKey(const Key('practice-prep-b3'));
    await tester.scrollUntilVisible(prep, 200);
    await tester.ensureVisible(prep);
    await tester.pumpAndSettle();
    await tester.tap(prep);
    await settle(tester);
    expect(
      find.textContaining('5 kg well-dried neem seed kernels'),
      findsOneWidget,
    );
    expect(find.text('Home-made, as published'), findsWidgets);
    final link = find.byKey(const Key('practices-labels-leaf_miner'));
    await tester.scrollUntilVisible(link, 200);
    await tester.ensureVisible(link);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await settle(tester);
    expect(find.text('Label information'), findsWidgets);
    await unmountApp(tester);
  });
}
