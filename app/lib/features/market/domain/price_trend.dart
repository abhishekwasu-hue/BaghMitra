import '../../../api/generated/bagmitra.swagger.dart';

/// Owner 2026-11-09 (Q130): the trend chart's ranges, three months by default.
enum TrendRange {
  days15(15),
  month1(30),
  months3(90);

  const TrendRange(this.days);

  final int days;
}

/// Points of one mandi's series inside [range], counted back from [today].
/// The API already sends one published price per day, oldest first.
List<PriceDay> pointsIn(List<PriceDay> all, TrendRange range, DateTime today) {
  final from = DateTime(
    today.year,
    today.month,
    today.day,
  ).subtract(Duration(days: range.days));
  return [
    for (final p in all)
      if (p.day.isAfter(from)) p,
  ];
}

/// Two published days further apart than this are not joined by the line: the gap shows
/// that no price was published (a weekend or holiday stays joined).
const maxJoinedGapDays = 3;

bool joined(PriceDay a, PriceDay b) =>
    b.day.difference(a.day).inDays <= maxJoinedGapDays;

/// High, low and latest modal price of a series, and the change of the latest price
/// against the last published price on or before 15 days and 1 month earlier.
class TrendStats {
  const TrendStats({
    required this.high,
    required this.low,
    required this.latest,
    this.change15,
    this.change30,
  });

  final PriceDay high;
  final PriceDay low;
  final PriceDay latest;

  /// Percent change (whole number, may be negative); null when no earlier price exists.
  final int? change15;
  final int? change30;

  static TrendStats? of(List<PriceDay> points) {
    if (points.isEmpty) return null;
    var high = points.first;
    var low = points.first;
    for (final p in points) {
      if (p.modalRsPerQuintal > high.modalRsPerQuintal) high = p;
      if (p.modalRsPerQuintal < low.modalRsPerQuintal) low = p;
    }
    final latest = points.last;
    return TrendStats(
      high: high,
      low: low,
      latest: latest,
      change15: _changeSince(points, latest, 15),
      change30: _changeSince(points, latest, 30),
    );
  }

  static int? _changeSince(List<PriceDay> points, PriceDay latest, int days) {
    final cutoff = latest.day.subtract(Duration(days: days));
    PriceDay? before;
    for (final p in points) {
      if (p.day.isAfter(cutoff)) break;
      before = p;
    }
    if (before == null || before.modalRsPerQuintal == 0) return null;
    final diff = latest.modalRsPerQuintal - before.modalRsPerQuintal;
    return (diff * 100 / before.modalRsPerQuintal).round();
  }
}
