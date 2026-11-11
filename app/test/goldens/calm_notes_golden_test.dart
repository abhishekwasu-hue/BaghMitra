// Owner 2026-11-10: notes are small and muted, with no alarming box or words. These
// goldens show the calm spray note, the calm label screen and the screens that lost the
// "general information" mark, in light and dark. Regenerate with:
//   flutter test --update-goldens test/goldens/calm_notes_golden_test.dart
@Tags(['golden'])
library;

import 'dart:convert';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/labels/data/label_claims_cache.dart';
import 'package:bagmitra/features/schemes/data/scheme_ticks_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/bahar/bahar_screen_test.dart' show seedPlot;
import '../features/plots/plots_screen_test.dart' show settle;
import '../features/schemes/schemes_test.dart' show schemeFeed;
import '../features/spray/spray_ingredient_picker_test.dart'
    show chooseIngredientType;
import '../features/spray/spray_screen_test.dart' show seedPlotAndBanList;
import '../helpers/pump_app.dart';

/// A block with one registered label row and one banned row for the same target.
Future<void> _seedLabels(AppDatabase db) async {
  await seedPlot(db);
  await db.writeMeta(
    LabelClaimsCache.keyFor('santra'),
    jsonEncode({
      'saved_at': '2026-11-06T06:00:00.000Z',
      'response': {
        'kind': 'label_information',
        'claims': [
          {
            'active_ingredient': 'Chem A',
            'formulation': '25% SC',
            'target': 'Gummosis',
            'dose': '500 g/ha',
            'phi_days': 30,
            'label_crop': 'Citrus',
            'category': 'chemical',
            'source_key': 'cibrc_major_uses',
            'source_title': 'CIB&RC major uses of pesticides',
            'source_url': 'https://ppqs.gov.in/major-uses',
          },
        ],
        'blocked': [
          {
            'active_ingredient': 'Banned C',
            'formulation': '20% EC',
            'target': 'Gummosis',
            'label_crop': 'Citrus',
            'reason': 'banned',
            'notification': 'S.O. 1(E)',
          },
        ],
      },
    }),
  );
}

Future<void> _seedTicks(AppDatabase db) async {
  final store = SchemeTicksStore(db);
  await store.set('pm_kisan', 'aadhaar', has: true);
  await store.set('pm_kisan', 'satbara', has: true);
}

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final suffix = mode == ThemeMode.dark ? 'dark' : 'light';
    for (final (name, location, seed) in [
      ('add_spray_banned_mr', '/plots/p1/sprays/new', seedPlotAndBanList),
      ('labels_banned_mr', '/plots/p1/labels?target=gummosis', _seedLabels),
      if (mode == ThemeMode.dark) ...[
        ('lookalikes_mr', '/lookalikes?plot=p1', seedPlot),
        ('scheme_detail_mr', '/schemes/pm_kisan', _seedTicks),
      ],
    ]) {
      testWidgets('${name}_$suffix', (tester) async {
        await pumpApp(
          tester,
          themeMode: mode,
          initialLocation: location,
          seed: seed,
          overrides: [
            feedProvider.overrideWith((ref, lang) async => schemeFeed()),
          ],
        );
        await settle(tester);
        if (name.startsWith('add_spray')) {
          await chooseIngredientType(tester, 'इतर');
          await tester.enterText(
            find.byKey(const Key('spray-active')),
            'Kelthane',
          );
          await settle(tester);
        }
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('${name}_$suffix.png'),
        );
        await unmountApp(tester);
      });
    }
  }
}
