import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../domain/offline_check.dart';

/// The model's input from a photo (JPEG / PNG bytes): upright, the whole photo resized
/// (no crop, like the training pipeline) to [OfflineModel.inputSize] square, RGB, float
/// 0..255 in row-major HWC order; the model scales it itself. Transparency is dropped (the
/// prepared photo is already drawn on white). Throws [FormatException] when the bytes are
/// not an image.
Float32List modelInputFrom(Uint8List encoded) {
  final decoded = img.decodeImage(encoded);
  if (decoded == null) throw const FormatException('not an image');
  final rgb = img
      .bakeOrientation(decoded)
      .convert(format: img.Format.uint8, numChannels: 3, noAnimation: true);
  final w = rgb.width, h = rgb.height;
  final src = Uint8List(w * h * 3);
  var i = 0;
  for (final p in rgb) {
    src[i++] = p.r.toInt();
    src[i++] = p.g.toInt();
    src[i++] = p.b.toInt();
  }
  const size = OfflineModel.inputSize;
  final across = _resizeRows(src, w, h, size);
  final square = _resizeColumns(across, size, h, size);
  return Float32List.fromList([for (final v in square) v.toDouble()]);
}

/// The training resize: PIL's `Image.resize(..., BILINEAR)`, a triangle filter widened by
/// the shrink factor (so a large photo is averaged, not sampled), first across, then down,
/// each pass rounded to 0..255 as PIL does for 8-bit photos.
({List<int> start, List<List<double>> weights}) _bilinearTaps(
  int inSize,
  int outSize,
) {
  final scale = inSize / outSize;
  final filterScale = scale < 1 ? 1.0 : scale;
  final support = filterScale; // the bilinear filter's support is 1
  final start = <int>[];
  final weights = <List<double>>[];
  for (var o = 0; o < outSize; o++) {
    final center = (o + 0.5) * scale;
    final lo = max(0, (center - support + 0.5).truncate());
    final hi = min(inSize, (center + support + 0.5).truncate());
    final k = [
      for (var x = lo; x < hi; x++)
        max(0.0, 1 - ((x - center + 0.5) / filterScale).abs()),
    ];
    final sum = k.fold(0.0, (a, b) => a + b);
    start.add(lo);
    weights.add([for (final v in k) sum == 0 ? 0.0 : v / sum]);
  }
  return (start: start, weights: weights);
}

int _clip8(double v) => v <= 0 ? 0 : (v >= 255 ? 255 : v.round());

/// [width] x [height] RGB to [outWidth] x [height].
Uint8List _resizeRows(Uint8List src, int width, int height, int outWidth) {
  final (:start, :weights) = _bilinearTaps(width, outWidth);
  final out = Uint8List(outWidth * height * 3);
  for (var y = 0; y < height; y++) {
    for (var o = 0; o < outWidth; o++) {
      final k = weights[o];
      for (var ch = 0; ch < 3; ch++) {
        var acc = 0.0;
        for (var j = 0; j < k.length; j++) {
          acc += k[j] * src[(y * width + start[o] + j) * 3 + ch];
        }
        out[(y * outWidth + o) * 3 + ch] = _clip8(acc);
      }
    }
  }
  return out;
}

/// [width] x [height] RGB to [width] x [outHeight].
Uint8List _resizeColumns(Uint8List src, int width, int height, int outHeight) {
  final (:start, :weights) = _bilinearTaps(height, outHeight);
  final out = Uint8List(width * outHeight * 3);
  for (var o = 0; o < outHeight; o++) {
    final k = weights[o];
    for (var x = 0; x < width; x++) {
      for (var ch = 0; ch < 3; ch++) {
        var acc = 0.0;
        for (var j = 0; j < k.length; j++) {
          acc += k[j] * src[((start[o] + j) * width + x) * 3 + ch];
        }
        out[(o * width + x) * 3 + ch] = _clip8(acc);
      }
    }
  }
  return out;
}

/// The model behind an interface: the real one runs the TFLite interpreter on the phone
/// ([TfliteLeafModel]); tests use a fake (the interpreter's native library is not there in
/// `flutter test`).
abstract interface class LeafModel {
  /// The class names in output order (`citrus_v1_labels.txt`).
  Future<List<String>> labels();

  /// One probability per label for one [modelInputFrom] input. Throws when the model cannot
  /// run on this phone.
  Future<List<double>> run(Float32List input);
}

/// `citrus_v1.tflite` through `tflite_flutter`. The interpreter is made, run and closed in a
/// background isolate per photo (one photo at a time, about a few hundred ms), so nothing
/// stays open between checks and the screen never stalls.
class TfliteLeafModel implements LeafModel {
  TfliteLeafModel(this._bundle);

  final AssetBundle _bundle;
  Future<Uint8List>? _model;
  Future<List<String>>? _labels;

  @override
  Future<List<String>> labels() => _labels ??= _bundle
      .loadString(OfflineModel.labelsAsset)
      .then(
        (text) => [
          for (final line in text.split('\n'))
            if (line.trim().isNotEmpty) line.trim(),
        ],
      );

  @override
  Future<List<double>> run(Float32List input) async {
    final model = await (_model ??= _bundle
        .load(OfflineModel.asset)
        .then((d) => d.buffer.asUint8List(d.offsetInBytes, d.lengthInBytes)));
    final count = (await labels()).length;
    return Isolate.run(() {
      final interpreter = Interpreter.fromBuffer(model);
      try {
        final shape = interpreter.getOutputTensor(0).shape;
        if (shape.isEmpty || shape.last != count) {
          throw StateError('model output $shape for $count labels');
        }
        final out = Float32List(count);
        interpreter.run(
          input.buffer.asUint8List(input.offsetInBytes, input.lengthInBytes),
          out.buffer,
        );
        return List<double>.of(out);
      } finally {
        interpreter.close();
      }
    });
  }
}

/// Photo in, [OfflineReading] out: the input is made off the UI thread, then the model runs.
class OfflineLeafCheck {
  OfflineLeafCheck(
    this.model, {
    Future<Float32List> Function(Uint8List)? toInput,
  }) : _toInput =
           toInput ?? ((photo) => Isolate.run(() => modelInputFrom(photo)));

  final LeafModel model;
  final Future<Float32List> Function(Uint8List) _toInput;

  /// Throws when the photo cannot be read or the model cannot run.
  Future<OfflineReading> check(Uint8List photo) async {
    final input = await _toInput(photo);
    final probabilities = await model.run(input);
    return OfflineReading.read(probabilities, await model.labels());
  }
}

/// The phone's leaf check; null where the TFLite library is not packaged (desktop, web and
/// `flutter test`), and the screen then keeps the plain "internet needed" line.
final offlineLeafCheckProvider = Provider<OfflineLeafCheck?>(
  (ref) => Platform.isAndroid || Platform.isIOS
      ? OfflineLeafCheck(TfliteLeafModel(rootBundle))
      : null,
);
