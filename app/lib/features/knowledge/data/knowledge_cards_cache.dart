import 'dart:convert';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../data/local/database.dart';

/// The grower knowledge cards with the time the phone saved them.
class CachedKnowledgeCards {
  const CachedKnowledgeCards(this.cards, this.savedAt);

  final List<GrowerCardOut> cards;
  final DateTime savedAt;
}

/// Knowledge cards (general information, owner decision Q57), cached on the phone so they
/// read offline. Refreshing is best effort: a failure keeps the cache.
class KnowledgeCardsCache {
  KnowledgeCardsCache(this._db, {required this._api, required this._clock});

  final AppDatabase _db;
  final Bagmitra _api;
  final DateTime Function() _clock;

  static const key = 'reference.knowledge_cards';

  Future<CachedKnowledgeCards?> load() async {
    final raw = await _db.readMeta(key);
    if (raw == null) return null;
    final j = (jsonDecode(raw) as Map).cast<String, Object?>();
    final res = GrowerCardsResponse.fromJson(
      (j['response']! as Map).cast<String, dynamic>(),
    );
    return CachedKnowledgeCards(
      res.cards,
      DateTime.parse(j['saved_at']! as String),
    );
  }

  /// Returns true when a fresh answer was stored.
  Future<bool> refresh() async {
    try {
      final res = await _api.v1KnowledgeCardsGet();
      final body = res.body;
      if (!res.isSuccessful || body == null) return false;
      await _db.writeMeta(
        key,
        jsonEncode({
          'saved_at': _clock().toUtc().toIso8601String(),
          'response': body.toJson(),
        }),
      );
      return true;
    } on Exception {
      return false;
    }
  }
}
