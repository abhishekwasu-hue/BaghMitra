import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:chopper/chopper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../../../api/api_client.dart';
import '../../../api/generated/bagmitra.swagger.dart';
import '../../../app/providers.dart';
import '../../../core/net_failure.dart';
import '../domain/photo_analysis.dart';

/// The server side of the photo check (`docs/runbooks/photo-analysis.md`).
abstract interface class PhotoAnalysisApi {
  /// Throws [PhotoLimitException] or [PhotoProblemException] when there is no answer.
  Future<PhotoAnalysisResult> analyse({
    required String plotId,
    required Uint8List photo,
    PhotoPart? part,
    String? scoutingItem,
  });

  /// Deletes the analysed photo and its result on the server; an id the server no longer
  /// has counts as deleted. Throws [PhotoProblemException].
  Future<void> delete(String photoId);
}

/// Over the app's authenticated client. The generated method for the upload sends the whole
/// form as one JSON part named `body` (swagger_dart_code_generator), which the server cannot
/// read, so the request is built here with the `photo` file and the two plain fields.
class HttpPhotoAnalysisApi implements PhotoAnalysisApi {
  HttpPhotoAnalysisApi(this._api);

  final Bagmitra _api;

  @override
  Future<PhotoAnalysisResult> analyse({
    required String plotId,
    required Uint8List photo,
    PhotoPart? part,
    String? scoutingItem,
  }) async {
    final res = await _guard(
      () => _api.client.send<String, String>(
        Request(
          'POST',
          Uri.parse('/v1/plots/$plotId/photo-analysis'),
          _api.client.baseUrl,
          multipart: true,
          parts: [
            PartValueFile<http.MultipartFile>(
              'photo',
              http.MultipartFile.fromBytes(
                'photo',
                photo,
                filename: 'photo.jpg',
              ),
            ),
            if (part != null) PartValue<String>('part', part.wire),
            if (scoutingItem != null)
              PartValue<String>('scouting_item', scoutingItem),
          ],
        ),
      ),
    );
    final status = res.statusCode;
    if (status >= 200 && status < 300) {
      try {
        final out = PhotoAnalysisOut.fromJson(
          jsonDecode(res.bodyString) as Map<String, dynamic>,
        );
        return PhotoAnalysisResult(
          unsure: out.unsure,
          photoId: out.photoId,
          candidates: [
            for (final c in out.candidates)
              PhotoCandidate(
                key: c.key,
                name: {'en': c.name.en, 'mr': c.name.mr, 'hi': c.name.hi},
                confidence: c.confidence,
                signs: c.signs,
                explanation: {
                  'en': c.explanation.en,
                  'mr': c.explanation.mr,
                  'hi': c.explanation.hi,
                },
              ),
          ],
        );
      } on Object catch (e) {
        throw PhotoProblemException(PhotoProblem.failed, 'answer: $e');
      }
    }
    if (status == 429) throw _limit(res.bodyString);
    throw PhotoProblemException(_problemFor(status), 'http $status');
  }

  @override
  Future<void> delete(String photoId) async {
    final res = await _guard(
      () => _api.v1PhotoAnalysisPhotoIdDelete(photoId: photoId),
    );
    final status = res.statusCode;
    if ((status >= 200 && status < 300) || status == 404) return;
    throw PhotoProblemException(_problemFor(status), 'http $status');
  }

  static PhotoProblem _problemFor(int status) => switch (status) {
    401 || 403 => PhotoProblem.signedOut,
    413 || 415 || 422 => PhotoProblem.refused,
    503 => PhotoProblem.unavailable,
    _ => PhotoProblem.failed,
  };

  static PhotoLimitException _limit(String body) {
    Map<String, dynamic>? details;
    try {
      final error = (jsonDecode(body) as Map<String, dynamic>)['error'];
      details =
          (error as Map<String, dynamic>)['details'] as Map<String, dynamic>?;
    } on Object {
      details = null;
    }
    final kind = switch (details?['limit']) {
      'monthly' => PhotoLimitKind.monthly,
      'total' => PhotoLimitKind.total,
      _ => PhotoLimitKind.daily,
    };
    return PhotoLimitException(
      kind,
      max: int.tryParse('${details?['max']}'),
      resetsAt: DateTime.tryParse('${details?['resets_at']}')?.toUtc(),
    );
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PhotoProblemException {
      rethrow;
    } on Object catch (e) {
      final offline = netFailureForError(e) == NetFailure.offline;
      throw PhotoProblemException(
        offline ? PhotoProblem.offline : PhotoProblem.failed,
        '$e',
      );
    }
  }
}

/// Turns a picked photo into the JPEG the server takes: upright, at most
/// [PhotoLimits.maxSide] px on the long side, under [PhotoLimits.maxBytes], drawn on white
/// when it has transparency. Runs off the UI thread. Throws [PhotoUnreadableException].
Future<Uint8List> preparePhoto(List<int> bytes) async {
  final input = Uint8List.fromList(bytes);
  final out = await Isolate.run(() => _prepare(input));
  if (out == null) throw const PhotoUnreadableException();
  return out;
}

Uint8List? _prepare(Uint8List input) {
  final decoded = img.decodeImage(input);
  if (decoded == null) return null;
  var image = img.bakeOrientation(decoded);
  final longest = max(image.width, image.height);
  if (longest > PhotoLimits.maxSide) {
    image = image.width >= image.height
        ? img.copyResize(
            image,
            width: PhotoLimits.maxSide,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: PhotoLimits.maxSide,
            interpolation: img.Interpolation.average,
          );
  }
  if (image.hasAlpha) {
    final white = img.Image(width: image.width, height: image.height)
      ..clear(img.ColorRgb8(255, 255, 255));
    image = img.compositeImage(white, image);
  }
  Uint8List? jpeg;
  for (final quality in const [85, 75, 65, 50]) {
    jpeg = img.encodeJpg(image, quality: quality);
    if (jpeg.length < PhotoLimits.maxBytes) break;
  }
  return jpeg;
}

/// Reads a picked file and prepares it ([preparePhoto]). Tests override it.
typedef PhotoPreparer = Future<Uint8List> Function(String path);

final photoPreparerProvider = Provider<PhotoPreparer>(
  (ref) =>
      (path) async => preparePhoto(await File(path).readAsBytes()),
);

/// The model can take up to a minute or two (server timeout 120 s), longer than the 20 s
/// every other call waits, so this one call has its own client with a longer wait.
const photoAnalysisTimeouts = ApiTimeouts(receive: Duration(seconds: 150));

final photoAnalysisApiProvider = Provider<PhotoAnalysisApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final auth = ref.watch(authRepositoryProvider);
  return HttpPhotoAnalysisApi(
    createApi(
      baseUrl: Uri.parse(config.apiBaseUrl),
      token: () => auth.current?.accessToken,
      timeouts: photoAnalysisTimeouts,
    ),
  );
});
