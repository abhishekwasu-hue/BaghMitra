import 'dart:convert';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:uuid/uuid.dart';

import '../../../api/generated/bagmitra.enums.swagger.dart' as enums;
import '../../../api/generated/bagmitra.swagger.dart';
import '../../../data/local/database.dart';

enum FeedbackKind { problem, suggestion, question }

/// One message the user wrote; kept on the phone until the server has it.
class FeedbackDraft {
  const FeedbackDraft({
    required this.id,
    required this.kind,
    required this.text,
    required this.appVersion,
    required this.device,
    this.screenshotPath,
  });

  factory FeedbackDraft.fromJson(Map<String, Object?> j) => FeedbackDraft(
    id: j['id']! as String,
    kind: FeedbackKind.values.byName(j['kind']! as String),
    text: j['text']! as String,
    appVersion: j['app_version']! as String,
    device: j['device']! as String,
    screenshotPath: j['screenshot'] as String?,
  );

  final String id;
  final FeedbackKind kind;
  final String text;
  final String appVersion;
  final String device;
  final String? screenshotPath;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'text': text,
    'app_version': appVersion,
    'device': device,
    'screenshot': screenshotPath,
  };
}

/// The server's answer to one message (audit M2).
enum SendResult {
  /// Stored (a retry of the same id is answered the same way).
  sent,

  /// Offline, timeout, 408, 429 or 5xx: keep it and try again later.
  retryLater,

  /// Any other 4xx: this message will never be accepted; drop it, send the next.
  refused,
}

SendResult sendResultOf(int status) {
  if (status >= 200 && status < 300) return SendResult.sent;
  if (status >= 400 && status < 500 && status != 408 && status != 429) {
    return SendResult.refused;
  }
  return SendResult.retryLater;
}

/// Where a message goes: `POST /v1/feedback` and the optional screenshot.
abstract interface class FeedbackServer {
  Future<SendResult> send(FeedbackDraft draft);
  Future<bool> sendScreenshot(String id, List<int> jpeg);
}

class ApiFeedbackServer implements FeedbackServer {
  const ApiFeedbackServer(this._api);
  final Bagmitra _api;

  @override
  Future<SendResult> send(FeedbackDraft d) async {
    try {
      final res = await _api.v1FeedbackPost(
        body: FeedbackIn(
          clientId: d.id,
          kind: enums.FeedbackInKind.values.byName(d.kind.name),
          text: d.text,
          appVersion: d.appVersion,
          device: d.device,
        ),
      );
      return sendResultOf(res.statusCode);
    } on Object {
      return SendResult.retryLater;
    }
  }

  @override
  Future<bool> sendScreenshot(String id, List<int> jpeg) async {
    try {
      final res = await _api.client.send<Object, Object>(
        Request(
          'PUT',
          Uri.parse('/v1/feedback/$id/screenshot'),
          _api.client.baseUrl,
          body: jpeg,
          headers: {'Content-Type': 'image/jpeg'},
        ),
      );
      return res.isSuccessful;
    } on Object {
      return false;
    }
  }
}

/// Feedback written offline waits here and goes when the phone is online (on send, on the
/// next app start). The text always goes; a screenshot goes when its file is still there
/// and photo storage is set up on the server (a refusal never blocks the text).
class FeedbackOutbox {
  FeedbackOutbox(this._db, this._server, {String Function()? newId})
    : _newId = newId ?? const Uuid().v4;

  static const metaKey = 'feedback.outbox';
  final AppDatabase _db;
  final FeedbackServer _server;
  final String Function() _newId;

  Future<List<FeedbackDraft>> pending() async {
    final raw = await _db.readMeta(metaKey);
    if (raw == null) return [];
    try {
      return [
        for (final j in jsonDecode(raw) as List)
          FeedbackDraft.fromJson((j as Map).cast<String, Object?>()),
      ];
    } on Object {
      return []; // an unreadable queue is dropped, never a crash
    }
  }

  Future<void> _save(List<FeedbackDraft> list) =>
      _db.writeMeta(metaKey, jsonEncode([for (final d in list) d.toJson()]));

  /// Queues the message and tries to send everything; true when nothing is left waiting.
  Future<bool> add({
    required FeedbackKind kind,
    required String text,
    required String appVersion,
    required String device,
    String? screenshotPath,
  }) async {
    final list = await pending()
      ..add(
        FeedbackDraft(
          id: _newId(),
          kind: kind,
          text: text.trim(),
          appVersion: appVersion,
          device: device,
          screenshotPath: screenshotPath,
        ),
      );
    await _save(list);
    return flush();
  }

  /// Sends what waits, oldest first. Stops at the first retry-later answer (offline, 5xx) and
  /// keeps the rest; a refused message is removed and the next one is sent (audit M2).
  Future<bool> flush() async {
    final list = await pending();
    while (list.isNotEmpty) {
      final d = list.first;
      final result = await _server.send(d);
      if (result == SendResult.retryLater) break;
      if (result == SendResult.sent && d.screenshotPath != null) {
        final path = d.screenshotPath!;
        final file = File(path);
        if (file.existsSync()) {
          await _server.sendScreenshot(d.id, await file.readAsBytes());
        }
      }
      list.removeAt(0);
      await _save(list);
    }
    return list.isEmpty;
  }
}
