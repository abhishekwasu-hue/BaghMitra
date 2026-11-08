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
    this.textSent = false,
  });

  factory FeedbackDraft.fromJson(Map<String, Object?> j) => FeedbackDraft(
    id: j['id']! as String,
    kind: FeedbackKind.values.byName(j['kind']! as String),
    text: j['text']! as String,
    appVersion: j['app_version']! as String,
    device: j['device']! as String,
    screenshotPath: j['screenshot'] as String?,
    textSent: j['text_sent'] == true,
  );

  final String id;
  final FeedbackKind kind;
  final String text;
  final String appVersion;
  final String device;
  final String? screenshotPath;

  /// The server has the text; only the screenshot still waits (audit L4).
  final bool textSent;

  FeedbackDraft withTextSent() => FeedbackDraft(
    id: id,
    kind: kind,
    text: text,
    appVersion: appVersion,
    device: device,
    screenshotPath: screenshotPath,
    textSent: true,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'text': text,
    'app_version': appVersion,
    'device': device,
    'screenshot': screenshotPath,
    'text_sent': textSent,
  };
}

/// The server's answer to one message (audit M2).
enum SendResult {
  /// Stored (a retry of the same id is answered the same way).
  sent,

  /// Offline, timeout, 401, 408, 429 or 5xx: keep it and try again later.
  retryLater,

  /// Any other 4xx: this message will never be accepted; drop it, send the next.
  refused,
}

SendResult sendResultOf(int status) {
  if (status >= 200 && status < 300) return SendResult.sent;
  // 401 waits too (owner Q123): a phone offline longer than the token's life gets 401 on its
  // first send, before the session is refreshed.
  const waits = {401, 408, 429};
  if (status >= 400 && status < 500 && !waits.contains(status)) {
    return SendResult.refused;
  }
  return SendResult.retryLater;
}

/// Where a message goes: `POST /v1/feedback` and the optional screenshot.
abstract interface class FeedbackServer {
  Future<SendResult> send(FeedbackDraft draft);
  Future<SendResult> sendScreenshot(String id, List<int> jpeg);
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
  Future<SendResult> sendScreenshot(String id, List<int> jpeg) async {
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
      return sendResultOf(res.statusCode);
    } on Object {
      return SendResult.retryLater;
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

  /// Sends what waits, oldest first. Stops at the first text that must wait (offline, 5xx)
  /// and keeps the rest; a refused message is removed and the next one is sent (audit M2).
  /// A screenshot that must wait stays queued with its text marked sent, and the next
  /// message still goes; a refused or missing screenshot is dropped (audit L4).
  Future<bool> flush() async {
    final list = await pending();
    var i = 0;
    while (i < list.length) {
      var d = list[i];
      if (!d.textSent) {
        final result = await _server.send(d);
        if (result == SendResult.retryLater) break;
        if (result == SendResult.refused) {
          list.removeAt(i);
          await _save(list);
          continue;
        }
        d = list[i] = d.withTextSent();
        await _save(list);
      }
      if (d.screenshotPath case final path?) {
        final file = File(path);
        if (file.existsSync()) {
          final shot = await _server.sendScreenshot(
            d.id,
            await file.readAsBytes(),
          );
          if (shot == SendResult.retryLater) {
            i++; // keep it; the next message may still go
            continue;
          }
        }
      }
      list.removeAt(i);
      await _save(list);
    }
    return list.isEmpty;
  }
}
