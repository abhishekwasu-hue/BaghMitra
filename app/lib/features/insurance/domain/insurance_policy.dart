import '../../bahar/domain/bahar_cycle.dart';
import '../../tasks/domain/farm_task.dart' show dateOnly;

/// Schemes a grower can pick. "unknown" is a real answer: many growers enrol through a bank
/// or CSC and do not know which scheme it was.
const insuranceSchemes = ['pmfby', 'rwbcis', 'other', 'unknown'];

/// The bahar a fruit crop policy covers (separate Ambia and Mrig notifications).
const insuranceSeasons = ['ambia', 'mrig'];

/// One crop insurance policy for a plot, as the grower recorded it ("पीक विमा नोंद"). A
/// record only: the app never fills in a premium, cover or rule. Synced as
/// `insurance_policy`.
class InsurancePolicy {
  const InsurancePolicy({
    required this.id,
    required this.plotId,
    required this.scheme,
    required this.season,
    this.seasonYear,
    this.insurerName,
    this.policyNumber,
    this.sumInsuredPaise,
    this.premiumPaidPaise,
    this.enrolledOn,
    this.note,
  });

  final String id;
  final String plotId;
  final String scheme;
  final String season;
  final int? seasonYear;
  final String? insurerName;

  /// Policy or application number.
  final String? policyNumber;
  final int? sumInsuredPaise;
  final int? premiumPaidPaise;
  final DateTime? enrolledOn;
  final String? note;

  Map<String, Object?> toPayload() => {
    'plot_id': plotId,
    'scheme': scheme,
    'season': season,
    'season_year': seasonYear,
    'insurer_name': insurerName,
    'policy_number': policyNumber,
    'sum_insured_paise': sumInsuredPaise,
    'premium_paid_paise': premiumPaidPaise,
    'enrolled_on': enrolledOn == null ? null : BaharCycle.isoDate(enrolledOn!),
    'note': note,
  };

  static InsurancePolicy fromPayload(String id, Map<String, Object?> p) =>
      InsurancePolicy(
        id: id,
        plotId: p['plot_id']! as String,
        scheme: p['scheme']! as String,
        season: p['season']! as String,
        seasonYear: p['season_year'] as int?,
        insurerName: p['insurer_name'] as String?,
        policyNumber: p['policy_number'] as String?,
        sumInsuredPaise: p['sum_insured_paise'] as int?,
        premiumPaidPaise: p['premium_paid_paise'] as int?,
        enrolledOn: p['enrolled_on'] == null
            ? null
            : DateTime.parse(p['enrolled_on']! as String),
        note: p['note'] as String?,
      );
}

/// An enrolment date from a published official notice in the govt feed. Only what the
/// server found: no notice, no deadline.
class InsuranceDeadline {
  const InsuranceDeadline({
    required this.itemId,
    required this.title,
    required this.dueDate,
    required this.url,
    this.season,
  });

  factory InsuranceDeadline.fromJson(Map<String, Object?> j) =>
      InsuranceDeadline(
        itemId: j['item_id']! as String,
        title: j['title']! as String,
        dueDate: DateTime.parse(j['due_date']! as String),
        url: j['url']! as String,
        season: j['season'] as String?,
      );

  final String itemId;
  final String title;
  final DateTime dueDate;
  final String url;

  /// `ambia` / `mrig` when the notice names one bahar, else null (applies to either).
  final String? season;

  /// Shown for a policy of [policySeason] (or for a plot without a policy: [policySeason]
  /// null) while the date has not passed.
  bool appliesTo(String? policySeason, DateTime today) =>
      !dateOnly(dueDate).isBefore(dateOnly(today)) &&
      (season == null || policySeason == null || season == policySeason);

  Map<String, Object?> toJson() => {
    'item_id': itemId,
    'title': title,
    'due_date': BaharCycle.isoDate(dueDate),
    'url': url,
    'season': season,
  };
}
