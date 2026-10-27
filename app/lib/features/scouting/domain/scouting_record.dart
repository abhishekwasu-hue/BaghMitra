import '../../bahar/domain/bahar_cycle.dart';

/// What the grower looked at. Names only: the scouting log is a record, never advice.
const scoutingItems = [
  'psylla',
  'leaf_miner',
  'mites_thrips',
  'fruit_drop',
  'gummosis_bark',
  'die_back',
  'other',
];

/// How much of it there was.
const scoutingSeverities = ['none', 'low', 'medium', 'high'];

/// One scouting observation on a plot ("पाहणी नोंद"). The optional photo lives only on
/// this phone: [photoPath] is never part of the sync payload.
class ScoutingRecord {
  const ScoutingRecord({
    required this.id,
    required this.plotId,
    required this.observedOn,
    required this.item,
    required this.severity,
    this.baharCycleId,
    this.note,
    this.photoPath,
  });

  final String id;
  final String plotId;
  final String? baharCycleId;
  final DateTime observedOn;
  final String item;
  final String severity;
  final String? note;
  final String? photoPath;

  Map<String, Object?> toPayload() => {
    'plot_id': plotId,
    'bahar_cycle_id': baharCycleId,
    'observed_on': BaharCycle.isoDate(observedOn),
    'item': item,
    'severity': severity,
    'note': note,
  };

  static ScoutingRecord fromPayload(String id, Map<String, Object?> p) =>
      ScoutingRecord(
        id: id,
        plotId: p['plot_id']! as String,
        baharCycleId: p['bahar_cycle_id'] as String?,
        observedOn: DateTime.parse(p['observed_on']! as String),
        item: p['item']! as String,
        severity: p['severity']! as String,
        note: p['note'] as String?,
      );
}
