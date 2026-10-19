import '../../bahar/domain/bahar_cycle.dart';

/// A fertiliser / manure / micronutrient application. Its cost is counted under [kind] in
/// the bahar summary (it is not also entered as an expense).
class InputRecord {
  const InputRecord({
    required this.id,
    required this.plotId,
    required this.appliedOn,
    required this.kind,
    required this.productName,
    this.baharCycleId,
    this.quantity,
    this.unit,
    this.costPaise = 0,
    this.note,
  });

  final String id;
  final String plotId;
  final String? baharCycleId;
  final DateTime appliedOn;

  /// Slug from `assets/config/input_kinds.json`.
  final String kind;
  final String productName;
  final double? quantity;
  final String? unit;
  final int costPaise;
  final String? note;

  Map<String, Object?> toPayload() => {
    'plot_id': plotId,
    'bahar_cycle_id': baharCycleId,
    'applied_on': BaharCycle.isoDate(appliedOn),
    'kind': kind,
    'product_name': productName,
    'quantity': quantity,
    'unit': unit,
    'cost_paise': costPaise,
    'note': note,
  };

  static InputRecord fromPayload(String id, Map<String, Object?> p) =>
      InputRecord(
        id: id,
        plotId: p['plot_id']! as String,
        baharCycleId: p['bahar_cycle_id'] as String?,
        appliedOn: DateTime.parse(p['applied_on']! as String),
        kind: p['kind']! as String,
        productName: p['product_name']! as String,
        quantity: (p['quantity'] as num?)?.toDouble(),
        unit: p['unit'] as String?,
        costPaise: p['cost_paise']! as int,
        note: p['note'] as String?,
      );
}

/// An irrigation event. A log only: water and power bills are entered as expenses.
class IrrigationRecord {
  const IrrigationRecord({
    required this.id,
    required this.plotId,
    required this.irrigatedOn,
    this.baharCycleId,
    this.durationHours,
    this.waterLitres,
    this.note,
  });

  final String id;
  final String plotId;
  final String? baharCycleId;
  final DateTime irrigatedOn;
  final double? durationHours;
  final double? waterLitres;
  final String? note;

  Map<String, Object?> toPayload() => {
    'plot_id': plotId,
    'bahar_cycle_id': baharCycleId,
    'irrigated_on': BaharCycle.isoDate(irrigatedOn),
    'duration_hours': durationHours,
    'water_litres': waterLitres,
    'note': note,
  };

  static IrrigationRecord fromPayload(String id, Map<String, Object?> p) =>
      IrrigationRecord(
        id: id,
        plotId: p['plot_id']! as String,
        baharCycleId: p['bahar_cycle_id'] as String?,
        irrigatedOn: DateTime.parse(p['irrigated_on']! as String),
        durationHours: (p['duration_hours'] as num?)?.toDouble(),
        waterLitres: (p['water_litres'] as num?)?.toDouble(),
        note: p['note'] as String?,
      );
}
