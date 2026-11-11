// Crop photo analysis (OPEN_QUESTIONS Q135, stage 3: the app). The farmer sends one photo of
// his own block; the server names up to three problems from the practice cards with a calm
// explanation (`POST /v1/plots/{plot_id}/photo-analysis`). Online only: nothing is queued.

/// What the photo shows; sent as the optional `part` field.
enum PhotoPart {
  leaf('leaf'),
  fruit('fruit'),
  trunk('trunk'),
  wholeTree('whole_tree');

  const PhotoPart(this.wire);
  final String wire;
}

/// The photo the phone sends: the server takes at most 2 MiB; about 1600 px on the long side
/// is plenty to see a spot on a leaf.
abstract final class PhotoLimits {
  static const maxSide = 1600;
  static const maxBytes = 2 * 1024 * 1024;
}

/// The candidate's confidence as a calm word ("जास्त शक्यता", "मध्यम", "कमी"), shown next to
/// the percentage. Display bands only; the server decides what it names.
enum Likelihood {
  high,
  medium,
  low;

  static const highFrom = 0.7;
  static const mediumFrom = 0.4;

  static Likelihood of(double confidence) => confidence >= highFrom
      ? high
      : confidence >= mediumFrom
      ? medium
      : low;
}

class PhotoCandidate {
  const PhotoCandidate({
    required this.key,
    required this.name,
    required this.confidence,
    required this.signs,
    required this.explanation,
  });

  /// A practice-card section key (canker, greening, ...), or [healthy] / [other].
  final String key;
  final Map<String, String> name;
  final double confidence;

  /// What the model saw in the photo, short phrases per language (`en`, `mr`, `hi`).
  final Map<String, List<String>> signs;
  final Map<String, String> explanation;

  static const healthy = 'healthy';
  static const other = 'other';

  String nameIn(String lang) => _pick(name, lang) ?? key;
  String explanationIn(String lang) => _pick(explanation, lang) ?? '';

  /// The seen signs in [lang]; the English ones only when that language has none
  /// (`english` is then true, so the screen can say so).
  ({List<String> signs, bool english}) signsIn(String lang) {
    List<String> clean(String l) => [
      for (final s in signs[l] ?? const <String>[])
        if (s.trim().isNotEmpty) s.trim(),
    ];
    final own = clean(lang);
    if (own.isNotEmpty || lang == 'en') return (signs: own, english: false);
    final en = clean('en');
    return (signs: en, english: en.isNotEmpty);
  }

  /// 0..100 for the screen.
  int get percent => (confidence.clamp(0, 1) * 100).round();

  static String? _pick(Map<String, String> m, String lang) {
    final v = m[lang];
    if (v != null && v.trim().isNotEmpty) return v;
    final en = m['en'];
    return en != null && en.trim().isNotEmpty ? en : null;
  }
}

class PhotoAnalysisResult {
  const PhotoAnalysisResult({
    required this.candidates,
    required this.unsure,
    required this.photoId,
  });

  /// At most three, most likely first.
  final List<PhotoCandidate> candidates;
  final bool unsure;

  /// The stored sample on the server; `DELETE /v1/photo-analysis/{photoId}` removes it.
  final String photoId;

  /// The photo looks healthy: the best (and sure) answer is `healthy`.
  bool get healthy =>
      !unsure &&
      candidates.isNotEmpty &&
      candidates.first.key == PhotoCandidate.healthy;
}

enum PhotoLimitKind { daily, monthly, total }

/// 429 `analysis_limit`: the plan's photos for the day / month are used (admin settings).
class PhotoLimitException implements Exception {
  const PhotoLimitException(this.kind, {this.max, this.resetsAt});

  final PhotoLimitKind kind;
  final int? max;

  /// UTC, from the server; shown in the phone's local time.
  final DateTime? resetsAt;

  @override
  String toString() => 'PhotoLimitException(${kind.name}, $max, $resetsAt)';
}

/// Why there is no answer, in the cases the farmer is told apart.
enum PhotoProblem {
  /// No network on the phone.
  offline,

  /// The server could not answer now (502, 5xx, timeout, block not on the server yet).
  failed,

  /// The server has photo analysis switched off (503).
  unavailable,

  /// This photo is not accepted (413 / 415 / 422): take another.
  refused,

  /// The session ended (401 / 403).
  signedOut,
}

class PhotoProblemException implements Exception {
  const PhotoProblemException(this.problem, [this.detail = '']);
  final PhotoProblem problem;
  final String detail;

  @override
  String toString() => 'PhotoProblemException(${problem.name} $detail)';
}

/// The picked file is not an image the phone can read.
class PhotoUnreadableException implements Exception {
  const PhotoUnreadableException();
}
