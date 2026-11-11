import 'dart:convert';
import 'dart:typed_data';

import 'package:chopper/chopper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../api/api_client.dart';
import '../../../api/generated/bagmitra.swagger.dart';
import '../../../app/providers.dart';
import '../../../core/net_failure.dart';
import '../../photo_analysis/data/photo_analysis_api.dart'
    show photoAnalysisTimeouts;
import '../../photo_analysis/domain/photo_analysis.dart';
import '../domain/bill_reading.dart';

/// Reads an agri-input shop's bill (`POST /v1/bills/read`, OPEN_QUESTIONS Q136).
abstract interface class BillReadApi {
  /// Throws [PhotoLimitException] (429 `bill_read_limit`) or [PhotoProblemException].
  Future<BillReading> read(Uint8List photo);
}

/// Over the app's authenticated client, hand-written like the photo analysis upload: one
/// multipart part `photo` (JPEG, at most 2 MiB; the phone re-encodes it first).
class HttpBillReadApi implements BillReadApi {
  HttpBillReadApi(this._api);

  final Bagmitra _api;

  static const path = '/v1/bills/read';

  @override
  Future<BillReading> read(Uint8List photo) async {
    final Response<String> res;
    try {
      res = await _api.client.send<String, String>(
        Request(
          'POST',
          Uri.parse(path),
          _api.client.baseUrl,
          multipart: true,
          parts: [
            PartValueFile<http.MultipartFile>(
              'photo',
              http.MultipartFile.fromBytes(
                'photo',
                photo,
                filename: 'bill.jpg',
              ),
            ),
          ],
        ),
      );
    } on Object catch (e) {
      final offline = netFailureForError(e) == NetFailure.offline;
      throw PhotoProblemException(
        offline ? PhotoProblem.offline : PhotoProblem.failed,
        '$e',
      );
    }
    final status = res.statusCode;
    if (status >= 200 && status < 300) {
      try {
        return BillReading.fromJson(
          jsonDecode(res.bodyString) as Map<String, dynamic>,
        );
      } on Object catch (e) {
        throw PhotoProblemException(PhotoProblem.failed, 'answer: $e');
      }
    }
    if (status == 429) throw _limit(res.bodyString);
    throw PhotoProblemException(switch (status) {
      401 || 403 => PhotoProblem.signedOut,
      413 || 415 || 422 => PhotoProblem.refused,
      503 => PhotoProblem.unavailable,
      _ => PhotoProblem.failed,
    }, 'http $status');
  }

  static PhotoLimitException _limit(String body) {
    Map<String, dynamic>? details;
    try {
      final error = (jsonDecode(body) as Map<String, dynamic>)['error'];
      details =
          (error as Map<String, dynamic>)['details'] as Map<String, dynamic>?;
    } on Object {
      details = null;
    }
    return PhotoLimitException(
      switch (details?['limit']) {
        'monthly' => PhotoLimitKind.monthly,
        'total' => PhotoLimitKind.total,
        _ => PhotoLimitKind.daily,
      },
      max: int.tryParse('${details?['max']}'),
      resetsAt: DateTime.tryParse('${details?['resets_at']}')?.toUtc(),
    );
  }
}

/// Reading a bill takes the model a while, like the photo check: the same long wait.
final billReadApiProvider = Provider<BillReadApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final auth = ref.watch(authRepositoryProvider);
  return HttpBillReadApi(
    createApi(
      baseUrl: Uri.parse(config.apiBaseUrl),
      token: () => auth.current?.accessToken,
      timeouts: photoAnalysisTimeouts,
    ),
  );
});
