// Batch 1 of the practice drawings (owner 2026-11-09: every card like gummosis), Marathi,
// phone width, light and dark: all seven new drawings on one page.
//   flutter test --update-goldens test/goldens/practice_figures_golden_test.dart
@Tags(['golden'])
library;

import 'package:bagmitra/features/practices/data/practice_cards.dart';
import 'package:bagmitra/features/practices/presentation/practice_figure_view.dart';
import 'package:bagmitra/l10n/app_localizations.dart';
import 'package:bagmitra/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _figures = [
  PracticeFigure(PracticeFigureKind.stickyTrap, [2]),
  PracticeFigure(PracticeFigureKind.budHeight, [30, 46]),
  PracticeFigure(PracticeFigureKind.doubleRing, [45]),
  PracticeFigure(PracticeFigureKind.trunkBand, [5]),
  PracticeFigure(PracticeFigureKind.lureTrap, [15, 20]),
  PracticeFigure(PracticeFigureKind.shadySide),
  PracticeFigure(PracticeFigureKind.openCanopy),
  PracticeFigure(PracticeFigureKind.manureRing),
];

void main() {
  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('practice_figures_batch1_mr_$mode', (tester) async {
      tester.view.physicalSize = const Size(360, 1700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: dark ? BmTheme.dark() : BmTheme.light(),
          locale: const Locale('mr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final f in _figures)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PracticeFigureView(figure: f, lang: 'mr'),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('practice_figures_batch1_mr_$mode.png'),
      );
    });
  }
}
