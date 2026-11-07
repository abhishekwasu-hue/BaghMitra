// After the introduction (spec v1.5 §3 step 7, §3A; L5): the "deal done" taps and the
// ratings. Ratings are stars per question and ticks from the admin's tag list only; there
// is no text anywhere (Q66).

DateTime? _time(Object? v) => v == null ? null : DateTime.parse(v as String);

/// grower, trader or broker.
enum DealRole { grower, trader, broker }

/// Where the deal stands for the caller (server state; the phone never decides it).
class DealState {
  const DealState({
    required this.myRole,
    required this.rates,
    this.growerDoneAt,
    this.traderDoneAt,
    this.completedAt,
    this.ratingUntil,
    this.ratingLocked = false,
  });

  factory DealState.fromJson(Map<String, Object?> j) => DealState(
    myRole: DealRole.values.byName(j['my_role']! as String),
    growerDoneAt: _time(j['grower_done_at']),
    traderDoneAt: _time(j['trader_done_at']),
    completedAt: _time(j['completed_at']),
    ratingUntil: _time(j['rating_until']),
    ratingLocked: j['rating_locked'] as bool? ?? false,
    rates: [
      for (final r in (j['rates'] as List?) ?? const [])
        DealRole.values.byName(r as String),
    ],
  );

  final DealRole myRole;
  final DateTime? growerDoneAt;
  final DateTime? traderDoneAt;
  final DateTime? completedAt;

  /// Ratings can be given or changed until then (7 days from completion, Q66).
  final DateTime? ratingUntil;
  final bool ratingLocked;

  /// The roles the caller rates on this deal.
  final List<DealRole> rates;

  /// Only the grower and the trader tap "deal done" (Q67).
  bool get iTap => myRole != DealRole.broker;

  bool get iTapped => switch (myRole) {
    DealRole.grower => growerDoneAt != null,
    DealRole.trader => traderDoneAt != null,
    DealRole.broker => false,
  };

  bool get completed => completedAt != null;
}

/// One tick under a rating question, from the admin's list (mr / hi / en labels).
class RatingTagItem {
  const RatingTagItem({
    required this.id,
    required this.questionKey,
    required this.polarity,
    required this.labels,
  });

  factory RatingTagItem.fromJson(Map<String, Object?> j) => RatingTagItem(
    id: j['id']! as String,
    questionKey: j['question_key']! as String,
    polarity: j['polarity']! as String,
    labels: {
      for (final c in const ['mr', 'hi', 'en']) c: j['label_$c']! as String,
    },
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'question_key': questionKey,
    'polarity': polarity,
    for (final e in labels.entries) 'label_${e.key}': e.value,
  };

  final String id;
  final String questionKey;
  final String polarity;
  final Map<String, String> labels;

  String label(String lang) => labels[lang] ?? labels['en']!;
}

/// The answer to one question: 1-5 stars and the ticked tag ids.
class RatingAnswer {
  const RatingAnswer(this.questionKey, this.stars, [this.tagIds = const []]);

  factory RatingAnswer.fromJson(Map<String, Object?> j) => RatingAnswer(
    j['question_key']! as String,
    (j['stars']! as num).toInt(),
    [for (final t in (j['tag_ids'] as List?) ?? const []) t as String],
  );

  Map<String, Object?> toJson() => {
    'question_key': questionKey,
    'stars': stars,
    'tag_ids': tagIds,
  };

  final String questionKey;
  final int stars;
  final List<String> tagIds;
}

/// The caller's ratings on a deal, the questions per rated role and the window.
class DealRatings {
  const DealRatings({
    required this.state,
    required this.questions,
    required this.given,
  });

  factory DealRatings.fromJson(Map<String, Object?> j) => DealRatings(
    state: DealState.fromJson((j['state']! as Map).cast<String, Object?>()),
    questions: {
      for (final e in (j['questions']! as Map).entries)
        DealRole.values.byName(e.key as String): [
          for (final q in e.value as List) q as String,
        ],
    },
    given: {
      for (final g in (j['given'] as List?) ?? const [])
        DealRole.values.byName((g as Map)['ratee_role']! as String): [
          for (final a in g['answers']! as List)
            RatingAnswer.fromJson((a as Map).cast<String, Object?>()),
        ],
    },
  );

  final DealState state;
  final Map<DealRole, List<String>> questions;
  final Map<DealRole, List<RatingAnswer>> given;
}
