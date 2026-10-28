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

/// One scouting observation on a plot ("पाहणी नोंद"). The optional photo file lives on
/// this phone: [photoPath] is never part of the sync payload. [photoKey] is set once the
/// optional photo backup has uploaded it (OPEN_QUESTIONS Q34) and is synced.
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
    this.photoKey,
  });

  final String id;
  final String plotId;
  final String? baharCycleId;
  final DateTime observedOn;
  final String item;
  final String severity;
  final String? note;
  final String? photoPath;
  final String? photoKey;

  /// The photo is backed up on the server (and can be seen on the grower's other phones).
  bool get backedUp => photoKey != null;

  ScoutingRecord withPhoto({String? path, String? key}) => ScoutingRecord(
    id: id,
    plotId: plotId,
    baharCycleId: baharCycleId,
    observedOn: observedOn,
    item: item,
    severity: severity,
    note: note,
    photoPath: path ?? photoPath,
    photoKey: key ?? photoKey,
  );

  Map<String, Object?> toPayload() => {
    'plot_id': plotId,
    'bahar_cycle_id': baharCycleId,
    'observed_on': BaharCycle.isoDate(observedOn),
    'item': item,
    'severity': severity,
    'note': note,
    // Only once backed up, so a record without one reads the same as before the backup.
    if (photoKey != null) 'photo_key': photoKey,
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
        photoKey: p['photo_key'] as String?,
      );
}
