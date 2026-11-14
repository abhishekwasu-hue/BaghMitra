import 'dart:convert';
import 'dart:io';

import 'package:bagmitra/features/bahar/data/stage_templates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/sources.dart';
import '../plots/plots_screen_test.dart' show settle;
import 'bahar_screen_test.dart' show seedPlot;

Map<String, dynamic> _asset() =>
    jsonDecode(File('assets/config/stage_templates.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('reference days ignore 29 February and cross year ends', () {
    expect(referenceDay(2028, 0), DateTime(2028));
    expect(
      referenceDay(2028, 59),
      DateTime(2028, 3),
    ); // a leap year: still 1 March
    expect(referenceDay(2027, 273), DateTime(2027, 10));
    expect(referenceDay(2027, 364), DateTime(2027, 12, 31));
    expect(referenceDay(2027, -24), DateTime(2026, 12, 8));
    expect(referenceDay(2027, 396), DateTime(2028, 2));
  });

  test('six crop × bahar templates; every stage names a read source', () {
    final set = StageTemplatesStore.parseBundled(_asset());
    expect(set.keys.toSet(), {
      for (final c in ['santra', 'mosambi'])
        for (final b in ['ambia', 'mrig', 'hasta']) templateKey(c, b),
    });
    for (final t in set.values) {
      for (final s in t.stages) {
        expect(t.sourcesFor(s.key), isNotEmpty, reason: '${t.crop}/${s.key}');
        expect(t.sourcesFor(s.key).every((x) => x.read != null), isTrue);
      }
    }
    // Mandarin Hasta: only the flowering month is published.
    expect(set['santra/hasta']!.stages.map((s) => s.key), ['flowering']);
  });

  test('the app bundles the same file the API seeds from', () {
    final api = File(
      '../api/src/bagmitra_api/bahar/seed_data/stage_templates.json',
    );
    expect(jsonDecode(api.readAsStringSync()), _asset());
  });

  test('chained windows follow the grower\'s own dates', () {
    final ambia = StageTemplatesStore.parseBundled(_asset())['santra/ambia']!;
    final w = ambia.windows(2027);
    expect(w['stress_start']!.from, DateTime(2026, 12, 8));
    expect(w['stress_start']!.to, DateTime(2026, 12, 14));
    expect(w['irrigation_restart']!.from, DateTime(2027, 1, 12)); // 8 Dec + 35
    expect(w['harvest']!.from, DateTime(2027, 10));
    expect(w.containsKey('fruit_set'), isFalse);

    final own = ambia.windows(2027, {'stress_start': DateTime(2026, 12, 20)});
    expect(own['irrigation_restart']!.from, DateTime(2027, 1, 24));
    expect(own['irrigation_restart']!.to, DateTime(2027, 3, 5));

    final filled = ambia.fillSuggested(2027, {
      'stress_start': DateTime(2026, 12, 20),
    });
    expect(filled['stress_start'], DateTime(2026, 12, 20)); // kept
    expect(filled['irrigation_restart'], DateTime(2027, 1, 24));
    expect(filled['flowering'], DateTime(2027, 2, 13)); // + 20 days
    expect(filled.containsKey('fruit_set'), isFalse);
  });

  test('the cached API copy reads its "name | title | url | read" sources', () {
    final set = StageTemplatesStore.parseCached([
      {
        'crop': 'santra',
        'bahar': 'mrig',
        'version': 2,
        'stages': [
          {
            'key': 'flowering',
            'anchor': 'season_start',
            'offset_days_min': 151,
            'offset_days_max': 211,
            'source_ids': ['N1'],
          },
        ],
        'sources': {
          'N1': 'NHB | Orange report | https://nhb.gov.in | read 2026-11-06',
        },
      },
    ]);
    final t = set['santra/mrig']!;
    expect(t.version, 2);
    expect(t.sourceNames(), ['NHB']);
    expect(t.checked(), DateTime(2026, 11, 6));
    expect(TemplateSource.fromLine('broken'), isNull);
  });

  testWidgets('Start bahar shows sourced windows and fills them on request', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/bahar/new',
      seed: seedPlot,
    );
    await settle(tester);
    await tester.tap(find.text('Ambia bahar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Suggested: 8 Dec 2025'), findsOneWidget);
    final none = find.textContaining('Enter your own date');
    await tester.scrollUntilVisible(none, 200);
    expect(none, findsOneWidget); // fruit set
    final note = find.byKey(const Key('stage-sources'));
    await tester.scrollUntilVisible(note, 200);
    expect(note, findsOneWidget);
    // Owner 2026-11-10: no "general information · confirm with your KVK" mark.
    expect(find.textContaining('General information'), findsNothing);
    // The source is one tap away, once for the screen (owner request); no date line
    // (owner 2026-11-14).
    expect(find.textContaining(RegExp(r'^Source: ')), findsNothing);
    await openAllSources(tester);
    expect(find.textContaining(RegExp(r'^Source: ')), findsOneWidget);
    expect(find.textContaining('6 Nov 2026'), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('fill-suggested')),
      -200,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, 150));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fill-suggested')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('1 Oct 2026'), 200);
    expect(find.text('1 Oct 2026'), findsOneWidget); // harvest
    await tester.scrollUntilVisible(find.text('8 Dec 2025'), -200);
    expect(
      find.text('8 Dec 2025'),
      findsOneWidget,
    ); // the stress start date row
    await unmountApp(tester);
  });
}
