import '../../bahar/domain/bahar_cycle.dart';

/// What was sampled. The grower picks one; nothing else is inferred from it.
const labTestTypes = ['soil', 'water', 'leaf'];

/// One value from a lab report, exactly as the grower typed it. [value] stays text ("<0.5",
/// "7.9"): the app never parses, rates or compares it with a range.
class LabReading {
  const LabReading({required this.parameter, required this.value, this.unit});

  factory LabReading.fromJson(Map<String, Object?> j) => LabReading(
    parameter: j['parameter']! as String,
    value: j['value']! as String,
    unit: j['unit'] as String?,
  );

  final String parameter;
  final String value;
  final String? unit;

  Map<String, Object?> toJson() => {
    'parameter': parameter,
    'value': value,
    'unit': unit,
  };

  /// "7.9 dS/m", or the value alone without a unit.
  String get valueWithUnit => unit == null ? value : '$value $unit';
}

/// A soil, water or leaf test of one plot ("माती / पाणी / पान तपासणी"), as the grower
/// recorded it from the lab report or Soil Health Card. A record only: no interpretation.
/// Synced as `lab_test`; [reportPath] (the report photo or file) stays on this phone.
class LabTest {
  const LabTest({
    required this.id,
    required this.plotId,
    required this.testType,
    required this.sampledOn,
    this.labName,
    this.reportedOn,
    this.readings = const [],
    this.note,
    this.reportPath,
  });

  final String id;
  final String plotId;

  /// One of [labTestTypes].
  final String testType;
  final DateTime sampledOn;
  final String? labName;
  final DateTime? reportedOn;
  final List<LabReading> readings;
  final String? note;

  /// The kept report photo or file on this phone; never synced.
  final String? reportPath;

  /// The kept report is a picture the app can show (else a file, such as a PDF).
  bool get reportIsImage => isImagePath(reportPath);

  LabTest withReportPath(String? path) => LabTest(
    id: id,
    plotId: plotId,
    testType: testType,
    sampledOn: sampledOn,
    labName: labName,
    reportedOn: reportedOn,
    readings: readings,
    note: note,
    reportPath: path,
  );

  Map<String, Object?> toPayload() => {
    'plot_id': plotId,
    'test_type': testType,
    'sampled_on': BaharCycle.isoDate(sampledOn),
    'lab_name': labName,
    'reported_on': reportedOn == null ? null : BaharCycle.isoDate(reportedOn!),
    'readings': [for (final r in readings) r.toJson()],
    'note': note,
  };

  static LabTest fromPayload(String id, Map<String, Object?> p) => LabTest(
    id: id,
    plotId: p['plot_id']! as String,
    testType: p['test_type']! as String,
    sampledOn: DateTime.parse(p['sampled_on']! as String),
    labName: p['lab_name'] as String?,
    reportedOn: p['reported_on'] == null
        ? null
        : DateTime.parse(p['reported_on']! as String),
    readings: readingsFromJson(p['readings']),
    note: p['note'] as String?,
  );

  static List<LabReading> readingsFromJson(Object? list) => [
    for (final r in (list as List?) ?? const [])
      LabReading.fromJson((r as Map).cast<String, Object?>()),
  ];
}

/// A kept file the app can show as a picture (else a file such as a PDF).
bool isImagePath(String? path) {
  final lower = path?.toLowerCase();
  return lower != null &&
      const ['.jpg', '.jpeg', '.png', '.webp', '.heic'].any(lower.endsWith);
}

/// The `source` of the "next test due" farm task made for a lab test, so editing the
/// test moves the same reminder instead of adding another.
String labTestReminderSource(String labTestId) => 'lab_test:$labTestId';
