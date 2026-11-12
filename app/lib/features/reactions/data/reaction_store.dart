import 'dart:async';
import 'dart:convert';

import '../../../data/local/database.dart';
import '../../feedback/data/feedback_outbox.dart' show SendResult;
import '../domain/reaction.dart';
import 'reaction_server.dart';

/// The phone's copy of the reader's reactions (Q146): the server's last counts per target,
/// and the outbox of choices not yet sent. A choice waits under its target (only the latest
/// tap per target is kept, `null` meaning "removed") and goes oldest target first.
class ReactionState {
  const ReactionState({this.server = const {}, this.pending = const {}});

  factory ReactionState.fromJson(Map<String, Object?> j) => ReactionState(
    server: {
      for (final MapEntry(:key, :value)
          in ((j['server'] as Map?) ?? const {}).entries)
        if (value is Map)
          key as String: ReactionSummary.fromJson(
            value.cast<String, Object?>(),
          ),
    },
    pending: {
      for (final p in (j['pending'] as List?) ?? const [])
        if (p case {'target': final String target})
          target: Reaction.parse(p['reaction']),
    },
  );

  final Map<String, ReactionSummary> server;

  /// Insertion-ordered: the oldest waiting target first.
  final Map<String, Reaction?> pending;

  ReactionView view(String target) => ReactionView.of(
    server[target],
    hasLocal: pending.containsKey(target),
    local: pending[target],
  );

  Map<String, Object?> toJson() => {
    'server': {
      for (final MapEntry(:key, :value) in server.entries) key: value.toJson(),
    },
    'pending': [
      for (final MapEntry(:key, :value) in pending.entries)
        {'target': key, 'reaction': value?.value},
    ],
  };
}

/// Reactions: shown on the phone at once, queued in the local meta table, and sent now or,
/// when offline, the next time the feed or a reaction bar opens (or the app starts). Sending
/// stops at the first target that must wait and keeps the rest; a refused one is dropped.
class ReactionStore {
  ReactionStore(this._db, this._server);

  static const key = 'feed.reactions';

  /// Server copies kept (newest written last); the outbox is never trimmed.
  static const maxTargets = 300;

  final AppDatabase _db;
  final ReactionServer _server;
  Future<void> _tail = Future.value();

  Future<T> _serial<T>(Future<T> Function() job) {
    final next = _tail.then((_) => job());
    _tail = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<ReactionState> load() async {
    final raw = await _db.readMeta(key);
    if (raw == null) return const ReactionState();
    try {
      return ReactionState.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } on Object {
      return const ReactionState(); // an unreadable copy is dropped, never a crash
    }
  }

  Future<void> _store(ReactionState s) {
    final server = s.server.length <= maxTargets
        ? s.server
        : Map.fromEntries(s.server.entries.skip(s.server.length - maxTargets));
    return _db.writeMeta(
      key,
      jsonEncode(ReactionState(server: server, pending: s.pending).toJson()),
    );
  }

  /// The reader tapped [reaction] on [target]: the same one again removes it, another one
  /// replaces it. Saves the choice in the outbox (nothing is sent yet) and returns what
  /// the bar shows now.
  Future<ReactionView> choose(String target, Reaction reaction) =>
      _serial(() async {
        final s = await load();
        final current = s.view(target).mine;
        final next = current == reaction ? null : reaction;
        final pending = Map<String, Reaction?>.of(s.pending)..remove(target);
        pending[target] = next;
        final stored = ReactionState(server: s.server, pending: pending);
        await _store(stored);
        return stored.view(target);
      });

  /// [choose], then tries to send everything waiting; returns the view after that attempt
  /// ([ReactionView.pending] true when it still waits).
  Future<ReactionView> tap(String target, Reaction reaction) async {
    await choose(target, reaction);
    await flush();
    return (await load()).view(target);
  }

  /// Sends what waits, oldest first; returns how many the server took or refused.
  Future<int> flush() => _serial(() async {
    var s = await load();
    var done = 0;
    for (final MapEntry(key: target, value: reaction)
        in s.pending.entries.toList()) {
      final sent = await _server.send(target, reaction);
      if (sent.result == SendResult.retryLater) break;
      final pending = Map<String, Reaction?>.of(s.pending)..remove(target);
      final server = Map<String, ReactionSummary>.of(s.server)..remove(target);
      if (sent.summary case final summary?) server[target] = summary;
      s = ReactionState(server: server, pending: pending);
      await _store(s);
      done++;
    }
    return done;
  });

  /// Fetches the counts of [targets] (sends waiting choices first). Offline the saved copy
  /// stays; a waiting choice is never overwritten by the server's older view.
  Future<void> refresh(List<String> targets) async {
    if (targets.isEmpty) return;
    await flush();
    final fresh = await _server.fetch(targets);
    await _serial(() async {
      final s = await load();
      final server = Map<String, ReactionSummary>.of(s.server);
      for (final MapEntry(:key, :value) in fresh.entries) {
        server
          ..remove(key)
          ..[key] = value;
      }
      await _store(ReactionState(server: server, pending: s.pending));
    });
  }
}
