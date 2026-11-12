// The phone's own leaf check (OPEN_QUESTIONS Q135, stage 3 offline): the on-device model
// `citrus_v1.tflite` runs on the farmer's photo only when the online check cannot reach the
// server. Its answer is a first estimate, never a diagnosis: the screen says so, and the full
// check runs once the phone is online again. Offline checks never reach the server, so they
// never count against the photo limits.

/// The model file, its labels and the thresholds: the one place to change them.
abstract final class OfflineModel {
  static const asset = 'assets/models/citrus_v1.tflite';
  static const labelsAsset = 'assets/models/citrus_v1_labels.txt';

  /// The model takes the whole photo resized (no crop) to this square, RGB, float 0..255.
  static const inputSize = 224;

  /// Below this probability the best class is "not clear" (provisional default 0.60, logged
  /// in Q135: the model has no Vidarbha field photos yet, so the value is to be set from
  /// field test photos; same-dataset test accuracy was 85.5 %, black spot only 52 %).
  static const minConfidence = 0.60;

  /// A second disease is named too ("or: ...") when the model gives it at least this.
  static const secondFrom = 0.25;
}

/// The data sets the model is trained on (CC BY 4.0, OPEN_QUESTIONS Q135): their citations,
/// shown under the settings screen's data sources. Bibliographic text, not translated.
const offlineModelCitations = [
  'Rauf H.T. et al. (2019). A citrus fruits and leaves dataset for detection and classification of citrus '
      'diseases through machine learning. Data in Brief 26, 104340. '
      'doi 10.1016/j.dib.2019.104340 (Mendeley Data 3f83gxmv57). CC BY 4.0.',
  'Orange leaves images dataset for the detection of HLB (San Luis Potosí, Mexico). '
      'Data 10(5):56 (2025); Mendeley Data jgkh2jxbwt, doi 10.17632/jgkh2jxbwt. CC BY 4.0.',
];

/// One class with its probability.
class OfflineGuess {
  const OfflineGuess(this.key, this.probability);

  /// `canker`, `greening`, `healthy` or `other` (the labels file); the disease keys equal
  /// the practice-card section keys.
  final String key;
  final double probability;

  @override
  String toString() => '$key ${probability.toStringAsFixed(2)}';
}

enum OfflineVerdict {
  /// A disease with a practice card: one or two are named, calmly.
  disease,

  /// The leaf looks healthy.
  healthy,

  /// Below the threshold, or `other`, or not a leaf photo: "not clear, the full check runs
  /// when online".
  unclear,
}

class OfflineReading {
  const OfflineReading(this.verdict, this.shown, {this.best});

  final OfflineVerdict verdict;

  /// What the screen names: one or two diseases, the healthy class, or nothing.
  final List<OfflineGuess> shown;

  /// The model's best class, for the on-device log (also when the verdict is unclear).
  final OfflineGuess? best;

  static const healthy = 'healthy';
  static const other = 'other';
  static const diseases = {'canker', 'greening'};

  /// Not a leaf photo (the farmer chose fruit, trunk or the whole tree): the model only
  /// knows leaves, so it is not run.
  static const notALeaf = OfflineReading(OfflineVerdict.unclear, []);

  /// Maps the model's probabilities (in [labels] order) to what the screen shows.
  /// Throws [ArgumentError] when the counts differ (a model and labels file that do not
  /// belong together).
  static OfflineReading read(List<double> probabilities, List<String> labels) {
    if (probabilities.length != labels.length || labels.isEmpty) {
      throw ArgumentError(
        '${probabilities.length} outputs for ${labels.length} labels',
      );
    }
    final ranked = [
      for (var i = 0; i < labels.length; i++)
        OfflineGuess(
          labels[i],
          probabilities[i].isFinite ? probabilities[i].clamp(0.0, 1.0) : 0.0,
        ),
    ]..sort((a, b) => b.probability.compareTo(a.probability));
    final best = ranked.first;
    if (best.probability < OfflineModel.minConfidence) {
      return OfflineReading(OfflineVerdict.unclear, const [], best: best);
    }
    if (best.key == healthy) {
      return OfflineReading(OfflineVerdict.healthy, [best], best: best);
    }
    if (!diseases.contains(best.key)) {
      return OfflineReading(OfflineVerdict.unclear, const [], best: best);
    }
    return OfflineReading(OfflineVerdict.disease, [
      best,
      if (ranked.skip(1).firstOrNull case final second?
          when diseases.contains(second.key) &&
              second.probability >= OfflineModel.secondFrom)
        second,
    ], best: best);
  }
}
