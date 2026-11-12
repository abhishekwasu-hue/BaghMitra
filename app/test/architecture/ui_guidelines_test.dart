// Sunlight and thumb checks on the main list and form screens: every labelled tap target
// is at least 48 dp and text meets WCAG contrast (the santra buttons once failed at 2.4:1).
import 'dart:io';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/tasks/data/tasks_repository.dart';
import 'package:bagmitra/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/accounts/accounts_screen_test.dart' show seedAccounts;
import '../features/bahar/bahar_screen_test.dart' show seedPlot;
import '../features/feed/feed_data_test.dart' show FakeFeedRepository;
import '../features/feed/feed_screen_test.dart' show seedFeed;
import '../features/lab_tests/lab_tests_test.dart' show seedLabTest;
import '../features/labels/label_info_test.dart' show seedLabels;
import '../features/market/market_prices_test.dart' show seedPrices;
import '../features/plots/plots_screen_test.dart' show seedTwo, settle;
import '../features/spray/spray_screen_test.dart' show seedWithSpray;
import '../features/tasks/tasks_test.dart' show task;
import '../features/weather/weather_forecast_test.dart' show seedForecast;
import '../helpers/pump_app.dart';

Future<void> _seedTask(AppDatabase db) => TasksRepository(
  db,
  clock: () => DateTime.utc(2026, 10, 13, 6),
).save(task('t1', DateTime(2026, 10, 13)));

/// WCAG contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final (la, lb) = (a.computeLuminance(), b.computeLuminance());
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

Future<void> _seedForecast(AppDatabase db) => seedForecast(db);

void main() {
  for (final (location, seed) in [
    ('/', null),
    ('/plots', seedTwo),
    ('/tasks', _seedTask),
    ('/tasks/new', seedPlot),
    ('/plots/new', null),
    ('/plots/p1', seedPlot),
    ('/market', seedPrices),
    ('/feed/gr1', seedFeed),
    ('/plots/p1/sprays', seedWithSpray),
    ('/plots/p1/sprays/new', seedWithSpray),
    ('/plots/p1/accounts', seedAccounts),
    ('/plots/p1/accounts/expense', seedPlot),
    ('/plots/p1/labour/new', seedPlot),
    ('/plots/p1/insurance/new', seedPlot),
    ('/claim-kit?plot=p1', seedPlot),
    ('/plots/p1/lab-tests/new', seedPlot),
    ('/plots/p1/lab-tests/l1', seedLabTest),
    ('/plots/p1/labels', seedLabels),
    ('/schemes', null),
    ('/schemes/pm_kisan', null),
    ('/lookalikes?plot=p1', seedPlot),
    ('/labs', null),
    ('/market/directory', null),
    ('/plots/p1/weather', _seedForecast),
    ('/plots/p1/photo-check', seedPlot),
  ]) {
    testWidgets('tap targets and contrast on $location', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        initialLocation: location,
        seed: seed,
        overrides: [
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository(null)),
        ],
      );
      await settle(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await unmountApp(tester);
      handle.dispose();
    });
  }

  // Icons on a santra fill (camera button, alert tile) are graphics: WCAG asks 3:1.
  // White on santra is 2.4:1 and washes out in sunlight.
  for (final (name, c) in [
    ('light', BmColors.light),
    ('dark', BmColors.dark),
  ]) {
    test('icons on santra are readable ($name)', () {
      expect(contrast(c.onAccent, c.accent), greaterThanOrEqualTo(4.5));
      expect(contrast(c.onAccent, c.accentSoft), greaterThanOrEqualTo(4.5));
      expect(contrast(c.accentInk, c.card), greaterThanOrEqualTo(3));
    });

    // Buttons (owner 2026-11-12: "a button must feel like a button"): every role's label
    // is ≥ 4.5:1 on its fill, and the fill or border that marks the button out is ≥ 3:1
    // against the page and the card (WCAG non-text contrast), in both themes.
    test('button labels and shapes stand out ($name)', () {
      final theme = name == 'light' ? BmTheme.light() : BmTheme.dark();
      Color resolve<T>(WidgetStateProperty<T?>? p, [Set<WidgetState>? s]) =>
          switch (p?.resolve(s ?? {})) {
            final Color color => color,
            final BorderSide side => side.color,
            final other => throw StateError('no colour: $other'),
          };
      final roles = <String, (ButtonStyle, Color)>{
        // (style, the colour that outlines it against the page)
        'main commit (santra)': (theme.filledButtonTheme.style!, c.accentEdge),
        'primary (green)': (BmButtonStyle.primary(c), c.primaryFill),
        'secondary (outlined)': (
          theme.outlinedButtonTheme.style!,
          c.secondaryBorder,
        ),
        'secondary (text)': (theme.textButtonTheme.style!, c.secondaryBorder),
        'destructive': (BmButtonStyle.destructive(c), c.caution),
      };
      for (final MapEntry(key: role, value: (style, edge)) in roles.entries) {
        final fg = resolve(style.foregroundColor);
        final bg = resolve(style.backgroundColor);
        expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: role);
        for (final page in [c.background, c.card]) {
          expect(contrast(edge, page), greaterThanOrEqualTo(3), reason: role);
        }
      }
      // The destructive edge is its label colour; its own border and tint are calm.
      expect(c.caution, isNot(c.danger));
      // A disabled secondary button stays readable.
      final secondary = theme.outlinedButtonTheme.style!;
      const off = {WidgetState.disabled};
      expect(
        contrast(
          resolve(secondary.foregroundColor, off),
          resolve(secondary.backgroundColor, off),
        ),
        greaterThanOrEqualTo(4.5),
      );
      // Icon-only buttons: icon on its tonal circle, the circle's border on the page.
      final icon = BmButtonStyle.icon(c);
      expect(
        contrast(resolve(icon.foregroundColor), resolve(icon.backgroundColor)),
        greaterThanOrEqualTo(4.5),
      );
      final iconMain = BmButtonStyle.iconPrimary(c);
      expect(
        contrast(
          resolve(iconMain.foregroundColor),
          resolve(iconMain.backgroundColor),
        ),
        greaterThanOrEqualTo(4.5),
      );
      for (final page in [c.background, c.card]) {
        expect(contrast(c.secondaryBorder, page), greaterThanOrEqualTo(3));
        // Links are text on the page: 4.5:1.
        expect(contrast(c.link, page), greaterThanOrEqualTo(4.5));
      }
      // Every button label is bold.
      for (final style in [
        theme.filledButtonTheme.style!,
        theme.outlinedButtonTheme.style!,
        theme.textButtonTheme.style!,
        BmButtonStyle.primary(c),
        BmButtonStyle.destructive(c),
      ]) {
        expect(style.textStyle!.resolve({})!.fontWeight, FontWeight.w700);
      }
    });

    // M5: orange means action; a note (info) and a deadline or warning (caution) each
    // have their own ink, readable as body text on cards and on the page.
    test('info and caution inks are their own and readable ($name)', () {
      for (final ink in [c.info, c.caution]) {
        expect(contrast(ink, c.card), greaterThanOrEqualTo(4.5));
        expect(contrast(ink, c.background), greaterThanOrEqualTo(4.5));
        expect(ink, isNot(anyOf(c.accent, c.accentInk, c.accentSoft)));
      }
      expect(c.info, isNot(c.caution));
      expect(c.info, isNot(c.inkMuted));
    });
  }

  // M5: santra text is kept for actions (the camera label) and the stage hero number.
  // Notes use InfoNote (small, muted; owner 2026-11-10), deadlines and stale lines
  // BmColors.caution.
  test('accentInk is used only on actions and the stage number', () {
    final users = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            !f.path.endsWith('tokens.dart') &&
            f.readAsStringSync().contains('accentInk'))
          f.path.replaceAll(r'\', '/'),
    ]..sort();
    expect(users, [
      'lib/design_system/navigation.dart',
      'lib/design_system/stage_timeline.dart',
    ]);
  });
}
