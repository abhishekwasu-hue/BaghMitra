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
import 'package:bagmitra/features/market_link/domain/market_lot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/bahar/bahar_screen_test.dart' show seedPlot;
import '../features/market_link/lot_form_test.dart' show mlConfig;
import '../features/market_link/market_lot_repository_test.dart' show sampleLot;
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
        if (scroll > 0) {
          // Decode the thumbnails in real time first: images first built inside the
          // test's fake time never finish loading.
          await _precacheThumbnails(tester);
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
}
