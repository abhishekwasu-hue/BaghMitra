import 'dart:convert';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../core/net_failure.dart';
import '../domain/feed_article.dart';
import '../domain/feed_check.dart';
import '../domain/feed_item.dart';
import '../domain/feed_preferences.dart';

/// What the grower did with an item, sent to `POST /v1/feed/{id}/<action>`.
enum FeedReceiptAction {
  seen('seen'),
  dismiss('dismiss'),
  remind('remind');

  const FeedReceiptAction(this.value);

  final String value;

  static FeedReceiptAction? parse(Object? v) =>
      values.where((a) => a.value == v).firstOrNull;
}

/// Where the Sarkari Sandesh feed comes from, and where the grower's receipts, alert
/// settings and message checks go. Every failure is a [FeedUnavailableException].
abstract interface class FeedRepository {
  Future<FeedPage> fetch({required String lang, FeedFilter? filter});

  /// One news topic with every report, oldest first (owner Q139).
  Future<FeedThreadPage> fetchThread({
    required String lang,
    required String threadId,
  });

  /// Records seen / dismiss / remind for one item on the server.
  Future<void> sendReceipt(String itemId, FeedReceiptAction action);

  Future<FeedPreferences> loadPreferences();

  /// Returns the settings as the server stored them.
  Future<FeedPreferences> savePreferences(FeedPreferences prefs);

  /// Looks for official items matching a pasted message. The text is sent once and
  /// never stored on the phone. [lang] is only used by the demo answer.
  Future<FeedCheckResult> check(String text, {String lang = 'en'});
}

class FeedUnavailableException implements Exception {
  const FeedUnavailableException(
    this.reason, {
    this.failure = NetFailure.server,
  });

  final String reason;

  /// Offline, server or signed out, for the words the grower sees.
  final NetFailure failure;

  @override
  String toString() => 'FeedUnavailableException: $reason';
}

/// The feed endpoints through the app's Chopper client, so the base URL and the signed-in
/// grower's bearer token are the same as every generated call. `/v1/feed/check` is not in
/// the generated client yet, so [check] calls it by hand.
class HttpFeedRepository implements FeedRepository {
  const HttpFeedRepository(this._api);

  final Bagmitra _api;

  static const path = '/v1/feed';
  static const checkPath = '/v1/feed/check';

  /// Runs one call, turning any transport or decoding failure into
  /// [FeedUnavailableException].
  static Future<T> _guard<T>(String what, Future<T> Function() call) async {
    try {
      return await call();
    } on FeedUnavailableException {
      rethrow;
    } on Object catch (e) {
      throw FeedUnavailableException(
        '$what: $e',
        failure: netFailureForError(e),
      );
    }
  }

  /// Every field of the contract item the app uses. The level and the article go through
  /// the same parsing as the phone cache ([FeedItem.fromJson]), so an unknown level or a
  /// broken article reads as none on both paths.
  static FeedItem _item(FeedItemOut o) => FeedItem(
    id: o.id,
    type: o.type,
    trust: o.trust.value ?? 'news',
    title: o.title,
    summary: o.summary ?? '',
    department: o.department,
    level: FeedItem.levelOf(o.level),
    grNumber: o.grNumber,
    publishedAt: o.publishedAt,
    url: o.url,
    deadline: o.deadline,
    validTo: o.validTo,
    replacedBy: o.replacedBy,
    mayBeEligibleBecause: o.mayBeEligibleBecause,
    seen: o.seen ?? false,
    article: FeedArticle.tryParse(o.article?.toJson()),
    threadId: o.threadId,
  );

  static FeedThread _thread(FeedThreadOut o) => FeedThread(
    id: o.id,
    title: o.title,
    summary: o.summary,
    latestAt: o.latestAt,
    itemCount: o.itemCount,
    unseenCount: o.unseenCount,
  );

  @override
  Future<FeedThreadPage> fetchThread({
    required String lang,
    required String threadId,
  }) async {
    final res = await _guard(
      'bad body',
      () => _api.v1FeedThreadsThreadIdGet(
        threadId: threadId,
        lang: V1FeedThreadsThreadIdGetLang.values
            .where((l) => l.value == lang)
            .firstOrNull,
      ),
    );
    final body = res.body;
    if (!res.isSuccessful || body == null) {
      throw FeedUnavailableException(
        'http ${res.statusCode}',
        failure: netFailureForStatus(res.statusCode),
      );
    }
    return FeedThreadPage(
      thread: _thread(body.thread),
      items: [for (final o in body.items) _item(o)],
      footer: body.footer,
    );
  }

  @override
  Future<FeedPage> fetch({required String lang, FeedFilter? filter}) async {
    final res = await _guard(
      'bad body',
      () => _api.v1FeedGet(
        lang: V1FeedGetLang.values.where((l) => l.value == lang).firstOrNull,
        type: filter?.value,
      ),
    );
    final body = res.body;
    if (!res.isSuccessful || body == null) {
      throw FeedUnavailableException(
        'http ${res.statusCode}',
        failure: netFailureForStatus(res.statusCode),
      );
    }
    return FeedPage(
      items: [for (final o in body.items) _item(o)],
      footer: body.footer,
      threads: {
        for (final t in body.threads ?? const <FeedThreadOut>[])
          t.id: _thread(t),
      },
    );
  }

  @override
  Future<void> sendReceipt(String itemId, FeedReceiptAction action) async {
    final res = await _guard(
      'receipt',
      () => switch (action) {
        FeedReceiptAction.seen => _api.v1FeedItemIdSeenPost(itemId: itemId),
        FeedReceiptAction.dismiss => _api.v1FeedItemIdDismissPost(
          itemId: itemId,
        ),
        FeedReceiptAction.remind => _api.v1FeedItemIdRemindPost(itemId: itemId),
      },
    );
    if (res.isSuccessful || _gone(res.statusCode)) return;
    throw FeedUnavailableException(
      'http ${res.statusCode}',
      failure: netFailureForStatus(res.statusCode),
    );
  }

  /// A client error that a retry cannot fix (the item is gone, the body is refused): the
  /// receipt is dropped rather than retried forever. Sign-in and rate limits are retried.
  static bool _gone(int status) =>
      status >= 400 &&
      status < 500 &&
      status != 401 &&
      status != 408 &&
      status != 429;

  static FeedPreferences _prefs(FeedPreferencesBody b) => FeedPreferences(
    quietStart: b.quietStart,
    quietEnd: b.quietEnd,
    weeklyCap: b.weeklyCap,
    optedOut: {
      for (final c in b.optedOut ?? const <FeedPreferencesBodyOptedOut>[])
        ?c.value,
    },
    digestWeekly: b.digestWeekly,
  );

  @override
  Future<FeedPreferences> loadPreferences() async {
    final res = await _guard('prefs', _api.v1MeFeedPreferencesGet);
    final body = res.body;
    if (!res.isSuccessful || body == null) {
      throw FeedUnavailableException(
        'http ${res.statusCode}',
        failure: netFailureForStatus(res.statusCode),
      );
    }
    return _prefs(body);
  }

  @override
  Future<FeedPreferences> savePreferences(FeedPreferences prefs) async {
    final res = await _guard(
      'prefs',
      () => _api.v1MeFeedPreferencesPut(
        body: FeedPreferencesBody(
          quietStart: prefs.quietStart,
          quietEnd: prefs.quietEnd,
          weeklyCap: prefs.weeklyCap,
          digestWeekly: prefs.digestWeekly,
          optedOut: [
            for (final c in FeedPreferencesBodyOptedOut.values)
              if (prefs.optedOut.contains(c.value)) c,
          ],
        ),
      ),
    );
    final body = res.body;
    if (!res.isSuccessful || body == null) {
      throw FeedUnavailableException(
        'http ${res.statusCode}',
        failure: netFailureForStatus(res.statusCode),
      );
    }
    return _prefs(body);
  }

  @override
  Future<FeedCheckResult> check(String text, {String lang = 'en'}) async {
    final res = await _guard(
      'check',
      () => _api.client.post<String, String>(
        Uri(path: checkPath),
        body: {'text': text},
      ),
    );
    final body = res.bodyString;
    if (!res.isSuccessful || body.isEmpty) {
      throw FeedUnavailableException(
        'http ${res.statusCode}',
        failure: netFailureForStatus(res.statusCode),
      );
    }
    try {
      return FeedCheckResult.fromJson(
        (jsonDecode(body) as Map).cast<String, Object?>(),
      );
    } on Object catch (e) {
      throw FeedUnavailableException('bad body: $e');
    }
  }
}
