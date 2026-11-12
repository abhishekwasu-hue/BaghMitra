// Bill photo on the spray record and Add expense forms (Q136), Marathi, 360 dp phone, text
// at 1.3x, light and dark: each form with a photo attached and filled from the bill, and
// the pick-a-line sheet. Regenerate with:
//   flutter test --update-goldens test/goldens/bill_photo_golden_test.dart
@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../features/bahar/bahar_screen_test.dart' show seedPlot;
import '../features/bills/bill_forms_test.dart' show billOverrides;
import '../features/bills/bill_read_test.dart';
import '../features/photo_analysis/photo_analysis_test.dart' show json;
import '../features/plots/plots_screen_test.dart' show settle;
import '../features/scouting/scouting_test.dart' show FakePhotos;
import '../helpers/pump_app.dart';

/// A paper-white bill with grey lines, as a real file for the thumbnail.
String _billFile() {
  final image = img.Image(width: 300, height: 400)
    ..clear(img.ColorRgb8(250, 248, 240));
  for (var y = 40; y < 380; y += 28) {
    img.drawLine(
      image,
      x1: 24,
      y1: y,
      x2: y % 56 == 0 ? 200 : 276,
      y2: y,
      color: img.ColorRgb8(120, 120, 120),
      thickness: 3,
    );
  }
  final dir = Directory.systemTemp.createTempSync('bill_golden');
  final file = File('${dir.path}/bill.jpg')
    ..writeAsBytesSync(img.encodeJpg(image));
  return file.path;
}

String _bill() => billJson(
  shop: 'श्री कृषी सेवा केंद्र',
  items: [
    {
      'name': 'Imida 17.8 SL (इमिडाक्लोप्रिड)',
      'active_ingredient': 'imidacloprid',
      'quantity': 500,
      'unit': 'ml',
      'amount_rs': 650,
    },
    {
      'name': 'Ridomil Gold',
      'active_ingredient': 'metalaxyl + mancozeb',
      'quantity': 1,
      'unit': 'kg',
      'amount_rs': 1500,
    },
  ],
);

void main() {
  late String path;
  setUpAll(() => path = _billFile());

  for (final (name, location, pick) in [
    ('spray_form', '/plots/p1/sprays/new', 'bill-pick-0'),
    ('expense_form', '/plots/p1/accounts/expense', 'bill-pick-total'),
    ('pick_sheet', '/plots/p1/accounts/expense', null),
  ]) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      final file = 'bill_${name}_mr_${mode.name}_x13';
      testWidgets(file, (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(
          tester,
          themeMode: mode,
          initialLocation: location,
          seed: seedPlot,
          size: const Size(360, 1500),
          overrides: billOverrides(
            FakeBillServer((_) async => json(_bill(), 200)),
            FakePhotos(picked: path),
          ),
        );
        await settle(tester);
        await tester.tap(find.byKey(const Key('bill-photo-camera')));
        await settle(tester);
        await tester.tap(find.byKey(const Key('bill-fill')));
        await settle(tester);
        if (pick != null) {
          await tester.tap(find.byKey(Key(pick)));
          await settle(tester);
          // The spray form ticks lines, then fills (a tank mix, Q142).
          final fill = find.byKey(const Key('bill-pick-fill'));
          if (fill.evaluate().isNotEmpty) {
            await tester.tap(fill);
            await settle(tester);
          }
        }
        // Let the thumbnail decode.
        await tester.runAsync(() async {
          for (final e in find.byType(Image).evaluate()) {
            await precacheImage((e.widget as Image).image, e);
          }
        });
        await tester.pump();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('$file.png'),
        );
        await unmountApp(tester);
      });
    }
  }
}
