import '../../../api/generated/bagmitra.enums.swagger.dart' as enums;
import '../../../api/generated/bagmitra.swagger.dart';
import '../../feedback/data/feedback_outbox.dart' show SendResult, sendResultOf;
import '../domain/reaction.dart';

/// The server's answer to one queued reaction.
typedef ReactionSent = ({SendResult result, ReactionSummary? summary});

/// Where reactions go: `PUT` / `DELETE /v1/reactions/{target}` and the counts.
abstract interface class ReactionServer {
  /// Sets [reaction] for [target], or removes the reader's reaction when null.
  Future<ReactionSent> send(String target, Reaction? reaction);

  /// Counts and the reader's own choice; throws when offline or refused.
  Future<Map<String, ReactionSummary>> fetch(List<String> targets);
}

ReactionSummary summaryOf(ReactionSummaryOut o) => ReactionSummary(
  counts: {
    for (final c in o.counts)
      if (Reaction.parse(c.reaction.value) case final r? when c.count > 0)
        r: c.count,
  },
  mine: Reaction.parse(o.mine),
);

class ApiReactionServer implements ReactionServer {
  const ApiReactionServer(this._api);
  final Bagmitra _api;

  /// The API caps one counts call at 50 targets.
  static const maxTargets = 50;

  @override
  Future<ReactionSent> send(String target, Reaction? reaction) async {
    try {
      final res = reaction == null
          ? await _api.v1ReactionsTargetDelete(target: target)
          : await _api.v1ReactionsTargetPut(
              target: target,
              body: ReactionIn(
                reaction: enums.ReactionInReaction.values.byName(
                  reaction.value,
                ),
              ),
            );
      final body = res.body;
      return (
        result: sendResultOf(res.statusCode),
        summary: res.isSuccessful && body != null ? summaryOf(body) : null,
      );
    } on Object {
      return (result: SendResult.retryLater, summary: null);
    }
  }

  @override
  Future<Map<String, ReactionSummary>> fetch(List<String> targets) async {
    final res = await _api.v1ReactionsGet(
      target: targets.take(maxTargets).toList(),
    );
    final body = res.body;
    if (!res.isSuccessful || body == null) {
      throw Exception('reactions: HTTP ${res.statusCode}');
    }
    return {for (final r in body.reactions) r.target: summaryOf(r)};
  }
}

/// Demo mode (no backend): every reaction is taken at once and only this reader counts.
class DemoReactionServer implements ReactionServer {
  final _mine = <String, Reaction>{};

  ReactionSummary _summary(String target) {
    final r = _mine[target];
    return ReactionSummary(counts: r == null ? const {} : {r: 1}, mine: r);
  }

  @override
  Future<ReactionSent> send(String target, Reaction? reaction) async {
    if (reaction == null) {
      _mine.remove(target);
    } else {
      _mine[target] = reaction;
    }
    return (result: SendResult.sent, summary: _summary(target));
  }

  @override
  Future<Map<String, ReactionSummary>> fetch(List<String> targets) async => {
    for (final t in targets) t: _summary(t),
  };
}
