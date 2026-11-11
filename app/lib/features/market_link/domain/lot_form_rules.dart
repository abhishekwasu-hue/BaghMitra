import '../../bahar/data/stage_templates.dart';
import '../../bahar/domain/bahar_cycle.dart';

/// The harvest window a lot starts with: the bahar's harvest stage window from its
/// template (counting from the grower's own dates), else the harvest date the grower
/// entered, else none. Public stage windows only; nothing is guessed (Q57).
StageWindow? harvestWindowFor(BaharCycle cycle, StageTemplate? template) {
  const key = 'harvest';
  final dates = {...cycle.planned, ...cycle.actual};
  final fromTemplate = template?.windows(cycle.seasonYear, dates)[key];
  if (fromTemplate != null) return fromTemplate;
  final entered = dates[key];
  return entered == null ? null : StageWindow(entered, entered);
}

const _devanagariDigits = '०१२३४५६७८९';
final _phone = RegExp(r'(?:\d[\s\-.()+/]*){10,}');
final _link = RegExp(
  r'https?://|www\.|wa\.me|t\.me|\S+@\S+\.\w{2,}'
  r'|\b[a-z0-9-]+\.(?:com|in|net|org|co|info|biz|me|io|app|link|ly|xyz|online|site|shop)\b',
  caseSensitive: false,
);

/// True when lot text holds something like a phone number or a link: a buyer reads it
/// before acceptance, so the server refuses it (spec v1.5 §4B; same rule as the API's
/// `has_contact_details`).
bool hasContactDetails(String text) {
  final plain = text.split('').map((c) {
    final i = _devanagariDigits.indexOf(c);
    return i < 0 ? c : '$i';
  }).join();
  return _phone.hasMatch(plain) || _link.hasMatch(plain);
}

/// One asking-rate range in paise, both ends allowed.
typedef RateRange = ({int min, int max});

/// The lot form settings the admin sets on the server (owner 2026-11-11, Q138): the rate
/// range per crop (santra and mosambi each their own) and basis (per quintal, per crate; the
/// whole orchard has none), for the grower's asking rate and a trader's offer, and how many
/// days after the chosen start the harvest window ends by default. The phone keeps the last
/// copy from `/v1/market-link/lot-settings`; [bundled] (the server's defaults) is used only
/// until the first answer arrives. The server checks the range again.
class LotFormSettings {
  const LotFormSettings({
    required this.ranges,
    required this.harvestWindowDays,
  });

  factory LotFormSettings.fromJson(Map<String, Object?> json) {
    final ranges = <String, Map<String, RateRange>>{};
    for (final r
        in (json['rate_ranges']! as List).cast<Map<String, Object?>>()) {
      (ranges[r['crop']! as String] ??= {})[r['basis']! as String] = (
        min: r['min_paise']! as int,
        max: r['max_paise']! as int,
      );
    }
    return LotFormSettings(
      ranges: ranges,
      harvestWindowDays: json['harvest_window_days']! as int,
    );
  }

  static const _defaults = {
    'per_quintal': (min: 250000, max: 1000000),
    'per_crate': (min: 40000, max: 120000),
  };

  static const bundled = LotFormSettings(
    ranges: {'santra': _defaults, 'mosambi': _defaults},
    harvestWindowDays: 15,
  );

  /// crop -> basis -> range.
  final Map<String, Map<String, RateRange>> ranges;
  final int harvestWindowDays;

  RateRange? rangeOf(String? crop, String? basis) => ranges[crop]?[basis];

  /// True when [paise] is inside the range of [crop] and [basis], or there is no range.
  bool fits(String? crop, String? basis, int paise) {
    final r = rangeOf(crop, basis);
    return r == null || (paise >= r.min && paise <= r.max);
  }

  /// The default end of a harvest window that starts on [from] (calendar days).
  DateTime harvestEnd(DateTime from) =>
      DateTime(from.year, from.month, from.day + harvestWindowDays);
}
