/// One flowering cycle (bahar) of one plot in one season. Stage dates are date-only and
/// keyed by stage slugs from config (`assets/config/bahars.json`) or a published template.
class BaharCycle {
  const BaharCycle({
    required this.id,
    required this.plotId,
    required this.bahar,
    required this.seasonYear,
    required this.status,
    this.templateId,
    this.planned = const {},
    this.actual = const {},
  });

  final String id;
  final String plotId;
  final String bahar;
  final int seasonYear;

  /// planned | active | completed | abandoned (API BaharCyclePayload).
  final String status;
  final String? templateId;
  final Map<String, DateTime> planned;
  final Map<String, DateTime> actual;

  static String isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Map<String, String> encodeDates(Map<String, DateTime> dates) => {
    for (final e in dates.entries) e.key: isoDate(e.value),
  };

  static Map<String, DateTime> decodeDates(Object? json) => {
    for (final e in ((json as Map<Object?, Object?>?) ?? const {}).entries)
      e.key! as String: DateTime.parse(e.value! as String),
  };

  /// Payload for the `bahar_cycle` sync entity.
  Map<String, Object?> toPayload() => {
    'plot_id': plotId,
    'bahar': bahar,
    'season_year': seasonYear,
    'template_id': templateId,
    'status': status,
    'planned': encodeDates(planned),
    'actual': encodeDates(actual),
  };

  static BaharCycle fromPayload(String id, Map<String, Object?> p) =>
      BaharCycle(
        id: id,
        plotId: p['plot_id']! as String,
        bahar: p['bahar']! as String,
        seasonYear: p['season_year']! as int,
        status: p['status']! as String,
        templateId: p['template_id'] as String?,
        planned: decodeDates(p['planned']),
        actual: decodeDates(p['actual']),
      );
}
