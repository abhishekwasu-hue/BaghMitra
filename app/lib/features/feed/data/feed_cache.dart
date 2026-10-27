import 'dart:convert';

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
/// the tab works offline. The whole feed is cached and the chips filter it on the phone, so
/// every filter works offline too. Refreshing is best effort: a failure keeps the cache.
class FeedCache {
  FeedCache(this._db, {required this._repository, required this._clock});

  static const maxItems = 50;

  final AppDatabase _db;
  final FeedRepository _repository;
  final DateTime Function() _clock;

  static String keyFor(String lang) => 'feed.$lang';

  Future<CachedFeed?> load(String lang) async {
    final raw = await _db.readMeta(keyFor(lang));
    if (raw == null) return null;
    final j = (jsonDecode(raw) as Map).cast<String, Object?>();
    return CachedFeed(
      FeedPage.fromJson((j['page']! as Map).cast<String, Object?>()),
      DateTime.parse(j['saved_at']! as String),
    );
  }

  /// Returns true when a fresh answer was stored.
  Future<bool> refresh(String lang) async {
    final FeedPage page;
    try {
      page = await _repository.fetch(lang: lang);
    } on Exception {
      return false;
    }
    final items = filterFeed(page.items, null).take(maxItems).toList();
    await _db.writeMeta(
      keyFor(lang),
      jsonEncode({
        'saved_at': _clock().toUtc().toIso8601String(),
        'page': FeedPage(items: items, footer: page.footer).toJson(),
      }),
    );
    return true;
  }
}
