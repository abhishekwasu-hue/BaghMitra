import '../../bahar/domain/bahar_cycle.dart';

/// The active ingredient to show beside [name], or null when there is none or it is the
/// same as the name in any case and spacing (an empty name is saved as the ingredient,
/// owner 2026-11-12), so a display reads "Carbofuran", not "Carbofuran · Carbofuran".
String? ingredientBesideName(String name, String? activeIngredient) {
  if (activeIngredient == null || activeIngredient.trim().isEmpty) return null;
  String norm(String v) =>
      v.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return norm(activeIngredient) == norm(name) ? null : activeIngredient;
}

/// One product of a spray: what went into the tank, with its own dose, cost and the PHI on
/// its label. A tank mix (OPEN_QUESTIONS Q142) is several of these in one spray.
class SprayProduct {
  const SprayProduct({
    required this.productName,
    this.activeIngredient,
    this.dose,
    this.costPaise = 0,
    this.phiDays,
  });

  final String productName;
  final String? activeIngredient;
  final String? dose;
  final int costPaise;
  final int? phiDays;

  /// [activeIngredient] when it says more than [productName]; see [ingredientBesideName].
  String? get shownIngredient =>
      ingredientBesideName(productName, activeIngredient);

  Map<String, Object?> toPayload() => {
    'product_name': productName,
    'active_ingredient': activeIngredient,
    'dose': dose,
    'cost_paise': costPaise,
    'phi_days': phiDays,
  };

  static SprayProduct fromPayload(Map<String, Object?> p) => SprayProduct(
    productName: p['product_name']! as String,
    activeIngredient: p['active_ingredient'] as String?,
    dose: p['dose'] as String?,
    costPaise: (p['cost_paise'] as int?) ?? 0,
    phiDays: p['phi_days'] as int?,
  );

  @override
  bool operator ==(Object other) =>
      other is SprayProduct &&
      other.productName == productName &&
      other.activeIngredient == activeIngredient &&
      other.dose == dose &&
      other.costPaise == costPaise &&
      other.phiDays == phiDays;

  @override
  int get hashCode =>
      Object.hash(productName, activeIngredient, dose, costPaise, phiDays);
}

/// One spray application. `activeIngredient` is what the ban / PHI check keys on. The
/// optional bill photo lives on this phone ([billPhotoPath], never synced); [billPhotoKey] is
/// set once the optional photo backup has uploaded it, and is synced (OPEN_QUESTIONS Q136).
///
/// A tank mix (Q142) is still one record: one date, water, area and count. [mix] lists its
/// products; the record's own product, ingredient and dose are then the first product's,
/// [costPaise] their sum and [phiDays] the longest of their PHIs ([SprayRecord.ofProducts]),
/// so every total and an older app read it as one spray. A single-product record has an
/// empty [mix] and syncs exactly as before.
class SprayRecord {
  const SprayRecord({
    required this.id,
    required this.plotId,
    required this.sprayedOn,
    required this.productName,
    this.baharCycleId,
    this.activeIngredient,
    this.dose,
    this.waterLitres,
    this.areaAcres,
    this.costPaise = 0,
    this.operator,
    this.phiDays,
    this.target,
    this.billPhotoPath,
    this.billPhotoKey,
    this.mix = const [],
    this.labourPaise,
  });

  /// A record of [products] (at least one) with the shared fields. One product gives the
  /// single-product shape; several give a mix with the summed cost and the longest PHI.
  factory SprayRecord.ofProducts({
    required String id,
    required String plotId,
    required DateTime sprayedOn,
    required List<SprayProduct> products,
    String? baharCycleId,
    double? waterLitres,
    double? areaAcres,
    String? operator,
    String? target,
    String? billPhotoPath,
    String? billPhotoKey,
    int? labourPaise,
  }) {
    if (products.isEmpty) {
      throw ArgumentError.value(products, 'products', 'at least one');
    }
    final first = products.first;
    final mixed = products.length > 1;
    return SprayRecord(
      id: id,
      plotId: plotId,
      baharCycleId: baharCycleId,
      sprayedOn: sprayedOn,
      productName: first.productName,
      activeIngredient: first.activeIngredient,
      dose: first.dose,
      waterLitres: waterLitres,
      areaAcres: areaAcres,
      costPaise: mixed
          ? products.fold(0, (sum, p) => sum + p.costPaise)
          : first.costPaise,
      operator: operator,
      phiDays: mixed ? strictestPhi(products) : first.phiDays,
      target: target,
      billPhotoPath: billPhotoPath,
      billPhotoKey: billPhotoKey,
      mix: mixed ? List.unmodifiable(products) : const [],
      labourPaise: labourPaise,
    );
  }

  final String id;
  final String plotId;
  final String? baharCycleId;
  final DateTime sprayedOn;
  final String productName;
  final String? activeIngredient;
  final String? dose;
  final double? waterLitres;
  final double? areaAcres;
  final int costPaise;
  final String? operator;
  final int? phiDays;
  final String? target;
  final String? billPhotoPath;
  final String? billPhotoKey;

  /// The products of a tank mix; empty for a single-product record.
  final List<SprayProduct> mix;

  /// Spraying labour for the whole spray (Q143), counted under "labour" in the accounts and
  /// never in [costPaise] (the products). Null when not written.
  final int? labourPaise;

  /// What the spray cost in all: the products and the labour.
  int get totalPaise => costPaise + (labourPaise ?? 0);

  bool get hasBillPhoto => billPhotoPath != null || billPhotoKey != null;

  bool get isMix => mix.length > 1;

  /// Every product of the spray: the mix, or the record's own one product.
  List<SprayProduct> get products => mix.isNotEmpty
      ? mix
      : [
          SprayProduct(
            productName: productName,
            activeIngredient: activeIngredient,
            dose: dose,
            costPaise: costPaise,
            phiDays: phiDays,
          ),
        ];

  /// "Captan + Imidacloprid": the product names joined, or the one product's name.
  String get productsLabel =>
      [for (final p in products) p.productName].join(' + ');

  /// Every active ingredient recorded on the spray, in order.
  List<String> get activeIngredients => [
    for (final p in products)
      if (p.activeIngredient case final ai? when ai.trim().isNotEmpty) ai,
  ];

  /// The longest PHI of [products]; null when none has one.
  static int? strictestPhi(Iterable<SprayProduct> products) => products
      .map((p) => p.phiDays)
      .whereType<int>()
      .fold<int?>(null, (a, b) => a == null || b > a ? b : a);

  SprayRecord withBillPhoto({String? path, String? key}) => SprayRecord(
    id: id,
    plotId: plotId,
    baharCycleId: baharCycleId,
    sprayedOn: sprayedOn,
    productName: productName,
    activeIngredient: activeIngredient,
    dose: dose,
    waterLitres: waterLitres,
    areaAcres: areaAcres,
    costPaise: costPaise,
    operator: operator,
    phiDays: phiDays,
    target: target,
    billPhotoPath: path ?? billPhotoPath,
    billPhotoKey: key ?? billPhotoKey,
    mix: mix,
    labourPaise: labourPaise,
  );

  Map<String, Object?> toPayload() => {
    'plot_id': plotId,
    'bahar_cycle_id': baharCycleId,
    'sprayed_on': BaharCycle.isoDate(sprayedOn),
    'product_name': productName,
    'active_ingredient': activeIngredient,
    'dose': dose,
    'water_litres': waterLitres,
    'area_acres': areaAcres,
    'cost_paise': costPaise,
    'operator': operator,
    'phi_days': phiDays,
    'target': target,
    // Only once backed up, so a record without one reads the same as before.
    if (billPhotoKey != null) 'bill_photo_key': billPhotoKey,
    // Only for a mix, so a single-product record syncs exactly as before Q142.
    if (mix.isNotEmpty) 'products': [for (final p in mix) p.toPayload()],
    // Only when written, so a record without it syncs as before Q143.
    if (labourPaise != null) 'labour_paise': labourPaise,
  };

  static SprayRecord fromPayload(String id, Map<String, Object?> p) =>
      SprayRecord(
        id: id,
        plotId: p['plot_id']! as String,
        baharCycleId: p['bahar_cycle_id'] as String?,
        sprayedOn: DateTime.parse(p['sprayed_on']! as String),
        productName: p['product_name']! as String,
        activeIngredient: p['active_ingredient'] as String?,
        dose: p['dose'] as String?,
        waterLitres: (p['water_litres'] as num?)?.toDouble(),
        areaAcres: (p['area_acres'] as num?)?.toDouble(),
        costPaise: p['cost_paise']! as int,
        operator: p['operator'] as String?,
        phiDays: p['phi_days'] as int?,
        target: p['target'] as String?,
        billPhotoKey: p['bill_photo_key'] as String?,
        mix: productsFrom(p['products']),
        labourPaise: p['labour_paise'] as int?,
      );

  /// A stored or synced products list; empty for null or a broken value.
  static List<SprayProduct> productsFrom(Object? raw) {
    if (raw is! List) return const [];
    final out = <SprayProduct>[];
    for (final e in raw) {
      if (e is Map && e['product_name'] is String) {
        out.add(SprayProduct.fromPayload(e.cast<String, Object?>()));
      }
    }
    return out.length > 1 ? List.unmodifiable(out) : const [];
  }
}
