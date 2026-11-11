import '../../bahar/domain/bahar_cycle.dart';

/// One spray application. `activeIngredient` is what the ban / PHI check keys on. The
/// optional bill photo lives on this phone ([billPhotoPath], never synced); [billPhotoKey] is
/// set once the optional photo backup has uploaded it, and is synced (OPEN_QUESTIONS Q136).
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
  });

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

  bool get hasBillPhoto => billPhotoPath != null || billPhotoKey != null;

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
      );
}
