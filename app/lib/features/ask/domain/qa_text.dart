/// Search keys for the offline questions and answers (owner 2026-11-12, Q144): the SAME rules
/// as the generator (`api/src/bagmitra_api/kb/qa_text.py`); a shared fixture
/// (`test/fixtures/qa_normalise_cases.json`) and a word-list test keep them equal.
/// 1. lower case, Devanagari digits to ASCII, nukta removed, chandrabindu as anusvara,
///    zero-width joiners dropped;
/// 2. words are runs of Devanagari letters / marks, Latin letters and digits;
/// 3. common question words and particles are dropped;
/// 4. one common case ending is cut ("फळगळीसाठी" -> "फळगळी", "rogachi" -> "roga") when at
///    least four characters stay;
/// 5. every word also gets a sound key: its consonants in a coarse Latin form, vowels and "y"
///    dropped ("फळगळ", "falgal", "phalgal" -> "plgl"; "सायला", "sayla" -> "sl").
library;

const qaStopwords = <String>{
  // Marathi
  'काय',
  'कसे',
  'कशी',
  'कसा',
  'कसं',
  'कोणते',
  'कोणता',
  'कोणती',
  'कोणत्या',
  'केव्हा',
  'कधी',
  'किती',
  'का',
  'की',
  'आहे',
  'आहेत',
  'असते',
  'असतो',
  'असेल',
  'होते',
  'होतो',
  'करावे',
  'करावा',
  'करावी',
  'करायचे',
  'करू',
  'मी',
  'माझ्या',
  'माझे',
  'माझा',
  'माझी',
  'आमच्या',
  'आम्ही',
  'तर',
  'व',
  'आणि',
  'किंवा',
  'हे',
  'ही',
  'हा',
  'तो',
  'ती',
  'ते',
  'या',
  'त्या',
  'मध्ये',
  'साठी',
  'ला',
  'ने',
  'चा',
  'ची',
  'चे',
  'च्या',
  'वर',
  'न',
  'नाही', 'पण', 'म्हणजे', 'काही', 'सांगा', 'द्या', 'मला',
  // Hindi
  'क्या',
  'कैसे',
  'कैसी',
  'कब',
  'कौन',
  'कौनसा',
  'कितना',
  'कितनी',
  'है',
  'हैं',
  'में',
  'के', 'को', 'से', 'पर', 'और', 'मेरे', 'मेरा', 'मेरी', 'हम', 'करें',
  'करना', 'चाहिए', 'बताइए', 'बताओ', 'सा',
  // English and romanised question words
  'what',
  'how',
  'when',
  'which',
  'why',
  'is',
  'are',
  'the',
  'a',
  'an',
  'of',
  'in',
  'on',
  'for',
  'to',
  'do',
  'does',
  'i',
  'my',
  'and',
  'or',
  'should',
  'can',
  'it',
  'kay',
  'kase',
  'kashi',
  'kasa',
  'kevha',
  'kadhi',
  'kiti',
  'ahe',
  'aahe',
  'karave',
  'kya',
  'kaise',
  'kab',
  'hai',
  'me',
  'mein',
  'ka',
  'ki',
  'ke',
  'madhe',
  'madhye',
  'sathi',
  'la',
  'cha',
  'chi',
  'che',
  'ani',
  'kinva',
  'kon',
  'konte',
  'konti',
  'kontya',
};

/// Case endings cut once, longest first.
const qaSuffixes = <String>{
  'मध्ये', 'साठी', 'च्या', 'ांना', 'ांची', 'ांचा', 'ांचे', 'ाच्या', 'चा', 'ची',
  'चे', 'ला', 'ना', 'ने', 'नी', 'वर', 'ांत', 'ात', 'ों', 'ें', 'ाने',
  // romanised Marathi
  'sathi', 'madhye', 'madhe', 'chya', 'chi', 'cha', 'che',
};

const _minStem = 4;

final List<String> _suffixesLongestFirst = qaSuffixes.toList()
  ..sort((a, b) => b.length.compareTo(a.length));

/// Devanagari letters and marks (U+0900-U+0963, U+0966-U+097F; not the dandas), a-z, 0-9.
final _word = RegExp('[ऀ-ॣ०-ॿa-z0-9]+');
const _devanagariDigits = '०१२३४५६७८९';

const _devConsonants = {
  'क': 'k',
  'ख': 'k',
  'ग': 'g',
  'घ': 'g',
  'ङ': 'n',
  'च': 'c',
  'छ': 'c',
  'ज': 'j',
  'झ': 'j',
  'ञ': 'n',
  'ट': 't',
  'ठ': 't',
  'ड': 'd',
  'ढ': 'd',
  'ण': 'n',
  'त': 't',
  'थ': 't',
  'द': 'd',
  'ध': 'd',
  'न': 'n',
  'प': 'p',
  'फ': 'p',
  'ब': 'b',
  'भ': 'b',
  'म': 'm',
  'य': '',
  'र': 'r',
  'ऱ': 'r',
  'ल': 'l',
  'ळ': 'l',
  'व': 'v',
  'श': 's',
  'ष': 's',
  'स': 's',
  'ह': 'h',
  'ं': 'n',
};
const _latinPairs = [
  ('chh', 'c'),
  ('ch', 'c'),
  ('sh', 's'),
  ('kh', 'k'),
  ('gh', 'g'),
  ('jh', 'j'),
  ('th', 't'),
  ('dh', 'd'),
  ('ph', 'p'),
  ('bh', 'b'),
  ('ck', 'k'),
];
const _latinSingle = {'f': 'p', 'w': 'v', 'z': 'j', 'q': 'k', 'x': 'ks'};
const _latinVowels = {'a', 'e', 'i', 'o', 'u'};

String qaNormalise(String text) {
  final b = StringBuffer();
  for (final r in text.toLowerCase().runes) {
    final ch = String.fromCharCode(r);
    final digit = _devanagariDigits.indexOf(ch);
    if (digit >= 0) {
      b.write(digit);
    } else if (r == 0x093C || r == 0x200C || r == 0x200D) {
      continue; // nukta, zero-width non-joiner / joiner
    } else if (r == 0x0901) {
      b.write('ं'); // chandrabindu written as anusvara
    } else {
      b.write(ch);
    }
  }
  return b.toString();
}

String qaStem(String word) {
  for (final s in _suffixesLongestFirst) {
    if (word.endsWith(s) && word.length - s.length >= _minStem) {
      return word.substring(0, word.length - s.length);
    }
  }
  return word;
}

/// Normalised, stemmed words without stopwords, in order, without repeats.
List<String> qaWords(String text) {
  final out = <String>[];
  for (final m in _word.allMatches(qaNormalise(text))) {
    final raw = m.group(0)!;
    if (qaStopwords.contains(raw) || raw.length < 2) continue;
    final w = qaStem(raw);
    if (!out.contains(w)) out.add(w);
  }
  return out;
}

bool _isDigit(String ch) => ch.compareTo('0') >= 0 && ch.compareTo('9') <= 0;

String _latinSkeleton(String word) {
  final out = StringBuffer();
  var i = 0;
  while (i < word.length) {
    final pair = _latinPairs.where((p) => word.startsWith(p.$1, i)).firstOrNull;
    if (pair != null) {
      out.write(pair.$2);
      i += pair.$1.length;
      continue;
    }
    final ch = word[i];
    final next = i + 1 < word.length ? word[i + 1] : '';
    if (_latinVowels.contains(ch) || _isDigit(ch) || ch == 'y') {
      // vowels, digits and the glide "y" are never part of a key
    } else if (ch == 'c') {
      out.write(next == 'e' || next == 'i' || next == 'y' ? 's' : 'k');
    } else {
      out.write(_latinSingle[ch] ?? ch);
    }
    i++;
  }
  return out.toString();
}

/// The word's consonants in a coarse Latin form; repeats merged.
String qaSkeleton(String word) {
  final devanagari = word.runes.any((r) => r >= 0x0900 && r <= 0x097F);
  var raw = devanagari
      ? word.split('').map((ch) => _devConsonants[ch] ?? '').join()
      : _latinSkeleton(word);
  // A nasal before p / b sounds as m ("मोसंबी" = "mosambi").
  raw = raw.replaceAll('np', 'mp').replaceAll('nb', 'mb');
  final merged = StringBuffer();
  String? last;
  for (final ch in raw.split('')) {
    if (ch != last) merged.write(ch);
    last = ch;
  }
  return merged.toString();
}

/// Words of all [texts], then "~" + each word's sound key (two letters or more).
List<String> qaIndexKeys(Iterable<String> texts) {
  final found = <String>[];
  for (final t in texts) {
    for (final w in qaWords(t)) {
      if (!found.contains(w)) found.add(w);
    }
  }
  final keys = [...found];
  for (final w in found) {
    final s = qaSkeleton(w);
    if (s.length >= 2 && !keys.contains('~$s')) keys.add('~$s');
  }
  return keys;
}
