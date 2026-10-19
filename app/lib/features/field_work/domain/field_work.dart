import '../../bahar/domain/bahar_cycle.dart';

/// One lot picked on a day. Grade and size class are config slugs and optional, so a grower
/// can first note just the weight.
class HarvestRecord {
  const HarvestRecord({
    required this.id,
    required this.plotId,
    required this.harvestedOn,
    required this.quantityKg,
    this.baharCycleId,
    this.grade,
    this.sizeClass,
    this.note,
  });

  final String id;
  final String plotId;
  final String? baharCycleId;
  final DateTime harvestedOn;
  final String? grade;
  final String? sizeClass;
  final double quantityKg;
  final String? note;

  Map<String, Object?> toPayload() => {
    'plot_id': plotId,
    'bahar_cycle_id': baharCycleId,
    'harvested_on': BaharCycle.isoDate(harvestedOn),
    'grade': grade,
    'size_class': sizeClass,
    'quantity_kg': quantityKg,
    'note': note,
  };

  static HarvestRecord fromPayload(String id, Map<String, Object?> p) =>
      HarvestRecord(
        id: id,
        plotId: p['plot_id']! as String,
        baharCycleId: p['bahar_cycle_id'] as String?,
        harvestedOn: DateTime.parse(p['harvested_on']! as String),
        grade: p['grade'] as String?,
        sizeClass: p['size_class'] as String?,
        quantityKg: (p['quantity_kg']! as num).toDouble(),
        note: p['note'] as String?,
      );
}

/// A worker's day: wage earned, advance already paid and when it was settled. The wage is
/// counted under labour in the bahar summary (it is not also entered as an expense).
class LabourRecord {
  const LabourRecord({
    required this.id,
    required this.plotId,
    required this.workerName,
    required this.workedOn,
    required this.wagePaise,
    this.baharCycleId,
    this.task,
    this.advancePaise = 0,
    this.settledOn,
    this.note,
  });

  final String id;
  final String plotId;
  final String? baharCycleId;
  final String workerName;
  final DateTime workedOn;

  /// Slug from `assets/config/field_work.json`.
  final String? task;
  final int wagePaise;
  final int advancePaise;
  final DateTime? settledOn;
  final String? note;

  bool get settled => settledOn != null;

  /// What the grower still owes the worker. An advance above the wage leaves nothing due.
  int get duePaise =>
      settled || advancePaise >= wagePaise ? 0 : wagePaise - advancePaise;

  Map<String, Object?> toPayload() => {
    'plot_id': plotId,
    'bahar_cycle_id': baharCycleId,
    'worker_name': workerName,
    'worked_on': BaharCycle.isoDate(workedOn),
    'task': task,
    'wage_paise': wagePaise,
    'advance_paise': advancePaise,
    'settled_on': settledOn == null ? null : BaharCycle.isoDate(settledOn!),
    'note': note,
  };

  static LabourRecord fromPayload(String id, Map<String, Object?> p) =>
      LabourRecord(
        id: id,
        plotId: p['plot_id']! as String,
        baharCycleId: p['bahar_cycle_id'] as String?,
        workerName: p['worker_name']! as String,
        workedOn: DateTime.parse(p['worked_on']! as String),
        task: p['task'] as String?,
        wagePaise: p['wage_paise']! as int,
        advancePaise: p['advance_paise']! as int,
        settledOn: p['settled_on'] == null
            ? null
            : DateTime.parse(p['settled_on']! as String),
        note: p['note'] as String?,
      );
}
