import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:chopper/chopper.dart' show Response;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../core/clock.dart';
import '../../../data/local/database.dart';
import '../../../sync/backoff.dart';
import '../../../sync/outbox.dart';
import '../../bills/data/bill_photos.dart';
import '../domain/scouting_record.dart';
import 'scouting_photos.dart';
import 'scouting_repository.dart';

// Optional backup of scouting photos to the server (OPEN_QUESTIONS Q34).
//
// After a record with a photo has synced, the phone asks the API for a signed upload URL,
// PUTs the JPEG straight to the private bucket, then records the returned `photo_key` on
// the record through the normal outbox. Another phone of the same grower sees the key,
// asks for a short-lived download URL when the record is viewed and keeps the file.
//
// When to upload: this app has no connectivity plugin, so Wi-Fi is recognised from the
// phone's network interface names ([looksLikeWifi]). Uploads run on Wi-Fi, or on any
// connection when the grower turns on "Back up photos on mobile data" (off by default).
// Viewing a backed-up photo on another phone downloads it on any connection, because the
// grower asked to see it. If the server answers 503 (backup not configured) nothing more
// is tried until the next app start.
//
// Bill photos of spray records and expenses (OPEN_QUESTIONS Q136) ride the same run, with the
// same rules, after the scouting photos ([BillBackupTarget]).

/// The server has no photo storage configured (503).
class PhotoBackupOffException implements Exception {
  const PhotoBackupOffException();
}

/// The server refused this photo (too large, record unknown, file gone): not retried.
class PhotoBackupRefusedException implements Exception {
  const PhotoBackupRefusedException(this.reason);
  final String reason;
  @override
  String toString() => 'photo refused: $reason';
}

/// Network or server trouble: tried again later.
class PhotoBackupFailedException implements Exception {
  const PhotoBackupFailedException(this.reason);
  final String reason;
  @override
  String toString() => 'photo backup failed: $reason';
}

class PhotoUploadTicket {
  const PhotoUploadTicket(this.uploadUrl, this.photoKey);
  final Uri uploadUrl;
  final String photoKey;
}

abstract interface class PhotoBackupApi {
  Future<PhotoUploadTicket> uploadUrl(String recordId, int sizeBytes);
  Future<void> put(Uri url, List<int> bytes);
  Future<Uri> downloadUrl(String recordId);
  Future<List<int>> get(Uri url);
}

/// Signed URLs for a bill photo (`/v1/bill-photos/{kind}/{record_id}/...`); the bytes go
/// through [PhotoBackupApi.put] / [PhotoBackupApi.get].
abstract interface class BillPhotoBackupApi {
  Future<PhotoUploadTicket> billUploadUrl(
    BillKind kind,
    String recordId,
    int sizeBytes,
  );
  Future<Uri> billDownloadUrl(BillKind kind, String recordId);
}

class HttpPhotoBackupApi implements PhotoBackupApi, BillPhotoBackupApi {
  HttpPhotoBackupApi(
    this._api, {
    http.Client? client,
    this.timeout = const Duration(seconds: 60),
  }) : _client = client ?? http.Client();

  static const contentType = 'image/jpeg';

  final Bagmitra _api;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<PhotoUploadTicket> uploadUrl(String recordId, int sizeBytes) async {
    final body = _check(
      await _guard(
        () => _api.v1ScoutingRecordIdPhotoUploadUrlPost(
          recordId: recordId,
          body: PhotoUploadIn(contentType: contentType, sizeBytes: sizeBytes),
        ),
      ),
    );
    return PhotoUploadTicket(Uri.parse(body.uploadUrl), body.photoKey);
  }

  @override
  Future<Uri> downloadUrl(String recordId) async {
    final body = _check(
      await _guard(
        () => _api.v1ScoutingRecordIdPhotoUrlGet(recordId: recordId),
      ),
    );
    return Uri.parse(body.url);
  }

  @override
  Future<PhotoUploadTicket> billUploadUrl(
    BillKind kind,
    String recordId,
    int sizeBytes,
  ) async {
    final body = _check(
      await _guard(
        () => _api.v1BillPhotosKindRecordIdUploadUrlPost(
          kind: switch (kind) {
            BillKind.spray =>
              V1BillPhotosKindRecordIdUploadUrlPostKind.sprayRecord,
            BillKind.expense =>
              V1BillPhotosKindRecordIdUploadUrlPostKind.expense,
          },
          recordId: recordId,
          body: PhotoUploadIn(contentType: contentType, sizeBytes: sizeBytes),
        ),
      ),
    );
    return PhotoUploadTicket(Uri.parse(body.uploadUrl), body.photoKey);
  }

  @override
  Future<Uri> billDownloadUrl(BillKind kind, String recordId) async {
    final body = _check(
      await _guard(
        () => _api.v1BillPhotosKindRecordIdUrlGet(
          kind: switch (kind) {
            BillKind.spray => V1BillPhotosKindRecordIdUrlGetKind.sprayRecord,
            BillKind.expense => V1BillPhotosKindRecordIdUrlGetKind.expense,
          },
          recordId: recordId,
        ),
      ),
    );
    return Uri.parse(body.url);
  }

  @override
  Future<void> put(Uri url, List<int> bytes) async {
    final resp = await _guard(
      () => _client.put(
        url,
        headers: {'Content-Type': contentType, 'x-upsert': 'true'},
        body: bytes,
      ),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw PhotoBackupFailedException('upload http ${resp.statusCode}');
    }
  }

  @override
  Future<List<int>> get(Uri url) async {
    final resp = await _guard(() => _client.get(url));
    if (resp.statusCode == 400 || resp.statusCode == 404) {
      throw const PhotoBackupRefusedException('not found');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw PhotoBackupFailedException('download http ${resp.statusCode}');
    }
    return resp.bodyBytes;
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(timeout);
    } on TimeoutException {
      throw const PhotoBackupFailedException('timeout');
    } on SocketException {
      throw const PhotoBackupFailedException('network');
    } on HttpException {
      throw const PhotoBackupFailedException('network');
    } on http.ClientException {
      throw const PhotoBackupFailedException('network');
    }
  }

  static T _check<T>(Response<T> resp) {
    final body = resp.body;
    if (resp.statusCode == 503) throw const PhotoBackupOffException();
    if (const {404, 413, 422}.contains(resp.statusCode)) {
      throw PhotoBackupRefusedException('http ${resp.statusCode}');
    }
    if (!resp.isSuccessful || body == null) {
      throw PhotoBackupFailedException('http ${resp.statusCode}');
    }
    return body;
  }
}

/// Wi-Fi interface names on Android (wlan*, wifi*, swlan*) and iOS (en0..); mobile data
/// shows up as rmnet* / ccmni* / pdp_ip* and is never matched.
bool looksLikeWifi(Iterable<String> interfaceNames) => interfaceNames.any(
  (n) => RegExp(r'^(wlan|swlan|wifi|en\d)').hasMatch(n.toLowerCase()),
);

abstract interface class NetworkCheck {
  /// Whether the phone seems to be on Wi-Fi; false when it cannot tell.
  Future<bool> onWifi();
}

class InterfaceNetworkCheck implements NetworkCheck {
  const InterfaceNetworkCheck();

  @override
  Future<bool> onWifi() async {
    try {
      final list = await NetworkInterface.list();
      return looksLikeWifi([
        for (final i in list)
          if (i.addresses.isNotEmpty) i.name,
      ]);
    } on Object {
      return false;
    }
  }
}

/// "Back up photos on mobile data" (off by default). Per install, never synced.
class PhotoBackupPrefs {
  PhotoBackupPrefs(this._db);

  static const mobileDataKey = 'photo_backup_mobile_data';

  final AppDatabase _db;

  Future<bool> mobileData() async => await _db.readMeta(mobileDataKey) == '1';

  Future<void> setMobileData(bool on) =>
      _db.writeMeta(mobileDataKey, on ? '1' : '0');
}

/// Reads a kept photo and stores a downloaded one, in the app's own photo folder.
abstract interface class PhotoFiles {
  /// The file's bytes, or null when it is gone.
  Future<List<int>?> read(String path);

  /// Writes a downloaded photo for [recordId]; the kept path.
  Future<String> store(String recordId, List<int> bytes);
}

class DevicePhotoFiles implements PhotoFiles {
  /// [folderName] is the kept photos' folder (bill photos use [billPhotoFolder]).
  DevicePhotoFiles({
    Future<Directory> Function()? documents,
    this.folderName = DeviceScoutingPhotos.folder,
  }) : _documents = documents ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documents;
  final String folderName;

  @override
  Future<List<int>?> read(String path) async {
    final file = File(path);
    return await file.exists() ? file.readAsBytes() : null;
  }

  @override
  Future<String> store(String recordId, List<int> bytes) async {
    final dir = Directory(p.join((await _documents()).path, folderName));
    await dir.create(recursive: true);
    final dest = p.join(dir.path, '$recordId.jpg');
    await File(dest).writeAsBytes(bytes, flush: true);
    return dest;
  }
}

/// One kind of record whose bill photo rides the scouting photo backup (Q136).
class BillBackupTarget {
  const BillBackupTarget({
    required this.kind,
    required this.records,
    required this.api,
    required this.files,
  });

  final BillKind kind;
  final BillPhotoRecords records;
  final BillPhotoBackupApi api;

  /// The folder downloaded bill photos are kept in.
  final PhotoFiles files;
}

class ScoutingPhotoBackup {
  ScoutingPhotoBackup({
    required this._repo,
    required this._api,
    required this._files,
    required this._outbox,
    required this._prefs,
    this._network = const InterfaceNetworkCheck(),
    this._clock = systemClock,
    this._bills = const [],
    this._backoff = const Backoff(
      base: Duration(minutes: 1),
      cap: Duration(hours: 6),
    ),
    Random? random,
    void Function(String)? log,
  }) : _random = random ?? Random(),
       _log = log ?? ((_) {});

  final ScoutingRepository _repo;
  final PhotoBackupApi _api;
  final PhotoFiles _files;
  final Outbox _outbox;
  final PhotoBackupPrefs _prefs;
  final NetworkCheck _network;
  final Clock _clock;
  final List<BillBackupTarget> _bills;
  final Backoff _backoff;
  final Random _random;
  final void Function(String) _log;

  bool _off = false;
  final _attempts = <String, int>{};
  final _nextAttempt = <String, DateTime>{};
  final _refused = <String>{};
  Future<int>? _running;

  /// The server said backup is not configured; nothing is tried until the app restarts.
  bool get off => _off;

  /// Uploads every photo that is due; how many were backed up. Concurrent callers share
  /// the run in flight.
  Future<int> uploadPending() =>
      _running ??= _upload().whenComplete(() => _running = null);

  Future<int> _upload() async {
    if (_off) return 0;
    if (!await _network.onWifi() && !await _prefs.mobileData()) return 0;
    var done = 0;
    for (final r in await _repo.photosToBackUp()) {
      if (_off) break;
      if (!_due(r.id)) continue;
      // The server must have the record first: its own write is pushed before the photo.
      if (await _outbox.hasPending(ScoutingRepository.entity, r.id)) continue;
      if (await _backUp(
        r.id,
        r.photoPath!,
        (size) => _api.uploadUrl(r.id, size),
        (key) => _repo.markBackedUp(r.id, key),
      )) {
        done++;
      }
    }
    for (final b in _bills) {
      for (final r in await b.records.billPhotosToBackUp()) {
        if (_off) break;
        final tag = '${b.kind.wire}:${r.id}';
        if (!_due(tag)) continue;
        if (await _outbox.hasPending(b.kind.wire, r.id)) continue;
        if (await _backUp(
          tag,
          r.path,
          (size) => b.api.billUploadUrl(b.kind, r.id, size),
          (key) => b.records.markBillBackedUp(r.id, key),
        )) {
          done++;
        }
      }
    }
    return done;
  }

  bool _due(String id) {
    if (_refused.contains(id)) return false;
    final next = _nextAttempt[id];
    return next == null || !next.isAfter(_clock());
  }

  /// Uploads one photo; [tag] keys its retry state.
  Future<bool> _backUp(
    String tag,
    String path,
    Future<PhotoUploadTicket> Function(int size) ticketFor,
    Future<void> Function(String key) markBackedUp,
  ) async {
    try {
      final bytes = await _files.read(path);
      if (bytes == null) throw const PhotoBackupRefusedException('file gone');
      final ticket = await ticketFor(bytes.length);
      await _api.put(ticket.uploadUrl, bytes);
      await markBackedUp(ticket.photoKey);
      _attempts.remove(tag);
      _nextAttempt.remove(tag);
      return true;
    } on PhotoBackupOffException {
      _off = true;
    } on PhotoBackupRefusedException catch (e) {
      _refused.add(tag);
      _log('photo backup $tag: $e');
    } on PhotoBackupFailedException catch (e) {
      final attempt = _attempts[tag] ?? 0;
      _attempts[tag] = attempt + 1;
      _nextAttempt[tag] = _clock().add(_backoff.delayFor(attempt, _random));
      _log('photo backup $tag: $e');
    }
    return false;
  }

  /// The photo file of [r] on this phone. A backed-up photo from another phone is
  /// downloaded once and kept; null when there is none or it cannot be fetched now.
  Future<String?> localPhoto(ScoutingRecord r) async {
    if (r.photoPath != null) return r.photoPath;
    if (r.photoKey == null) return null;
    return _download(
      () => _api.downloadUrl(r.id),
      (bytes) => _files.store(r.id, bytes),
      (path) => _repo.keepDownloaded(r.id, path),
    );
  }

  /// The bill photo of record [id] of [kind] on this phone, downloaded once when it was
  /// backed up from another phone; null when there is none or it cannot be fetched now.
  Future<String?> localBillPhoto(BillKind kind, String id) async {
    final b = _bills.where((x) => x.kind == kind).firstOrNull;
    final ref = await b?.records.billPhotoOf(id);
    if (b == null || ref == null) return null;
    if (ref.path != null) return ref.path;
    if (ref.key == null) return null;
    return _download(
      () => b.api.billDownloadUrl(kind, id),
      (bytes) => b.files.store(id, bytes),
      (path) => b.records.keepDownloadedBill(id, path),
    );
  }

  Future<String?> _download(
    Future<Uri> Function() url,
    Future<String> Function(List<int> bytes) store,
    Future<void> Function(String path) keep,
  ) async {
    if (_off) return null;
    try {
      final bytes = await _api.get(await url());
      final path = await store(bytes);
      await keep(path);
      return path;
    } on PhotoBackupOffException {
      _off = true;
    } on PhotoBackupRefusedException catch (e) {
      _log('photo download: $e');
    } on PhotoBackupFailedException catch (e) {
      _log('photo download: $e');
    }
    return null;
  }
}
