/// One published mandi price, as far as the fair-price check needs it.
class MandiPrice {
  const MandiPrice({
    required this.market,
    required this.day,
    required this.modalRsPerQuintal,
    this.isLocal = false,
    this.isMajor = false,
  });

  final String market;
  final DateTime day;
  final int modalRsPerQuintal;
  final bool isLocal;
  final bool isMajor;
}

/// A sale rate set beside one market's modal price on the same day.
class FairPriceComparison {
  const FairPriceComparison({
    required this.market,
    required this.day,
    required this.modalRsPerQuintal,
    required this.percent,
  });

  final String market;
  final DateTime day;
  final int modalRsPerQuintal;

  /// Whole per cent the rate is above (positive) or below (negative) the modal price.
  final int percent;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Compares a sale rate (paise per quintal) with the modal price published for the sale
/// day: a local APMC first, then a major market, then the first listed. Null when no
/// price was published that day (no nearest-day guess, no forecast) or there is no rate.
FairPriceComparison? compareWithMandi({
  required int ratePaisePerQuintal,
  required DateTime soldOn,
  required Iterable<MandiPrice> prices,
}) {
  if (ratePaisePerQuintal <= 0) return null;
  final sameDay = [
    for (final p in prices)
      if (_sameDay(p.day, soldOn) && p.modalRsPerQuintal > 0) p,
  ];
  if (sameDay.isEmpty) return null;
  final pick =
      sameDay.where((p) => p.isLocal).firstOrNull ??
      sameDay.where((p) => p.isMajor).firstOrNull ??
      sameDay.first;
  final modalPaise = pick.modalRsPerQuintal * 100;
  return FairPriceComparison(
    market: pick.market,
    day: pick.day,
    modalRsPerQuintal: pick.modalRsPerQuintal,
    percent: ((ratePaisePerQuintal - modalPaise) * 100 / modalPaise).round(),
  );
}
