import 'dart:convert';

import 'package:chopper/chopper.dart' show Request, Response;

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../sync/outbox.dart';
import '../../../sync/sync_engine.dart';
import '../../scouting/data/photo_backup.dart';
import 'market_lot_repository.dart';

/// Why a publish did not happen (or that it did).
enum PublishOutcome {
  published,
  closed,
  offline,
  photosNeeded,
  photoMissing,
  notAccepted,
  orchardCheck,
  failed,
}

/// The server's state of a lot after publish / close.
class ServerLotState {
  const ServerLotState(this.status, this.publishedAt, [this.orchardCheck]);
  final String status;
  final DateTime? publishedAt;
  final String? orchardCheck;
}

class LotApiException implements Exception {
  const LotApiException(this.code);
  final String code;
  @override
  String toString() => 'lot api: $code';
}

abstract interface class LotApi {
  /// Uploads one JPEG through the server, which strips its EXIF (GPS point) before storing
  /// it (spec v1.5 §4B); returns the stored key.
  Future<String> upload(String photoId, List<int> bytes);

  /// [action] is `publish` or `close`. Throws [LotApiException] with the server's code.
  Future<ServerLotState> change(String lotId, String action);
}

class HttpLotApi implements LotApi {
  HttpLotApi(this._api);

  final Bagmitra _api;

  static String _code(Response<Object?> res) {
    try {
      final body = res.error is String
          ? jsonDecode(res.error! as String)
          : res.error;
      if (body is Map && body['error'] is Map) {
        return '${(body['error'] as Map)['code']}';
      }
    } on FormatException {
      // fall through
    }
    return 'http_${res.statusCode}';
  }

  @override
  Future<String> upload(String photoId, List<int> bytes) async {
    // Raw JPEG bytes: the generated JSON client cannot send them, so the request is built
    // here on the same client (base URL, sign-in header, time limit).
    final res = await _api.client.send<String, String>(
      Request(
        'PUT',
        Uri.parse('/v1/market-link/lot-photos/$photoId/photo'),
        _api.client.baseUrl,
        body: bytes,
        headers: const {'Content-Type': 'image/jpeg'},
      ),
    );
    if (!res.isSuccessful) throw LotApiException(_code(res));
    final body = jsonDecode(res.bodyString);
    final key = body is Map ? body['photo_key'] : null;
    if (key is! String) throw const LotApiException('bad_response');
    return key;
  }

  @override
  Future<ServerLotState> change(String lotId, String action) async {
    final res = action == 'close'
        ? await _api.v1MarketLinkLotsLotIdClosePost(lotId: lotId)
        : await _api.v1MarketLinkLotsLotIdPublishPost(lotId: lotId);
    final body = res.body;
    if (!res.isSuccessful || body == null) throw LotApiException(_code(res));
    return ServerLotState(body.status, body.publishedAt, body.orchardCheck);
  }
}

/// Publishing is an online step (spec v1.5 §3 step 1): send the draft and its photos'
/// rows, upload each photo, send the keys, then ask the server to publish.
class LotPublisher {
  LotPublisher({
    required this._repo,
    required this._api,
    required this._files,
    required this._outbox,
    required this._sync,
    void Function(String)? log,
  }) : _log = log ?? ((_) {});

  final MarketLotRepository _repo;
  final LotApi _api;
  final PhotoFiles _files;
  final Outbox _outbox;
  final Future<SyncRunResult> Function() _sync;
  final void Function(String) _log;

  Future<bool> _sent(String lotId) async {
    if (await _outbox.hasPending(MarketLotRepository.lotEntity, lotId)) {
      return false;
    }
    for (final p in await _repo.photosOf(lotId)) {
      if (await _outbox.hasPending(MarketLotRepository.photoEntity, p.id)) {
        return false;
      }
    }
    return true;
  }

  Future<PublishOutcome> publish(String lotId) async {
    try {
      if ((await _sync()).offline) return PublishOutcome.offline;
      if (!await _sent(lotId)) return PublishOutcome.failed;
      for (final p in await _repo.photosOf(lotId)) {
        if (p.uploaded) continue;
        final path = p.photoPath;
        final bytes = path == null ? null : await _files.read(path);
        if (bytes == null) return PublishOutcome.photoMissing;
        await _repo.markUploaded(p.id, await _api.upload(p.id, bytes));
      }
      if ((await _sync()).offline) return PublishOutcome.offline;
      if (!await _sent(lotId)) return PublishOutcome.failed;
      return await _change(lotId, 'publish');
    } on LotApiException catch (e) {
      _log('lot publish: $e');
      return _outcome(e.code);
    } on Object catch (e) {
      _log('lot publish: ${e.runtimeType}');
      return PublishOutcome.failed;
    }
  }

  /// Takes a published lot off the buyers' list.
  Future<PublishOutcome> close(String lotId) async {
    try {
      return await _change(lotId, 'close');
    } on LotApiException catch (e) {
      _log('lot close: $e');
      return _outcome(e.code);
    } on Object catch (e) {
      _log('lot close: ${e.runtimeType}');
      return PublishOutcome.offline;
    }
  }

  Future<PublishOutcome> _change(String lotId, String action) async {
    final state = await _api.change(lotId, action);
    await _repo.keepServerState(
      lotId,
      status: state.status,
      publishedAt: state.publishedAt,
      orchardCheck: state.orchardCheck,
    );
    if (action == 'close') return PublishOutcome.closed;
    // Spec §4C: photos away from the mapped orchard -> published, but waits for an admin check.
    final check = state.orchardCheck;
    return check == 'inside' || check == 'near'
        ? PublishOutcome.published
        : PublishOutcome.orchardCheck;
  }

  static PublishOutcome _outcome(String code) => switch (code) {
    'lot_photos_needed' => PublishOutcome.photosNeeded,
    'lot_photos_not_uploaded' => PublishOutcome.photoMissing,
    'terms_not_accepted' => PublishOutcome.notAccepted,
    _ => PublishOutcome.failed,
  };
}
