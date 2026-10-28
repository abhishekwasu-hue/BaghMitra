// Crop insurance and claim kit screens. Regenerate with:
//   flutter test --update-goldens test/goldens/insurance_golden_test.dart
@Tags(['golden'])
library;

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/features/insurance/presentation/claim_report_page.dart';
import 'package:bagmitra/features/insurance/presentation/share_claim_kit.dart';
import 'package:bagmitra/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/bahar/bahar_screen_test.dart' show seedPlot;
import '../features/insurance/claim_kit_test.dart' show seedClaim;
import '../features/insurance/insurance_test.dart' show deadline, seedPolicy;
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

void main() {
  for (final (name, location, seed) in [
    ('insurance_mr_light', '/plots/p1/insurance', seedPolicy),
    ('insurance_empty_mr_light', '/plots/p1/insurance', seedPlot),
    ('add_policy_mr_light', '/plots/p1/insurance/new', seedPlot),
    ('claim_kit_mr_light', '/claim-kit/k1', seedClaim),
  ]) {
    testWidgets(name, (tester) async {
      await pumpApp(
        tester,
        initialLocation: location,
        seed: seed,
        overrides: [
          insuranceDeadlinesProvider.overrideWith(
            (ref, lang) async => name == 'insurance_mr_light'
                ? [deadline('a', season: 'ambia')]
                : const [],
          ),
        ],
      );
      await settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }

  testWidgets('claim_pdf_summary_mr', (tester) async {
    late ClaimReportContent content;
    await pumpApp(
      tester,
      initialLocation: '/plots/p1/insurance',
      seed: (db) async {
        await seedPolicy(db);
        await seedClaim(db); // re-saves the plot with its GPS
      },
    );
    await settle(tester);
    final element = tester.element(find.byType(Scaffold).first);
    final ref = ProviderScope.containerOf(element);
    await tester.runAsync(() async {
      final kit = await ref.read(claimKitRepositoryProvider).find('k1');
      content = await claimReportContent(
        ref.read,
        AppLocalizations.of(element),
        'mr',
        kit!,
      );
    });
    await unmountApp(tester);
    tester.view.physicalSize = const Size(595 * 2, 842 * 2);
    tester.view.devicePixelRatio = 2;
    await tester.pumpWidget(
      Center(child: RepaintBoundary(child: ClaimReportPage(content))),
    );
    await expectLater(
      find.byType(ClaimReportPage),
      matchesGoldenFile('claim_pdf_summary_mr.png'),
    );
  });
}
