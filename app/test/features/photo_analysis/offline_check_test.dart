import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bagmitra/features/photo_analysis/data/offline_leaf_model.dart';
import 'package:bagmitra/features/photo_analysis/domain/offline_check.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

const citrusLabels = ['canker', 'greening', 'healthy', 'other'];

/// The model, as the test wants it to answer; counts its runs.
class FakeLeafModel implements LeafModel {
  FakeLeafModel(this.probabilities, {this.fails = false});

  List<double> probabilities;
  final bool fails;
  final inputs = <Float32List>[];

  @override
  Future<List<String>> labels() async => citrusLabels;

  @override
  Future<List<double>> run(Float32List input) async {
    inputs.add(input);
    if (fails) throw StateError('no tflite library');
    return probabilities;
  }
}

/// A check over [FakeLeafModel] that skips decoding (the widget tests' photo is a stand-in).
OfflineLeafCheck fakeCheck(FakeLeafModel model) => OfflineLeafCheck(
  model,
  toInput: (_) async => Float32List(OfflineModel.inputSize * 2),
);

Uint8List png(img.Image image) => Uint8List.fromList(img.encodePng(image));

/// (r, g, b) of the model input at (x, y).
List<double> at(Float32List input, int x, int y) {
  final i = (y * OfflineModel.inputSize + x) * 3;
  return [input[i], input[i + 1], input[i + 2]];
}

void main() {
  group('preprocessing', () {
    test('one 224 x 224 RGB input, float 0..255, in R, G, B order', () {
      final input = modelInputFrom(
        png(
          img.Image(width: 50, height: 40)..clear(img.ColorRgb8(30, 140, 200)),
        ),
      );
      expect(input.length, 224 * 224 * 3);
      expect(at(input, 0, 0), [30, 140, 200]);
      expect(at(input, 223, 223), [30, 140, 200]);
      expect(input.every((v) => v >= 0 && v <= 255), isTrue);
      final white = modelInputFrom(
        png(
          img.Image(width: 8, height: 8)..clear(img.ColorRgb8(255, 255, 255)),
        ),
      );
      expect(white.every((v) => v == 255), isTrue);
    });

    test('the whole photo is resized, not cropped (both ends stay)', () {
      // Left quarter red, right quarter blue, on a wide photo.
      final image = img.Image(width: 800, height: 200)
        ..clear(img.ColorRgb8(0, 200, 0));
      img.fillRect(
        image,
        x1: 0,
        y1: 0,
        x2: 199,
        y2: 199,
        color: img.ColorRgb8(255, 0, 0),
      );
      img.fillRect(
        image,
        x1: 600,
        y1: 0,
        x2: 799,
        y2: 199,
        color: img.ColorRgb8(0, 0, 255),
      );
      final input = modelInputFrom(png(image));
      expect(at(input, 5, 112), [255, 0, 0]);
      expect(at(input, 112, 112), [0, 200, 0]);
      expect(at(input, 218, 112), [0, 0, 255]);
    });

    test('matches the training resize (PIL bilinear) within 1 level', () {
      // Values from Python: PIL Image.open(png).convert('RGB').resize((224, 224),
      // Image.BILINEAR) on this same picture (lossless PNG, so no decoder differences).
      final image = img.Image(width: 600, height: 380);
      for (final p in image) {
        p
          ..r = (p.x * 7 + p.y * 3) % 256
          ..g = (p.x * p.y) % 251
          ..b = ((p.x ~/ 13 + p.y ~/ 9) % 2) * 180 + 40;
      }
      final input = modelInputFrom(png(image));
      const pil = {
        (0, 0): [9, 0, 40],
        (223, 0): [90, 45, 97],
        (0, 223): [120, 62, 43],
        (223, 223): [201, 132, 98],
        (101, 57): [142, 113, 68],
        (112, 112): [117, 115, 40],
        (31, 200): [70, 114, 220],
        (190, 13): [52, 175, 220],
      };
      for (final MapEntry(key: (x, y), value: rgb) in pil.entries) {
        final got = at(input, x, y);
        for (var c = 0; c < 3; c++) {
          expect(
            (got[c] - rgb[c]).abs(),
            lessThanOrEqualTo(1),
            reason: '($x, $y)',
          );
        }
      }
    });

    test('a photo turned by EXIF is made upright first', () {
      // Stored 2 x 1 (left red, right blue) with orientation 6 (turn 90° clockwise):
      // upright it is 1 x 2, red on top, blue below.
      final image = img.Image(width: 2, height: 1)
        ..setPixelRgb(0, 0, 255, 0, 0)
        ..setPixelRgb(1, 0, 0, 0, 255);
      image.exif.imageIfd.orientation = 6;
      final input = modelInputFrom(Uint8List.fromList(img.encodeJpg(image)));
      final top = at(input, 112, 10), bottom = at(input, 112, 213);
      expect(top[0], greaterThan(top[2]));
      expect(bottom[2], greaterThan(bottom[0]));
    });

    test('grey, transparent and palette photos still give RGB', () {
      final grey = img.Image(width: 4, height: 4, numChannels: 1)
        ..clear(img.ColorUint8.rgb(90, 90, 90));
      expect(at(modelInputFrom(png(grey)), 100, 100), [90, 90, 90]);
      final clear = img.Image(width: 4, height: 4, numChannels: 4)
        ..clear(img.ColorRgba8(10, 120, 30, 0));
      expect(at(modelInputFrom(png(clear)), 100, 100), [10, 120, 30]);
      final palette = img.Image(width: 4, height: 4)
        ..clear(img.ColorRgb8(200, 60, 20));
      final quantized = img.quantize(palette, numberOfColors: 4);
      expect(at(modelInputFrom(png(quantized)), 100, 100), [200, 60, 20]);
    });

    test('bytes that are not an image are refused', () {
      expect(
        () => modelInputFrom(Uint8List.fromList(utf8.encode('not a photo'))),
        throwsFormatException,
      );
    });
  });

  group('outputs to what the screen shows', () {
    test('a disease above the threshold is named', () {
      final r = OfflineReading.read([0.72, 0.1, 0.1, 0.08], citrusLabels);
      expect(r.verdict, OfflineVerdict.disease);
      expect(r.shown.map((g) => g.key), ['canker']);
      expect(r.shown.single.probability, 0.72);
    });

    test('a second disease is named when it reaches the second-line level', () {
      final two = OfflineReading.read([0.28, 0.66, 0.04, 0.02], citrusLabels);
      expect(two.shown.map((g) => g.key), ['greening', 'canker']);
      final low = OfflineReading.read([0.2, 0.7, 0.05, 0.05], citrusLabels);
      expect(low.shown.map((g) => g.key), ['greening']);
      // Healthy or other in second place is not named.
      final healthy = OfflineReading.read([
        0.62,
        0.05,
        0.3,
        0.03,
      ], citrusLabels);
      expect(healthy.shown.map((g) => g.key), ['canker']);
    });

    test('the threshold: below it is not clear, at it a result', () {
      expect(OfflineModel.minConfidence, 0.6);
      final below = OfflineReading.read([0.59, 0.2, 0.11, 0.1], citrusLabels);
      expect(below.verdict, OfflineVerdict.unclear);
      expect(below.shown, isEmpty);
      expect(below.best?.key, 'canker');
      final atIt = OfflineReading.read([0.6, 0.2, 0.1, 0.1], citrusLabels);
      expect(atIt.verdict, OfflineVerdict.disease);
    });

    test('healthy reads as healthy; other is not clear', () {
      final healthy = OfflineReading.read([0.05, 0.1, 0.8, 0.05], citrusLabels);
      expect(healthy.verdict, OfflineVerdict.healthy);
      expect(healthy.shown.single.key, 'healthy');
      final other = OfflineReading.read([0.02, 0.05, 0.03, 0.9], citrusLabels);
      expect(other.verdict, OfflineVerdict.unclear);
      expect(other.shown, isEmpty);
    });

    test('a broken output does not crash and is not clear', () {
      final r = OfflineReading.read([double.nan, 0.3, 0.2, 0.1], citrusLabels);
      expect(r.verdict, OfflineVerdict.unclear);
      expect(
        () => OfflineReading.read([0.5, 0.5], citrusLabels),
        throwsArgumentError,
      );
    });

    test(
      'the check makes the input, runs the model and reads its labels',
      () async {
        final model = FakeLeafModel([0.1, 0.8, 0.05, 0.05]);
        final check = OfflineLeafCheck(
          model,
          toInput: (b) async => modelInputFrom(b),
        );
        final reading = await check.check(
          png(
            img.Image(width: 20, height: 20)..clear(img.ColorRgb8(80, 160, 60)),
          ),
        );
        expect(reading.verdict, OfflineVerdict.disease);
        expect(reading.shown.single.key, 'greening');
        expect(model.inputs.single.length, 224 * 224 * 3);
      },
    );
  });

  group('the model files', () {
    test('labels file is the training class order', () {
      final map = jsonDecode(
        File('../ml/labels_map.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final file = File(OfflineModel.labelsAsset)
          .readAsLinesSync()
          .where((l) => l.trim().isNotEmpty)
          .toList();
      expect(file, map['classes']);
      expect(file, citrusLabels);
    });

    test('the model is the trained file named in the model card', () async {
      final bytes = File(OfflineModel.asset).readAsBytesSync();
      final hash = await Sha256().hash(bytes);
      final hex = [
        for (final b in hash.bytes) b.toRadixString(16).padLeft(2, '0'),
      ].join();
      expect(bytes.length, 2735448);
      expect(hex, startsWith('16aa4482'));
      expect(hex, endsWith('3ae29a'));
      final card = File('assets/models/citrus_v1_model_card.md')
          .readAsStringSync();
      expect(card, contains(hex));
    });

    test('the pubspec ships the model and labels', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- ${OfflineModel.asset}'));
      expect(pubspec, contains('- ${OfflineModel.labelsAsset}'));
      expect(pubspec, contains(RegExp(r'tflite_flutter: \d+\.\d+\.\d+\n')));
    });
  });
}
