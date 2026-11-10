import 'dart:convert';
import 'dart:io';

import 'package:bagmitra/features/lab_tests/data/lab_parameters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'lab_tests_test.dart' show FakeReportFiles, fakeFiles, seedLabTest;

void main() {
  test(
    'soil norms: official source with date, known parameters, no advice',
    () async {
      final catalog = LabParameters(bundle: FileAssetBundle());
      final norms = await catalog.loadNorms();
      expect(norms.keys, ['soil']);
      final soil = norms['soil']!;
      expect(soil.checked, DateTime(2026, 11, 6));
      expect(Uri.parse(soil.sourceUrl).host, endsWith('.gov.in'));
      final names = {for (final p in (await catalog.load())['soil']!) p.key};
      for (final r in soil.rows) {
        expect(names, contains(r.key), reason: r.key);
        expect(r.ranges, hasLength(3), reason: r.key);
        for (final g in r.ranges) {
          expect({'ok', 'mid', 'bad'}, contains(g.tone));
          expect(g.classLabels.keys.toSet(), {'en', 'mr', 'hi'});
        }
      }
      // Only the ranges the source prints: no N or B, no fertiliser product or dose.
      expect(soil.rows.map((r) => r.key), isNot(contains('n')));
      expect(soil.rows.map((r) => r.key), isNot(contains('b')));
      final raw = jsonEncode(
        (jsonDecode(File(LabParameters.asset).readAsStringSync())
            as Map)['norms'],
      ).toLowerCase();
      for (final word in [
        'urea',
        'dap',
        'mop',
        'kg/tree',
        'dose',
        'युरिया',
        'मात्रा',
      ]) {
        expect(raw, isNot(contains(word)), reason: word);
      }
    },
  );

  testWidgets('a soil test shows the rating ranges as general information', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/lab-tests/l1',
      seed: seedLabTest,
      overrides: fakeFiles(FakeReportFiles()),
    );
    await settle(tester);
    final card = find.byKey(const Key('lab-norms'));
    await tester.scrollUntilVisible(card, 200);
    expect(find.text('Soil Health Card rating ranges'), findsOne);
    await tester.tap(card);
    await settle(tester);
    // Owner 2026-11-10: no general-information mark; the sources stay folded.
    expect(find.textContaining('General information'), findsNothing);
    expect(find.textContaining('See sources'), findsOne);
    // One "ask an expert" line per screen: the hint keeps only the comparison.
    expect(
      find.text('Compare the value on your report with these ranges.'),
      findsOne,
    );
    expect(find.byKey(const Key('lab-norm-oc')), findsOne);
    expect(find.text('Low  < 0.5'), findsWidgets);
    await unmountApp(tester);
  });
}
