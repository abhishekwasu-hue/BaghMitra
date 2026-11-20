import 'dart:convert';

import '../../../core/net_failure.dart';
import '../../../data/local/database.dart';
import '../domain/feed_item.dart';
import 'feed_repository.dart';

/// The last feed answer for one language, with the time the phone saved it.
class CachedFeed {
  const CachedFeed(this.page, this.savedAt);

  final FeedPage page;
  final DateTime savedAt;
}

/// The Sarkari Sandesh feed, cached on the phone (newest [maxItems] items per language) so
/// the tab works offline; the chips filter it on the phone. Each chip's own list (Q165: a
/// ज्ञान लेख older than the newest [maxItems] items of every kind) is cached under its own
/// key once it was opened. Refreshing is best effort: a failure keeps the cache.
class FeedCache {
  FeedCache(this._db, {required this._repository, required this._clock});

  static const maxItems = 50;

  final AppDatabase _db;
  final FeedRepository _repository;
  final DateTime Function() _clock;

  static String keyFor(String lang, [FeedFilter? filter]) =>
      filter == null ? 'feed.$lang' : 'feed.$lang.${filter.value}';

  Future<CachedFeed?> load(String lang, {FeedFilter? filter}) async {
    final raw = await _db.readMeta(keyFor(lang, filter));
    if (raw == null) return null;
    final j = (jsonDecode(raw) as Map).cast<String, Object?>();
    return CachedFeed(
      FeedPage.fromJson((j['page']! as Map).cast<String, Object?>()),
      DateTime.parse(j['saved_at']! as String),
    );
  }

  /// Returns true when a fresh answer was stored.
  Future<bool> refresh(String lang) async =>
      await refreshOrFailure(lang) == null;

  /// Stores a fresh answer and returns null, or says why none came; the cache stays as is.
  Future<NetFailure?> refreshOrFailure(
    String lang, {
    FeedFilter? filter,
  }) async {
    final FeedPage page;
    try {
      page = await _repository.fetch(lang: lang, filter: filter);
    } on FeedUnavailableException catch (e) {
      return e.failure;
    } on Object catch (e) {
      return netFailureForError(e);
    }
    final items = filterFeed(page.items, null).take(maxItems).toList();
    final kept = {for (final i in items) ?i.threadId};
    // A longer answer than kept: the next page starts after the last kept item.
    final next = items.length < page.items.length
        ? FeedCursor(items.last.publishedAt, items.last.id)
        : page.next;
    await _db.writeMeta(
      keyFor(lang, filter),
      jsonEncode({
        'saved_at': _clock().toUtc().toIso8601String(),
        'page': FeedPage(
          items: items,
          footer: page.footer,
          threads: {
            for (final t in page.threads.values)
              if (kept.contains(t.id)) t.id: t,
          },
          next: next,
        ).toJson(),
      }),
    );
    return null;
  }

  /// One opened news topic (owner Q139), cached per language and topic so it opens offline.
  static String threadKeyFor(String lang, String threadId) =>
      'feed.thread.$lang.$threadId';

  Future<CachedFeedThread?> loadThread(String lang, String threadId) async {
    final raw = await _db.readMeta(threadKeyFor(lang, threadId));
    if (raw == null) return null;
    final j = (jsonDecode(raw) as Map).cast<String, Object?>();
    return CachedFeedThread(
      FeedThreadPage.fromJson((j['page']! as Map).cast<String, Object?>()),
      DateTime.parse(j['saved_at']! as String),
    );
  }

  /// Stores a fresh answer for the topic and returns null, or says why none came.
  Future<NetFailure?> refreshThreadOrFailure(
    String lang,
    String threadId,
  ) async {
    final FeedThreadPage page;
    try {
      page = await _repository.fetchThread(lang: lang, threadId: threadId);
    } on FeedUnavailableException catch (e) {
      return e.failure;
    } on Object catch (e) {
      return netFailureForError(e);
    }
    await _db.writeMeta(
      threadKeyFor(lang, threadId),
      jsonEncode({
        'saved_at': _clock().toUtc().toIso8601String(),
        'page': page.toJson(),
      }),
    );
    return null;
  }
}

/// The last answer for one news topic, with the time the phone saved it.
class CachedFeedThread {
  const CachedFeedThread(this.page, this.savedAt);

  final FeedThreadPage page;
  final DateTime savedAt;
}
