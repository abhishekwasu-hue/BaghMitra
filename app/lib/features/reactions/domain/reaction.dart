import '../../../l10n/app_localizations.dart';

/// A reader's reaction after reading a feed item or an answer (owner 2026-11-12, Q146). A
/// fixed, calm set in the order the bar shows it; [value] is the API's word.
enum Reaction {
  useful('useful', '👍'),
  thanks('thanks', '🙏'),
  liked('liked', '😊'),
  okay('okay', '😐'),
  unclear('unclear', '😟');

  const Reaction(this.value, this.emoji);

  final String value;
  final String emoji;

  static Reaction? parse(Object? v) =>
      values.where((r) => r.value == v).firstOrNull;

  String label(AppLocalizations t) => switch (this) {
    useful => t.reactionUseful,
    thanks => t.reactionThanks,
    liked => t.reactionLiked,
    okay => t.reactionOkay,
    unclear => t.reactionUnclear,
  };
}

/// The target key of a bundled answer of the विचारा tab (the API's `qa:<id>`).
String qaReactionTarget(String answerId) => 'qa:$answerId';

/// What the server last said about one target: every reaction's count and the reader's own.
class ReactionSummary {
  const ReactionSummary({this.counts = const {}, this.mine});

  factory ReactionSummary.fromJson(Map<String, Object?> j) => ReactionSummary(
    counts: {
      for (final MapEntry(:key, :value)
          in ((j['counts'] as Map?) ?? const {}).entries)
        if (Reaction.parse(key) case final r? when value is int && value > 0)
          r: value,
    },
    mine: Reaction.parse(j['mine']),
  );

  /// Only reactions someone chose (a missing one is zero).
  final Map<Reaction, int> counts;
  final Reaction? mine;

  int count(Reaction r) => counts[r] ?? 0;

  Map<String, Object?> toJson() => {
    'counts': {
      for (final MapEntry(:key, :value) in counts.entries) key.value: value,
    },
    'mine': mine?.value,
  };
}

/// What the bar shows for one target: the server's counts with the reader's own choice
/// applied at once (even before the server has it), and whether that choice still waits.
class ReactionView {
  const ReactionView({this.counts = const {}, this.mine, this.pending = false});

  /// [server] (may be null: never fetched) with the reader's [local] choice in place of the
  /// one the server holds.
  factory ReactionView.of(
    ReactionSummary? server, {
    required bool hasLocal,
    Reaction? local,
  }) {
    final base = server ?? const ReactionSummary();
    if (!hasLocal) {
      return ReactionView(counts: base.counts, mine: base.mine);
    }
    final counts = Map<Reaction, int>.of(base.counts);
    void add(Reaction? r, int by) {
      if (r == null) return;
      final n = (counts[r] ?? 0) + by;
      if (n > 0) {
        counts[r] = n;
      } else {
        counts.remove(r);
      }
    }

    add(base.mine, -1);
    add(local, 1);
    return ReactionView(counts: counts, mine: local, pending: true);
  }

  final Map<Reaction, int> counts;
  final Reaction? mine;

  /// The reader's choice is not on the server yet.
  final bool pending;

  int count(Reaction r) => counts[r] ?? 0;
}
