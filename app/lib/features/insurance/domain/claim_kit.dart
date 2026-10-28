/// The crop-loss claim kit checklist. General guidance only: every policy has its own
/// rules, so the screen and the PDF always add "check your policy" and no amounts or
/// deadlines are stated as fact (OPEN_QUESTIONS Q37).
const claimChecklist = [
  'inform_72h',
  'photos',
  'panchnama',
  'policy_copy',
  'acknowledgement',
  'keep_fruit',
];

/// A loss photo, stamped with when and where it was added in the app (not read from the
/// photo file). [lat] / [lon] are null when the phone could not read its position.
class ClaimPhoto {
  const ClaimPhoto({
    required this.id,
    required this.path,
    required this.takenAt,
    this.lat,
    this.lon,
    this.accuracyM,
  });

  final String id;
  final String path;
  final DateTime takenAt;
  final double? lat;
  final double? lon;
  final double? accuracyM;

  bool get hasPosition => lat != null && lon != null;

  /// Latin digits and a fixed layout so the stamp reads the same in every language and in
  /// the PDF: "2026-10-28 14:05 · 21.14580, 79.08820 (±12 m)".
  String stamp({required String noGps}) {
    final t = takenAt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final when =
        '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
    if (!hasPosition) return '$when · $noGps';
    final where = '${lat!.toStringAsFixed(5)}, ${lon!.toStringAsFixed(5)}';
    final acc = accuracyM == null ? '' : ' (±${accuracyM!.round()} m)';
    return '$when · $where$acc';
  }
}

/// One crop-loss record ("नुकसान नोंद"): plot, date of loss, photos, a note and the ticked
/// checklist. Kept on this phone only; shared as a PDF when the grower chooses.
class ClaimKit {
  const ClaimKit({
    required this.id,
    required this.plotId,
    required this.lossOn,
    this.note,
    this.done = const {},
    this.photos = const [],
  });

  final String id;
  final String plotId;
  final DateTime lossOn;
  final String? note;

  /// Ticked [claimChecklist] keys.
  final Set<String> done;
  final List<ClaimPhoto> photos;
}
