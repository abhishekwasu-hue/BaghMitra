/// The crops a question names (owner 2026-11-15): the stored questions and answers are for
/// santra and mosambi only, so a question about another crop ("बाजरी लागवडी संदर्भात सांगा")
/// must not get a citrus answer. The names come from config (assets/config/ask_crops.json,
/// crops.json, crop_guides.json); a word names a crop when it is one of its names, or a name
/// followed by a case ending ("बाजरीची", "कापसाचे", "kapsachi"). Names of several words
/// ("pearl millet", "sweet lime") match as a run of words.
library;

import 'qa_text.dart' show qaIsDevanagari, qaNormalise;

class AskCrop {
  const AskCrop({required this.slug, required this.labels, required this.qa});

  final String slug;
  final Map<String, String> labels;

  /// The stored questions and answers are for this crop (santra, mosambi).
  final bool qa;

  String label(String lang) => labels[lang] ?? labels['en'] ?? slug;
}

/// One crop's names before they are joined: [names] in any language and script.
typedef AskCropSource = ({
  String slug,
  Map<String, String> labels,
  Iterable<String> names,
});

final _word = RegExp('[ऀ-ॣ०-ॿa-z0-9]+');

List<String> _words(String text) => [
  for (final m in _word.allMatches(qaNormalise(text))) m.group(0)!,
];

class AskCrops {
  AskCrops({
    required Iterable<AskCropSource> crops,
    required Set<String> qaCrops,
    Iterable<String> ignoreNames = const [],
    Iterable<String> notCropPhrases = const [],
    Iterable<String> devanagariEndings = const [],
    Iterable<String> latinEndings = const [],
  }) : _devanagariEndings = {...devanagariEndings.map(qaNormalise)},
       _latinEndings = {...latinEndings.map(qaNormalise)},
       _notCrop = [
         for (final p in notCropPhrases)
           if (_words(p) case final w when w.isNotEmpty) w,
       ] {
    final ignored = {for (final n in ignoreNames) ..._words(n)};
    final seen = <String>{};
    for (final c in crops) {
      final crop = AskCrop(
        slug: c.slug,
        labels: c.labels,
        qa: qaCrops.contains(c.slug),
      );
      for (final name in c.names) {
        final words = _words(name);
        if (words.isEmpty ||
            (words.length == 1 && ignored.contains(words[0]))) {
          continue;
        }
        if (seen.add('${c.slug}|${words.join(' ')}')) _names.add((words, crop));
      }
    }
  }

  final _names = <(List<String>, AskCrop)>[];
  final Set<String> _devanagariEndings;
  final Set<String> _latinEndings;

  /// Phrases whose words name something else ("paddy husk", "भाताचे तूस").
  final List<List<String>> _notCrop;

  bool _sameWord(String word, String name) {
    if (word == name) return true;
    if (!word.startsWith(name)) return false;
    final rest = word.substring(name.length);
    return (qaIsDevanagari(name) ? _devanagariEndings : _latinEndings).contains(
      rest,
    );
  }

  /// Where [name] first starts in [words] at or after [from], or -1; [same] says whether
  /// the word at [words] index i is the name's word j.
  static int _find(
    List<String> words,
    List<String> name,
    bool Function(int i, int j) same, {
    int from = 0,
  }) {
    for (var i = from; i + name.length <= words.length; i++) {
      var match = true;
      for (var j = 0; j < name.length && match; j++) {
        match = same(i + j, j);
      }
      if (match) return i;
    }
    return -1;
  }

  /// The crops [text] names, in the order they appear, each once.
  List<AskCrop> namedIn(String text) {
    final words = _words(text);
    final blocked = <int>{};
    for (final p in _notCrop) {
      var from = 0;
      while (true) {
        final at = _find(words, p, (i, j) => words[i] == p[j], from: from);
        if (at < 0) break;
        blocked.addAll([for (var j = 0; j < p.length; j++) at + j]);
        from = at + p.length;
      }
    }
    final found = <(int, AskCrop)>[];
    for (final (name, crop) in _names) {
      final at = _find(
        words,
        name,
        // Only the last word of a name takes an ending.
        (i, j) =>
            !blocked.contains(i) &&
            (j == name.length - 1
                ? _sameWord(words[i], name[j])
                : words[i] == name[j]),
      );
      if (at >= 0) found.add((at, crop));
    }
    found.sort((a, b) => a.$1.compareTo(b.$1));
    final out = <AskCrop>[];
    for (final (_, crop) in found) {
      if (!out.any((c) => c.slug == crop.slug)) out.add(crop);
    }
    return out;
  }

  /// The crops [text] names that the stored answers are not for; empty when it names none,
  /// or names santra or mosambi too (a citrus question that also names another crop, e.g.
  /// an intercrop in the orchard, is answered as before).
  List<AskCrop> otherCropsIn(String text) {
    final named = namedIn(text);
    if (named.any((c) => c.qa)) return const [];
    return named;
  }
}
