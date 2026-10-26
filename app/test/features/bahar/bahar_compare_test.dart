import 'package:bagmitra/features/bahar/data/bahar_compare.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'bahar_screen_test.dart' show seedPlot, seedPlotWithCycle;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<BaharCompareData> load() =>
      BaharCompareConfig(bundle: rootBundle).load();

  test(
    'every point is sourced, labelled in en/mr/hi and names a known answer',
    () async {
      final data = await load();
      expect(data.points, isNotEmpty);
      final answers = {
        for (final q in data.questions)
          q.key: {for (final o in q.options) o.slug},
      };
      for (final p in data.points) {
        expect(p.source, isNotEmpty);
        expect(p.labels.keys, containsAll(['en', 'mr', 'hi']));
        for (final MapEntry(:key, :value) in p.when.entries) {
          expect(answers[key], contains(value), reason: p.labels['en']);
        }
      }
    },
  );

  test(
    'a point shows only when all its conditions match the answers',
    () async {
      final data = await load();
      final unanswered = data.pointsFor('mrig', const {});
      final short = data.pointsFor('mrig', const {'water_apr_may': 'short'});
      expect(unanswered.every((p) => p.when.isEmpty), isTrue);
      expect(short.length, greaterThan(unanswered.length));
      expect(
        data.pointsFor('ambia', const {'water_apr_may': 'short'}),
        isNotEmpty,
        reason: 'sources disagree: both sides are shown',
      );
      expect(data.pointsFor('hasta', const {}), isEmpty);
    },
  );

  testWidgets('compare bahars from start bahar, then use one', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/bahar/new',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('compare-bahars')));
    await settle(tester);
    expect(find.text('Compare bahars'), findsOneWidget);
    expect(find.textContaining('decision is yours'), findsOneWidget);
    expect(find.text('No bahar recorded on this block yet.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('answer-water_apr_may-short')));
    await settle(tester);
    expect(find.textContaining('NHB'), findsWidgets);

    await tester.scrollUntilVisible(find.byKey(const Key('use-mrig')), 200);
    await tester.tap(find.byKey(const Key('use-mrig')));
    await settle(tester);
    expect(find.text('Start a bahar'), findsOneWidget);
    final chip = tester.widget<ChoiceChip>(
      find.ancestor(
        of: find.text('Mrig bahar'),
        matching: find.byType(ChoiceChip),
      ),
    );
    expect(chip.selected, isTrue);
    await unmountApp(tester);
  });

  testWidgets('shows the last bahar recorded on the block', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/bahar/compare',
      seed: seedPlotWithCycle,
    );
    await settle(tester);
    expect(
      find.textContaining('Last bahar on this block: Ambia bahar'),
      findsOneWidget,
    );
    await unmountApp(tester);
  });
}
