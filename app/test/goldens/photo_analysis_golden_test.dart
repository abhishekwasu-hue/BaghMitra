// Photo analysis ("फोटोवरून ओळखा", Q135 stage 3), Marathi, 360 dp phone, text at 1.3x:
// the result in light and dark, an unsure and a healthy answer, the daily limit and the
// offline line. Regenerate with:
//   flutter test --update-goldens test/goldens/photo_analysis_golden_test.dart
@Tags(['golden'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:bagmitra/features/photo_analysis/data/photo_analysis_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../features/bahar/bahar_screen_test.dart' show seedPlot;
import '../features/photo_analysis/photo_analysis_test.dart';
import '../features/plots/plots_screen_test.dart' show settle;
import '../features/scouting/scouting_test.dart' show FakePhotos;
import '../helpers/pump_app.dart';

/// A leaf-green picture for the preview.
final _leaf = () {
  final image = img.Image(width: 360, height: 200);
  for (final p in image) {
    p
      ..r = 40 + p.y ~/ 4
      ..g = 110 + p.x ~/ 6
      ..b = 50;
  }
  return Uint8List.fromList(img.encodeJpg(image));
}();

const _explanationCanker =
    'पानावर उठावदार, खडबडीत तपकिरी ठिपके आणि त्याभोवती पिवळी कडा दिसते. हे कँकर कार्डातील '
    'वर्णनाशी जुळते. कार्ड उघडून झाडाची इतर पाने व फळे तपासा.';
const _explanationGreening =
    'काही पानांवर पिवळसर डाग दिसतात. ग्रीनिंगची खात्री फक्त प्रयोगशाळेतील PCR तपासणीने होते. '
    'कार्ड उघडून लक्षणे जुळवा.';

Future<http.Response> Function(http.Request) _answer(String name) =>
    (_) async => switch (name) {
      'result' => json(
        analysisJson(
          candidates: [
            candidate('canker', explanationMr: _explanationCanker),
            candidate(
              'greening',
              confidence: 0.38,
              mr: 'ग्रीनिंग (HLB)',
              explanationMr: _explanationGreening,
              // No Marathi signs here: the fold says the English ones are shown.
              signs: englishOnlySigns,
            ),
          ],
        ),
        200,
      ),
      'unsure' => json(
        analysisJson(
          unsure: true,
          candidates: [
            candidate(
              'canker',
              confidence: 0.3,
              explanationMr: 'फोटो थोडा धूसर आहे; ठिपके अस्पष्ट दिसतात.',
            ),
          ],
        ),
        200,
      ),
      'healthy' => json(
        analysisJson(
          candidates: [
            candidate(
              'healthy',
              confidence: 0.9,
              mr: 'निरोगी दिसते',
              signs: noSigns,
              explanationMr:
                  'पाने हिरवीगार व एकसारखी दिसतात; फोटोतील झाड निरोगी झाडासारखे '
                  'आहे.',
            ),
          ],
        ),
        200,
      ),
      'limit' => json(limitJson('daily', resets: '2026-10-14T00:00:00Z'), 429),
      _ => http.Response('', 200),
    };

void main() {
  for (final (name, mode) in [
    ('result', ThemeMode.light),
    ('result', ThemeMode.dark),
    ('unsure', ThemeMode.light),
    ('healthy', ThemeMode.dark),
    ('limit', ThemeMode.light),
    ('offline', ThemeMode.dark),
  ]) {
    final file = 'photo_check_${name}_mr_${mode.name}_x13';
    testWidgets(file, (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final server = FakeAnalysisServer(
        name == 'offline'
            ? (_) async => throw const SocketException('no route')
            : _answer(name),
      );
      await pumpApp(
        tester,
        themeMode: mode,
        initialLocation: '/plots/p1/photo-check',
        seed: seedPlot,
        size: const Size(360, 1100),
        photos: FakePhotos(),
        overrides: [
          photoAnalysisApiProvider.overrideWithValue(server.api),
          photoPreparerProvider.overrideWithValue((_) async => _leaf),
        ],
      );
      await settle(tester);
      await tester.tap(find.byKey(const Key('photo-check-camera')));
      await settle(tester);
      if (name == 'result') {
        await tester.tap(find.byKey(const Key('photo-part-leaf')));
        await settle(tester);
      }
      await tester.tap(find.byKey(const Key('photo-check-run')));
      await settle(tester);
      if (name == 'result') {
        // The canker signs opened: Marathi, under the plain fold label.
        await tester.ensureVisible(find.byKey(const Key('photo-signs-canker')));
        await tester.tap(find.byKey(const Key('photo-signs-canker')));
        await settle(tester);
        // The tapped tile keeps focus; the picture shows the screen at rest.
        FocusManager.instance.primaryFocus?.unfocus();
        await settle(tester);
      }
      // Let the preview decode.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$file.png'),
      );
      await unmountApp(tester);
    });
  }
}
