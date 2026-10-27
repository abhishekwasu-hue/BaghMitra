import 'dart:async';
import 'dart:convert';

import '../../../data/local/database.dart';
import 'feed_repository.dart';

/// What the phone remembers about the grower's own feed actions.
class FeedReceiptState {
  const FeedReceiptState({
    this.seen = const {},
    this.dismissed = const {},
    this.pending = const [],
  });

  factory FeedReceiptState.fromJson(Map<String, Object?> j) => FeedReceiptState(
    seen: {for (final s in (j['seen'] as List?) ?? const []) s as String},
    dismissed: {
      for (final s in (j['dismissed'] as List?) ?? const []) s as String,
    },
    pending: [
      for (final p in (j['pending'] as List?) ?? const [])
        if (p case {'id': final String id, 'action': final Object? a})
          if (FeedReceiptAction.parse(a) case final action?) (id, action),
    ],
  );

  /// Items opened on this phone.
  final Set<String> seen;

  /// Items the grower hid from the list.
  final Set<String> dismissed;

  /// Receipts not yet accepted by the server, oldest first.
  final List<(String, FeedReceiptAction)> pending;

  Map<String, Object?> toJson() => {
    'seen': [...seen],
    'dismissed': [...dismissed],
    'pending': [
      for (final (id, action) in pending) {'id': id, 'action': action.value},
    ],
  };
}

/// Seen / dismiss / remind receipts: applied on the phone at once (so the dot and the
/// hidden item work offline), queued in the local meta table, and sent to the server now
/// or, when offline, the next time the feed opens. Sending stops at the first failure and
/// keeps the rest for later.
class FeedReceipts {
  FeedReceipts(this._db, {required this._repository});

  static const key = 'feed.receipts';

  /// How many seen / dismissed ids are kept (the feed cache holds far fewer items).
  static const maxIds = 200;

  final AppDatabase _db;
  final FeedRepository _repository;
  Future<void> _tail = Future.value();

  /// Runs [job] after every earlier job, so reads and writes of the queue never interleave.
  Future<T> _serial<T>(Future<T> Function() job) {
    final next = _tail.then((_) => job());
    _tail = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<FeedReceiptState> load() async {
    final raw = await _db.readMeta(key);
    if (raw == null) return const FeedReceiptState();
    return FeedReceiptState.fromJson(
      (jsonDecode(raw) as Map).cast<String, Object?>(),
    );
  }

  Future<void> _store(FeedReceiptState s) => _db.writeMeta(
    key,
    jsonEncode(
      FeedReceiptState(
        seen: _newest(s.seen),
        dismissed: _newest(s.dismissed),
        pending: s.pending,
      ).toJson(),
    ),
  );

  static Set<String> _newest(Set<String> ids) =>
      ids.length <= maxIds ? ids : ids.skip(ids.length - maxIds).toSet();

  /// Applies [action] to [itemId] on the phone and queues it for the server, then tries
  /// to send everything queued. A second "seen" for the same item is not queued again.
  Future<void> record(String itemId, FeedReceiptAction action) async {
    await _serial(() async {
      final s = await load();
      if (action == FeedReceiptAction.seen && s.seen.contains(itemId)) return;
      final queued = s.pending.any((p) => p == (itemId, action));
      await _store(
        FeedReceiptState(
          seen: action == FeedReceiptAction.seen ? {...s.seen, itemId} : s.seen,
          dismissed: action == FeedReceiptAction.dismiss
              ? {...s.dismissed, itemId}
              : s.dismissed,
          pending: queued ? s.pending : [...s.pending, (itemId, action)],
        ),
      );
    });
    await flush();
  }

  /// Sends queued receipts in order; returns how many the server took.
  Future<int> flush() => _serial(() async {
    final s = await load();
    var sent = 0;
    for (final (id, action) in s.pending) {
      try {
        await _repository.sendReceipt(id, action);
      } on Exception {
        break;
      }
      sent++;
    }
    if (sent > 0) {
      await _store(
        FeedReceiptState(
          seen: s.seen,
          dismissed: s.dismissed,
          pending: s.pending.sublist(sent),
        ),
      );
    }
    return sent;
  });
}
