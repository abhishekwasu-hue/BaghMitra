// Market linkage L3 screens at phone width (360 dp), Marathi, 1.3x text, light and dark.
// Regenerate with:
//   flutter test --update-goldens test/goldens/market_link_l3_golden_test.dart
@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:bagmitra/api/generated/bagmitra.swagger.dart'
    show V1MarketPricesGetScope;
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/market/data/market_prices_cache.dart';
import 'package:bagmitra/features/market_link/data/market_lot_repository.dart';
import 'package:bagmitra/features/market_link/data/package_status.dart';
import 'package:bagmitra/features/market_link/domain/market_lot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/bahar/bahar_screen_test.dart' show seedPlot;
import '../features/market_link/lot_form_test.dart' show mlConfig;
import '../features/market_link/market_lot_repository_test.dart' show sampleLot;
import '../features/market_link/package_chip_test.dart' show FixedPackageStatus;
import '../features/plots/plots_screen_test.dart' show settle;
import '../helpers/pump_app.dart';

const _phone = Size(360, 780);

/// A real image file for the thumbnails (the app icon).
const _image = 'assets/icon/icon.png';

Future<void> _seedLots(AppDatabase db) async {
  await seedPlot(db);
  final repo = MarketLotRepository(db);
  await repo.save(sampleLot());
  await repo.save(sampleLot(id: 'l2'));
  await repo.keepServerState(
    'l2',
    status: 'published',
    publishedAt: DateTime.utc(2026, 10, 12),
    orchardCheck: 'inside',
  );
  for (final (i, lot) in [('a', 'l1'), ('b', 'l1'), ('c', 'l1'), ('d', 'l2')]) {
    await repo.savePhoto(
      LotPhoto(
        id: '$lot-$i',
        lotId: lot,
        capturedAt: DateTime.utc(2026, 10, 12, 5),
        lat: 21.1,
        lon: 79.0,
        photoPath: _image,
      ),
    );
  }
  // Today's (13 Oct) mandi price saved on the phone.
  await db.writeMeta(
    MarketPricesCache.keyFor('santra', V1MarketPricesGetScope.all),
    jsonEncode({
      'saved_at': '2026-10-13T05:00:00.000Z',
      'prices': {
        'stale': false,
        'prices': [
          {
            'day': '2026-10-13',
            'market': 'Warud',
            'state': 'Maharashtra',
            'district': 'Amravati',
            'commodity': 'Orange',
            'modal_rs_per_quintal': 3300,
            'source': 'agmarknet',
            'is_local': true,
            'is_major': false,
          },
        ],
      },
    }),
  );
}

Future<void> _precacheThumbnails(WidgetTester tester) async {
  final context = tester.element(find.byType(Scaffold).first);
  await tester.runAsync(() async {
    for (final width in [88 * 3, 56 * 3]) {
      await precacheImage(
        ResizeImage(FileImage(File(_image)), width: width),
        context,
      );
    }
  });
}

Future<void> _images(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await tester.pump();
}

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final m = mode.name;
    for (final (name, location, seed, scroll) in [
      ('l3_empty', '/market-link/lots', seedPlot, 0.0),
      ('l3_my_lots', '/market-link/lots', _seedLots, 0.0),
      ('l3_lot_form', '/market-link/lots/l1', _seedLots, 0.0),
      ('l3_photo_strip', '/market-link/lots/l1', _seedLots, 900.0),
    ]) {
      testWidgets('${name}_mr_$m', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(
          tester,
          config: mlConfig,
          themeMode: mode,
          initialLocation: location,
          seed: seed,
          size: _phone,
        );
        await settle(tester);
        // Decode the thumbnails in real time first, for every screen: images first built
        // inside the test's fake time may not finish loading (l3_my_lots flaked on CI).
        await _precacheThumbnails(tester);
        if (scroll > 0) {
          await tester.drag(find.byType(ListView).first, Offset(0, -scroll));
          await tester.pump();
        }
        await _images(tester);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('${name}_mr_$m.png'),
        );
        await unmountApp(tester);
      });
    }
  }

  // Sale form clarity (owner 2026-11-11, Q138): one start date picked, the end filled
  // 15 days later with "बदला", per quintal chosen, the label and the muted range line.
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('lot_form_quintal_mr_${mode.name}', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        config: mlConfig,
        themeMode: mode,
        initialLocation: '/market-link/lots/new?plot=p1',
        seed: _seedLots,
        size: _phone,
      );
      await settle(tester);
      // The list builds lazily at phone height: scroll each part into view first.
      final list = find.byType(Scrollable).first;
      Future<void> reach(String key) async {
        await tester.scrollUntilVisible(
          find.byKey(Key(key)),
          120,
          scrollable: list,
        );
        // Built in the cache area is not on screen yet.
        await tester.ensureVisible(find.byKey(Key(key)));
        await settle(tester);
      }

      await reach('lot-window-from');
      await tester.tap(find.byKey(const Key('lot-window-from')));
      await settle(tester);
      final ok = MaterialLocalizations.of(
        tester.element(find.byType(DatePickerDialog)),
      ).okButtonLabel;
      await tester.tap(find.text('१५').last);
      await tester.tap(find.text(ok));
      await settle(tester);
      await reach('lot-basis-per_quintal');
      await tester.tap(find.byKey(const Key('lot-basis-per_quintal')));
      await settle(tester);
      await reach('lot-rate');
      await tester.enterText(find.byKey(const Key('lot-rate')), '3500');
      FocusManager.instance.primaryFocus?.unfocus();
      await settle(tester);
      // The harvest window near the top, the rate and the mandi line below it.
      await tester.scrollUntilVisible(
        find.text('तोडणीचा काळ'),
        -120,
        scrollable: list,
      );
      final top = Scrollable.ensureVisible(
        tester.element(find.text('तोडणीचा काळ')),
      );
      await settle(tester);
      await top;
      expect(find.text('१५ ऑक्टो – ३० ऑक्टो'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('lot_form_quintal_mr_${mode.name}.png'),
      );
      await unmountApp(tester);
    });
  }

  // Season sale package chip (L9b, spec v1.5 §4E): an active and a not-active lot.
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('l9_package_chip_mr_${mode.name}', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        config: mlConfig,
        themeMode: mode,
        initialLocation: '/market-link/lots',
        seed: (db) async {
          await _seedLots(db);
          await MarketLotRepository(db).save(sampleLot(id: 'l3'));
          await MarketLotRepository(db).keepServerState(
            'l3',
            status: 'published',
            publishedAt: DateTime.utc(2026, 10, 13),
            orchardCheck: 'inside',
          );
        },
        size: _phone,
        overrides: [
          packageStatusSourceProvider.overrideWithValue(
            FixedPackageStatus(
              PackageStatus(
                switchOn: true,
                covers: {'l2': DateTime.utc(2026, 12, 31, 6)},
              ),
            ),
          ),
        ],
      );
      await settle(tester);
      await _images(tester);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('l9_package_chip_mr_${mode.name}.png'),
      );
      await unmountApp(tester);
    });
  }
}
