import '../../spray/domain/spray_check.dart';
import '../../spray/domain/spray_record.dart';

/// What the grower's own label check says about one spray, for the export record.
/// [listed]: the active ingredient is on a registered CIB&RC label row for the crop (the
/// label list saved on the phone); [check]: it could not be matched (no ingredient entered,
/// no saved label list, or no row with that name): the grower checks the label;
/// [banned] / [restricted]: the app's ban / crop-restriction check flagged it.
enum LabelStatus { listed, check, banned, restricted }

/// One line of the export record: a spray as the grower recorded it. A tank mix (Q142) is
/// one line with every product ([products]); its PHI end is the longest of them.
class ExportRecordRow {
  const ExportRecordRow({
    required this.sprayedOn,
    required this.product,
    required this.status,
    this.activeIngredient,
    this.dose,
    this.phiEnd,
    this.products = const [],
  });

  final DateTime sprayedOn;

  /// The product, or the mix's products joined ("Captan + Imidacloprid").
  final String product;

  /// The ingredient, or every recorded ingredient of the mix joined with " + ".
  final String? activeIngredient;

  /// The dose of a single product (a mix's doses are on [products]).
  final String? dose;

  /// The worst status among the products: banned, then restricted, then check.
  final LabelStatus status;

  /// Spray date + the longest recorded pre-harvest interval; null when none was recorded.
  final DateTime? phiEnd;

  /// Every product of a mix; empty for a single product.
  final List<SprayProduct> products;

  bool get isMix => products.length > 1;
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
  return [for (final s in picked) _row(s, crop, rules, onLabel)];
}

ExportRecordRow _row(
  SprayRecord s,
  CropRules crop,
  RestrictionList rules,
  Set<String>? onLabel,
) {
  final phi = SprayRecord.strictestPhi(s.products);
  final ais = s.activeIngredients;
  return ExportRecordRow(
    sprayedOn: s.sprayedOn,
    product: s.productsLabel,
    activeIngredient: s.isMix
        ? (ais.isEmpty ? null : ais.join(' + '))
        : s.activeIngredient,
    dose: s.isMix ? null : s.dose,
    phiEnd: phi == null
        ? null
        : DateTime(s.sprayedOn.year, s.sprayedOn.month, s.sprayedOn.day + phi),
    status: _worst([
      for (final p in s.products)
        _status(p.activeIngredient, s.sprayedOn, crop, rules, onLabel),
    ]),
    products: s.isMix ? s.products : const [],
  );
}

LabelStatus _worst(List<LabelStatus> all) {
  for (final s in const [
    LabelStatus.banned,
    LabelStatus.restricted,
    LabelStatus.check,
  ]) {
    if (all.contains(s)) return s;
  }
  return LabelStatus.listed;
}

LabelStatus _status(
  String? ai,
  DateTime sprayedOn,
  CropRules crop,
  RestrictionList rules,
  Set<String>? onLabel,
) {
  final kinds = checkSpray(
    activeIngredient: ai,
    sprayedOn: sprayedOn,
    crop: crop,
    rules: rules,
  ).map((w) => w.kind);
  if (kinds.contains(SprayWarningKind.banned)) return LabelStatus.banned;
  if (kinds.contains(SprayWarningKind.restrictedForCrop)) {
    return LabelStatus.restricted;
  }
  if (onLabel == null || ai == null || ai.trim().isEmpty) {
    return LabelStatus.check;
  }
  return onLabel.contains(rules.resolve(ai))
      ? LabelStatus.listed
      : LabelStatus.check;
}

/// Splits rows over printed pages; the first page also holds the heading, so fewer rows.
/// No rows still gives one page (the heading and footer). [weight] is how many lines a row
/// takes (a tank mix prints a line per product); a row taller than a page gets its own.
List<List<T>> paginate<T>(
  List<T> rows, {
  required int first,
  required int other,
  int Function(T row)? weight,
}) {
  final pages = <List<T>>[[]];
  var room = first;
  var used = 0;
  for (final r in rows) {
    final w = weight?.call(r) ?? 1;
    if (used + w > room && pages.last.isNotEmpty) {
      pages.add([]);
      room = other;
      used = 0;
    }
    pages.last.add(r);
    used += w;
  }
  return pages;
}
