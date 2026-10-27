import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/plots/data/plot_repository.dart';
import 'package:bagmitra/features/plots/domain/plot.dart';
import 'package:bagmitra/features/practices/data/irrigation_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;

// No fertiliser or chemical content in the irrigation guide.
const _enBanned = [
  'spray',
  'fertili',
  'urea',
  'npk',
  'fungicide',
  'insecticide',
  'pesticide',
  'cycocel',
  'paclobutrazol',
  'gram n',
  'ml/l',
  'g/l',
];
const _mrBanned = ['फवार', 'खत', 'कीटकनाशक', 'बुरशीनाशक', 'युरिया'];
const _hiBanned = ['छिड़क', 'उर्वरक', 'खाद', 'कीटनाशक', 'यूरिया'];

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

Future<void> Function(AppDatabase) _seed(String crop, int? plantingYear) =>
    (db) => PlotRepository(db).save(
      Plot(
        id: 'p1',
        name: 'बाग १',
        crop: crop,
        areaSqM: 2 * Plot.sqMPerAcre,
        plantingYear: plantingYear,
      ),
    );

void main() {
  late IrrigationGuideData data;

  setUpAll(() async {
    data = await IrrigationGuideConfig(bundle: FileAssetBundle()).load();
  });

  test('every row and note is sourced, translated and free of chemicals', () {
    expect(data.isDraft, isTrue);
    expect(data.crops.keys, containsAll(['santra', 'mosambi']));
    expect(data.seasons.keys, ['year', 'winter', 'summer', 'rainy']);
    final bandKeys = {for (final b in data.ageBands) b.key};
    expect(bandKeys, {'young', 'middle', 'mature'});
    for (final b in data.ageBands) {
      _expectClean(b.labels, 'band ${b.key}');
    }
    for (final s in data.seasons.entries) {
      _expectClean(s.value, 'season ${s.key}');
    }
    for (final m in data.methods.entries) {
      _expectClean(m.value, 'method ${m.key}');
    }
    for (final s in data.sources.values) {
      expect(s.title, isNotEmpty);
      expect(Uri.parse(s.url).isScheme('https'), isTrue, reason: s.url);
    }
    final ids = <String>{};
    for (final MapEntry(key: crop, value: g) in data.crops.entries) {
      expect(g.rows, isNotEmpty, reason: crop);
      for (final r in g.rows) {
        expect(ids.add(r.id), isTrue, reason: 'duplicate id ${r.id}');
        _expectClean(r.labels, 'row ${r.id}');
        expect(r.source, isNotEmpty, reason: 'row ${r.id} source');
        expect(r.sourceKeys, isNotEmpty, reason: 'row ${r.id} source keys');
        for (final k in r.sourceKeys) {
          expect(data.sources, contains(k), reason: 'row ${r.id} cites $k');
        }
        expect(r.ages, isNotEmpty);
        expect(bandKeys, containsAll(r.ages), reason: 'row ${r.id} ages');
        expect(data.seasons, contains(r.season), reason: 'row ${r.id}');
        expect(data.methods, contains(r.method), reason: 'row ${r.id}');
      }
      for (final n in g.notes) {
        expect(ids.add(n.id), isTrue, reason: 'duplicate id ${n.id}');
        _expectClean(n.labels, 'note ${n.id}');
        expect(n.source, isNotEmpty);
        for (final k in n.sourceKeys) {
          expect(data.sources, contains(k), reason: 'note ${n.id} cites $k');
        }
        expect(n.sourceKeys, isNotEmpty);
      }
      for (final (i, gap) in g.gaps.indexed) {
        _expectClean(gap, '$crop gap $i');
      }
    }
    // Santra has a sourced row for every age band.
    for (final b in bandKeys) {
      expect(
        data.crops['santra']!.rows.where((r) => r.ages.contains(b)),
        isNotEmpty,
        reason: 'santra $b',
      );
    }
  });

  test('young and middle mosambi have sourced rows; bahar rest is sourced', () {
    final m = data.crops['mosambi']!;
    for (final b in ['young', 'middle']) {
      final rows = [for (final s in data.seasons.keys) ...m.rowsFor(b, s)];
      expect(
        rows.where((r) => r.labels['en']!.contains('litres per tree per day')),
        isNotEmpty,
        reason: 'mosambi $b litres',
      );
    }
    expect([
      for (final r in m.rowsFor('young', 'summer')) r.id,
    ], contains('m6'));
    expect([
      for (final r in m.rowsFor('middle', 'summer')) r.id,
    ], contains('m7'));
    expect([for (final r in m.rowsFor('young', 'year')) r.id], contains('m10'));
    final byId = {for (final r in m.rows) r.id: r};
    expect(byId['m6']!.sourceKeys, ['AW18']);
    expect(byId['m10']!.sourceKeys, ['CH24']);
    expect(byId['m11']!.sourceKeys, ['MP25']);
    final notes = {for (final n in m.notes) n.id: n};
    expect(notes['mn5']!.sourceKeys, ['MP25']);
    expect(notes['mn6']!.sourceKeys, ['AW24', 'AW23']);
    expect(notes['mn6']!.label('en'), contains('35–45 days'));
    expect(notes['mn7']!.sourceKeys, ['VK']);
    // The bahar-length gap is closed; only the winter / rainy litres gap stays.
    expect(m.gaps, hasLength(1));
    // Santra young and middle now have a summer row too.
    final s = data.crops['santra']!;
    expect([
      for (final r in s.rowsFor('young', 'summer')) r.id,
    ], contains('s20'));
    expect([
      for (final r in s.rowsFor('middle', 'summer')) r.id,
    ], contains('s21'));
  });

  test('tree age band from the planting year', () {
    expect(data.bandFor(null, 2026), isNull);
    expect(data.bandFor(2027, 2026), isNull);
    expect(data.bandFor(2026, 2026)?.key, 'young');
    expect(data.bandFor(2022, 2026)?.key, 'young');
    expect(data.bandFor(2021, 2026)?.key, 'middle');
    expect(data.bandFor(2018, 2026)?.key, 'middle');
    expect(data.bandFor(2017, 2026)?.key, 'mature');
    expect(data.bandFor(1990, 2026)?.key, 'mature');
  });

  test('labels and unknown keys fall back', () {
    const row = IrrigationRow(
      id: 'x',
      ages: ['young'],
      season: 'year',
      method: 'drip',
      labels: {'en': 'Drip'},
      source: 'N1',
      sourceKeys: ['N1'],
    );
    expect(row.label('mr'), 'Drip');
    expect(
      const IrrigationNote('n', {'en': 'A'}, 'N1', ['N1']).label('hi'),
      'A',
    );
    expect(data.seasonLabel('monsoon', 'en'), 'monsoon');
    expect(data.methodLabel('flood', 'mr'), 'flood');
    expect(data.ageBands.first.label('xx'), 'Young (1–4 years)');
  });

  testWidgets('a santra block opens with its tree age and its rows', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1',
      seed: _seed('santra', 2019),
    );
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('open-irrigation-guide')));
    await tester.tap(find.byKey(const Key('open-irrigation-guide')));
    await settle(tester);

    expect(find.text('Irrigation guide'), findsOneWidget);
    expect(find.byKey(const Key('irrigation-caveat')), findsOneWidget);
    expect(find.textContaining('Check with your KVK'), findsOneWidget);
    expect(find.text('Planted in 2019: about 7 years old'), findsOneWidget);
    // A block has one crop: no crop chooser.
    expect(find.byKey(const Key('irrigation-crop-mosambi')), findsNothing);
    expect(find.textContaining('Draft'), findsNothing);

    // Clock is 2026 in tests: 7 years old = middle band.
    final middle = tester.widget<ChoiceChip>(
      find.byKey(const Key('irrigation-age-middle')),
    );
    expect(middle.selected, isTrue);
    expect(find.text('About 35–105 litres per tree per day.'), findsOneWidget);
    expect(find.text('About 5–15 litres per tree per day.'), findsNothing);
    expect(find.textContaining('N1: NHB Model Project Report'), findsWidgets);

    await tester.tap(find.byKey(const Key('irrigation-age-young')));
    await settle(tester);
    expect(find.text('About 5–15 litres per tree per day.'), findsOneWidget);
    expect(find.text('About 35–105 litres per tree per day.'), findsNothing);

    await tester.tap(find.byKey(const Key('irrigation-age-mature')));
    await settle(tester);
    final winter = find.byKey(const Key('irrigation-season-winter'));
    await tester.scrollUntilVisible(winter, 300);
    expect(winter, findsOneWidget);
    final s9 = find.byKey(const Key('irrigation-s9'));
    await tester.scrollUntilVisible(s9, 300);
    expect(s9, findsOneWidget);

    final sources = find.byKey(const Key('irrigation-sources'));
    await tester.scrollUntilVisible(sources, 300);
    expect(find.byKey(const Key('irrigation-sn7')), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a mosambi block without a planting year asks for the age', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/irrigation-guide',
      seed: _seed('mosambi', null),
    );
    await settle(tester);
    expect(
      find.text(
        'Planting year not entered for this block. Choose the tree age.',
      ),
      findsOneWidget,
    );
    // Young is the default band; mosambi rows only, no santra litres.
    expect(find.byKey(const Key('irrigation-m4')), findsOneWidget);
    expect(find.byKey(const Key('irrigation-s1')), findsNothing);
    expect(find.byKey(const Key('irrigation-m1')), findsNothing);
    final m10 = find.byKey(const Key('irrigation-m10'));
    await tester.scrollUntilVisible(m10, 300);
    expect(m10, findsOneWidget);
    final m6 = find.byKey(const Key('irrigation-m6'));
    await tester.scrollUntilVisible(m6, 300);
    expect(m6, findsOneWidget);
    expect(find.byKey(const Key('irrigation-m7')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('irrigation-age-middle')),
      -300,
    );
    await tester.tap(find.byKey(const Key('irrigation-age-middle')));
    await settle(tester);
    final m7 = find.byKey(const Key('irrigation-m7'));
    await tester.scrollUntilVisible(m7, 300);
    expect(m7, findsOneWidget);
    expect(find.byKey(const Key('irrigation-m6')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('irrigation-age-mature')),
      -300,
    );
    await tester.tap(find.byKey(const Key('irrigation-age-mature')));
    await settle(tester);
    final m1 = find.byKey(const Key('irrigation-m1'));
    await tester.scrollUntilVisible(m1, 300);
    expect(m1, findsOneWidget);
    final gaps = find.text('Not found in the sources yet');
    await tester.scrollUntilVisible(gaps, 300);
    expect(gaps, findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('guide renders in Marathi and switches crop', (tester) async {
    await pumpApp(tester, initialLocation: '/practices');
    await settle(tester);
    await tester.tap(find.byKey(const Key('open-irrigation-guide-all')));
    await settle(tester);

    expect(find.text('ओलित तक्ता'), findsOneWidget);
    expect(find.textContaining('कृषी विज्ञान केंद्राला'), findsOneWidget);
    expect(find.text('लहान (१–४ वर्षे)'), findsOneWidget);
    expect(find.text('दर झाडाला दररोज सुमारे ५–१५ लिटर.'), findsOneWidget);
    expect(find.text('ठिबक'), findsWidgets);
    expect(find.text('हिवाळा'), findsOneWidget);

    await tester.tap(find.byKey(const Key('irrigation-crop-mosambi')));
    await settle(tester);
    expect(find.text('दर झाडाला दररोज सुमारे ५–१५ लिटर.'), findsNothing);
    expect(find.text('दर १०–१२ दिवसांनी पाणी.'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('an unknown crop shows that no figure is in the sources', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('hi'),
      initialLocation: '/plots/p1/irrigation-guide',
      seed: _seed('lemon', 2020),
    );
    await settle(tester);
    expect(find.byKey(const Key('irrigation-no-rows')), findsOneWidget);
    expect(find.text('रोपण 2020: लगभग 6 साल के पेड़'), findsOneWidget);
    await unmountApp(tester);
  });
}
