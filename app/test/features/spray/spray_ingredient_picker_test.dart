import 'dart:convert';

import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/spray/data/restrictions_cache.dart';
import 'package:bagmitra/features/spray/data/spray_ingredients.dart';
import 'package:bagmitra/features/spray/presentation/spray_ingredient_picker.dart';
import 'package:bagmitra/l10n/app_localizations.dart';
import 'package:bagmitra/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;

/// Step 1 of the picker: choose a type by its label.
Future<void> chooseIngredientType(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const Key('spray-active-type')));
  await settle(tester);
  await tester.tap(find.text(label).last);
  await settle(tester);
}

/// Step 2: open the list and tap one compound by its shown text.
Future<void> chooseIngredient(WidgetTester tester, String shown) async {
  await tester.tap(find.byKey(const Key('spray-active-pick')));
  await settle(tester);
  await tester.tap(find.text(shown));
  await settle(tester);
}

Future<List<Map<String, Object?>>> _queued(
  WidgetTester tester,
  AppDatabase db,
) async {
  final rows = await tester.runAsync(
    () => (db.select(
      db.outboxEntries,
    )..where((t) => t.entity.equals('spray_record'))).get(),
  );
  return [for (final r in rows!) jsonDecode(r.payload) as Map<String, Object?>];
}

Future<void> _seedCarbofuranBan(AppDatabase db) async {
  await seedPlot(db);
  await db.writeMeta(
    RestrictionsCache.metaKey,
    jsonEncode({
      'restrictions': [
        {
          'active_ingredient': 'carbofuran',
          'kind': 'banned',
          'crops': <String>[],
          'crop_groups': <String>[],
          'notification': 'S.O. TEST(E)',
          'effective_from': '2020-01-01T00:00:00Z',
        },
      ],
      'synonyms': <Object>[],
    }),
  );
}

Future<void> _pumpPicker(
  WidgetTester tester,
  TextEditingController controller,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sprayIngredientsConfigProvider.overrideWithValue(
          SprayIngredientsConfig(bundle: FileAssetBundle()),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        theme: BmTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SprayIngredientPicker(controller: controller)),
      ),
    ),
  );
  await settle(tester);
}

void main() {
  testWidgets('type, then a compound from our list; the name is saved', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/sprays/new',
      seed: seedPlot,
    );
    await settle(tester);
    // No free-text box until the grower picks "Other".
    expect(find.byKey(const Key('spray-active')), findsNothing);
    await chooseIngredientType(tester, 'Fungicide');
    await tester.tap(find.byKey(const Key('spray-active-pick')));
    await settle(tester);
    // 12 fungicides: longer than 8, so the list has a search box; sorted by name.
    expect(find.byKey(const Key('spray-active-search')), findsOneWidget);
    expect(find.text('Aureofungin 46.15% w/v SP'), findsOneWidget);
    expect(find.text('Imidacloprid 17.80% SL'), findsNothing);
    await tester.enterText(
      find.byKey(const Key('spray-active-search')),
      'capt',
    );
    await settle(tester);
    expect(find.text('Aureofungin 46.15% w/v SP'), findsNothing);
    await tester.tap(find.text('Captan 75% WP'));
    await settle(tester);
    expect(find.text('Captan 75% WP'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('spray-product')), 'Captaf');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect((await _queued(tester, db)).single['active_ingredient'], 'Captan');
    await unmountApp(tester);
  });

  testWidgets('a short list has no search box; every tap target is 48 dp', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/sprays/new',
      seed: seedPlot,
    );
    await settle(tester);
    await chooseIngredientType(tester, 'Herbicide');
    expect(
      tester.getSize(find.byKey(const Key('spray-active-pick'))).height,
      greaterThanOrEqualTo(BmSpace.tapTarget),
    );
    await tester.tap(find.byKey(const Key('spray-active-pick')));
    await settle(tester);
    expect(find.byKey(const Key('spray-active-search')), findsNothing);
    expect(
      tester
          .getSize(find.byKey(const Key('spray-active-option-Diuron')))
          .height,
      greaterThanOrEqualTo(BmSpace.tapTarget),
    );
    await unmountApp(tester);
  });

  testWidgets('the ban check still reads an ingredient picked from the list', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/sprays/new',
      seed: _seedCarbofuranBan,
    );
    await settle(tester);
    expect(find.text('Outside the approved list'), findsNothing);
    await chooseIngredientType(tester, 'Insecticide');
    await chooseIngredient(tester, 'Carbofuran 03% CG');
    expect(find.text('Outside the approved list'), findsOneWidget);
    expect(find.textContaining('S.O. TEST(E)'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('Other shows the free-text box; what is typed is saved', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/sprays/new',
      seed: seedPlot,
    );
    await settle(tester);
    await chooseIngredientType(tester, 'Other');
    expect(
      find.text('Write the name as printed on the label.'),
      findsOneWidget,
    );
    // Typing a list name here does not jump away from the box.
    await tester.enterText(find.byKey(const Key('spray-active')), 'Sulphur');
    await settle(tester);
    expect(find.byKey(const Key('spray-active')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('spray-active')), 'Neem oil');
    await tester.enterText(find.byKey(const Key('spray-product')), 'Neem');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect((await _queued(tester, db)).single['active_ingredient'], 'Neem oil');
    await unmountApp(tester);
  });

  testWidgets('a type with no official list (tonic) is typed by the grower', (
    tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      initialLocation: '/plots/p1/sprays/new',
      seed: seedPlot,
    );
    await settle(tester);
    await chooseIngredientType(tester, 'Tonic');
    expect(find.byKey(const Key('spray-active-pick')), findsNothing);
    expect(find.byKey(const Key('spray-active')), findsOneWidget);
    // Nutrition types list the FCO 1985 Schedule I grades.
    await chooseIngredientType(tester, 'Nutrition: micronutrients');
    await chooseIngredient(tester, 'Chelated Zinc as Zn-EDTA');
    expect(find.text('Chelated Zinc as Zn-EDTA'), findsOneWidget);
    await chooseIngredientType(tester, 'Nutrition: water-soluble fertilisers');
    await chooseIngredient(tester, 'Calcium Nitrate');
    expect(find.text('Calcium Nitrate'), findsOneWidget);
    // Growth regulators come from our KB cards (owner 2026-11-11).
    await chooseIngredientType(tester, 'Growth regulator');
    await chooseIngredient(tester, 'Paclobutrazol');
    expect(find.text('Paclobutrazol'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('an old or filled-in value pre-selects its list entry', (
    tester,
  ) async {
    final c = TextEditingController(text: 'imidacloprid');
    addTearDown(c.dispose);
    await _pumpPicker(tester, c);
    expect(find.text('Insecticide'), findsOneWidget);
    expect(find.text('Imidacloprid 17.80% SL'), findsOneWidget);
    expect(c.text, 'Imidacloprid');

    // A value set from outside (the bill photo) after the form is open.
    c.text = 'Captan 75% WP';
    await settle(tester);
    expect(find.text('Fungicide'), findsOneWidget);
    expect(find.text('Captan 75% WP'), findsOneWidget);
    expect(c.text, 'Captan');

    // Anything not in the list lands under Other with its text.
    c.text = 'Kelthane';
    await settle(tester);
    expect(find.text('Other'), findsOneWidget);
    expect(find.byKey(const Key('spray-active')), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Kelthane'), findsOneWidget);
  });

  testWidgets('changing the type clears a compound of another type', (
    tester,
  ) async {
    final c = TextEditingController(text: 'Captan');
    addTearDown(c.dispose);
    await _pumpPicker(tester, c);
    await chooseIngredientType(tester, 'Insecticide');
    expect(c.text, isEmpty);
    expect(find.text('Choose from the list'), findsOneWidget);
  });
}
