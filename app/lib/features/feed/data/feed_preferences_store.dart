import 'dart:convert';

import '../../../data/local/database.dart';
import '../domain/feed_preferences.dart';
import 'feed_repository.dart';

/// The alert settings as the screen opens them: fresh from the server ([online]), or the
/// last saved copy on the phone (the server defaults if there is none) when offline.
class LoadedFeedPreferences {
  const LoadedFeedPreferences(this.prefs, {required this.online});

  final FeedPreferences prefs;
  final bool online;
}

/// Alert settings with a phone copy of the last values the server confirmed. Saving needs
/// the network: offline the screen shows the copy and does not offer to save.
class FeedPreferencesStore {
  FeedPreferencesStore(this._db, {required this._repository});

  static const key = 'feed.prefs';

  final AppDatabase _db;
  final FeedRepository _repository;

  Future<FeedPreferences?> _cached() async {
    final raw = await _db.readMeta(key);
    if (raw == null) return null;
    return FeedPreferences.fromJson(
      (jsonDecode(raw) as Map).cast<String, Object?>(),
    );
  }

  Future<void> _keep(FeedPreferences p) =>
      _db.writeMeta(key, jsonEncode(p.toJson()));

  Future<LoadedFeedPreferences> load() async {
    try {
      final fresh = await _repository.loadPreferences();
      await _keep(fresh);
      return LoadedFeedPreferences(fresh, online: true);
    } on FeedUnavailableException {
      return LoadedFeedPreferences(
        await _cached() ?? FeedPreferences.defaults,
        online: false,
      );
    }
  }

  /// Throws [FeedUnavailableException] when the server did not take it.
  Future<FeedPreferences> save(FeedPreferences prefs) async {
    final stored = await _repository.savePreferences(prefs);
    await _keep(stored);
    return stored;
  }
}
