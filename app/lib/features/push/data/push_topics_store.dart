import 'dart:convert';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../data/local/database.dart';
import '../domain/push_topics.dart';

/// The API's switch endpoints (`GET` / `PUT /v1/me/push-topics`).
abstract interface class PushTopicsApi {
  Future<PushTopics> load();
  Future<PushTopics> save(PushTopics topics);
}

class PushTopicsUnavailable implements Exception {
  const PushTopicsUnavailable(this.statusCode);
  final int statusCode;

  @override
  String toString() => 'PushTopicsUnavailable($statusCode)';
}

class HttpPushTopicsApi implements PushTopicsApi {
  const HttpPushTopicsApi(this._api);
  final Bagmitra _api;

  static PushTopics _from(PushTopicsBody b) => PushTopics(
    articles: b.articles,
    market: b.market,
    weather: b.weatherChange,
  );

  @override
  Future<PushTopics> load() async {
    final res = await _api.v1MePushTopicsGet();
    final body = res.body;
    if (!res.isSuccessful || body == null) {
      throw PushTopicsUnavailable(res.statusCode);
    }
    return _from(body);
  }

  @override
  Future<PushTopics> save(PushTopics t) async {
    final res = await _api.v1MePushTopicsPut(
      body: PushTopicsBody(
        articles: t.articles,
        market: t.market,
        weatherChange: t.weather,
      ),
    );
    final body = res.body;
    if (!res.isSuccessful || body == null) {
      throw PushTopicsUnavailable(res.statusCode);
    }
    return _from(body);
  }
}

/// The switches on the phone first, so Settings shows and changes them offline: a change is
/// written to the phone at once and marked pending, then sent; while the send fails it stays
/// pending and goes with the next [sync] (Settings opened, app started signed in). With
/// nothing pending, [sync] takes the server's copy (it may have been changed on another
/// phone). The copy belongs to one account: another account's copy is ignored. Without an
/// API (demo mode) the switches live on the phone only.
class PushTopicsStore {
  PushTopicsStore(this._db, {required this.userId, this._api});

  static const key = 'push.topics';

  final AppDatabase _db;
  final PushTopicsApi? _api;
  final String? userId;

  Future<({PushTopics topics, bool pending})> _read() async {
    final raw = await _db.readMeta(key);
    if (raw == null) return (topics: PushTopics.defaults, pending: false);
    try {
      final j = (jsonDecode(raw) as Map).cast<String, Object?>();
      if (j['user'] != userId) {
        return (topics: PushTopics.defaults, pending: false);
      }
      return (topics: PushTopics.fromJson(j), pending: j['pending'] == true);
    } on FormatException {
      return (topics: PushTopics.defaults, pending: false);
    }
  }

  Future<void> _write(PushTopics t, {required bool pending}) => _db.writeMeta(
    key,
    jsonEncode({...t.toJson(), 'user': userId, 'pending': pending}),
  );

  /// What the phone holds now (defaults until anything was saved).
  Future<PushTopics> local() async => (await _read()).topics;

  /// Whether a change still waits to reach the server.
  Future<bool> pending() async => (await _read()).pending;

  /// Switches one topic: saved on the phone first, then sent (kept pending when offline).
  Future<PushTopics> set(PushTopic topic, {required bool on}) async {
    final next = (await _read()).topics.withTopic(topic, on: on);
    await _write(next, pending: _api != null);
    await sync();
    return local();
  }

  /// Sends a pending change, or takes the server's copy; never throws (offline keeps the
  /// phone's copy). Returns what the phone holds afterwards.
  Future<PushTopics> sync() async {
    final api = _api;
    if (api == null || userId == null) return local();
    final now = await _read();
    try {
      final stored = now.pending
          ? await api.save(now.topics)
          : await api.load();
      // A switch moved while the call was out: keep it pending for the next sync.
      final latest = await _read();
      if (latest.topics == now.topics) {
        await _write(stored, pending: false);
      }
    } on Object {
      // Offline or the server refused: the phone's copy stays as it is.
    }
    return local();
  }
}
