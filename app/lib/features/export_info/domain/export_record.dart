import '../../spray/domain/spray_check.dart';
import '../../spray/domain/spray_record.dart';

/// What the grower's own label check says about one spray, for the export record.
/// [listed]: the active ingredient is on a registered CIB&RC label row for the crop (the
/// label list saved on the phone); [check]: it could not be matched (no ingredient entered,
/// no saved label list, or no row with that name): the grower checks the label;
/// [banned] / [restricted]: the app's ban / crop-restriction check flagged it.
enum LabelStatus { listed, check, banned, restricted }

/// One line of the export record: a spray as the grower recorded it.
class ExportRecordRow {
  const ExportRecordRow({
    required this.sprayedOn,
    required this.product,
    required this.status,
    this.activeIngredient,
    this.dose,
    this.phiEnd,
  });

  final DateTime sprayedOn;
  final String product;
  final String? activeIngredient;
  final String? dose;
  final LabelStatus status;

  /// Spray date + the recorded pre-harvest interval; null when no PHI was recorded.
  final DateTime? phiEnd;
}

/// The sprays of one plot ([baharCycleId] null: every spray of the plot), oldest first,
/// each with its label status and PHI end date. Only what the grower recorded and the app
/// already checks; no compliance verdict is made.
List<ExportRecordRow> exportRecordRows({
  required List<SprayRecord> sprays,
  required String? baharCycleId,
  required CropRules crop,
  required RestrictionList rules,

  /// Active ingredients on the crop's saved label rows; null when none are saved.
  required Iterable<String>? labelIngredients,
}) {
  final onLabel = labelIngredients == null
      ? null
      : {for (final a in labelIngredients) rules.resolve(a)};
  final picked = [
    for (final s in sprays)
      if (baharCycleId == null || s.baharCycleId == baharCycleId) s,
  ]..sort((a, b) => a.sprayedOn.compareTo(b.sprayedOn));
  return [
    for (final s in picked)
      ExportRecordRow(
        sprayedOn: s.sprayedOn,
        product: s.productName,
        activeIngredient: s.activeIngredient,
        dose: s.dose,
        phiEnd: s.phiDays == null
            ? null
            : DateTime(
                s.sprayedOn.year,
                s.sprayedOn.month,
                s.sprayedOn.day + s.phiDays!,
              ),
        status: _status(s, crop, rules, onLabel),
      ),
  ];
}

LabelStatus _status(
  SprayRecord s,
  CropRules crop,
  RestrictionList rules,
  Set<String>? onLabel,
) {
  final kinds = checkSpray(
    activeIngredient: s.activeIngredient,
    sprayedOn: s.sprayedOn,
    crop: crop,
    rules: rules,
  ).map((w) => w.kind);
  if (kinds.contains(SprayWarningKind.banned)) return LabelStatus.banned;
  if (kinds.contains(SprayWarningKind.restrictedForCrop)) {
    return LabelStatus.restricted;
  }
  final ai = s.activeIngredient;
  if (onLabel == null || ai == null || ai.trim().isEmpty) {
    return LabelStatus.check;
  }
  return onLabel.contains(rules.resolve(ai))
      ? LabelStatus.listed
      : LabelStatus.check;
}

/// Splits rows over printed pages; the first page also holds the heading, so fewer rows.
/// No rows still gives one page (the heading and footer).
List<List<T>> paginate<T>(
  List<T> rows, {
  required int first,
  required int other,
}) {
  final pages = <List<T>>[rows.take(first).toList()];
  for (var i = first; i < rows.length; i += other) {
    pages.add(rows.skip(i).take(other).toList());
  }
  return pages;
}
