/// Marathi and Hindi names for the mandi, state, commodity and variety strings the price
/// source (Agmarknet) sends in English. Display only: the API values are never changed, and a
/// name not listed here is shown exactly as the source wrote it. Spellings on the source side
/// follow the API settings and are still to be confirmed on the first live pull
/// (OPEN_QUESTIONS Q26 / Q27); a new spelling only needs a line here.
library;

typedef _Names = ({String mr, String hi});

const Map<String, _Names> _markets = {
  // Local APMCs of the santra belt.
  'kalamna': (mr: 'कळमना', hi: 'कलमना'),
  'warud': (mr: 'वरूड', hi: 'वरुड़'),
  'katol': (mr: 'काटोल', hi: 'काटोल'),
  'morshi': (mr: 'मोर्शी', hi: 'मोर्शी'),
  'amravati': (mr: 'अमरावती', hi: 'अमरावती'),
  // Major terminal markets.
  'azadpur': (mr: 'आझादपूर', hi: 'आज़ादपुर'),
  'mumbai': (mr: 'मुंबई', hi: 'मुंबई'),
  'pune': (mr: 'पुणे', hi: 'पुणे'),
  'nagpur': (mr: 'नागपूर', hi: 'नागपुर'),
  'bangalore': (mr: 'बंगळुरू', hi: 'बेंगलुरु'),
  'chennai': (mr: 'चेन्नई', hi: 'चेन्नई'),
  'hyderabad': (mr: 'हैदराबाद', hi: 'हैदराबाद'),
  'kolkata': (mr: 'कोलकाता', hi: 'कोलकाता'),
  'ahmedabad': (mr: 'अहमदाबाद', hi: 'अहमदाबाद'),
  'jaipur': (mr: 'जयपूर', hi: 'जयपुर'),
  'lucknow': (mr: 'लखनौ', hi: 'लखनऊ'),
  'indore': (mr: 'इंदूर', hi: 'इंदौर'),
};

const Map<String, _Names> _states = {
  'andhra pradesh': (mr: 'आंध्र प्रदेश', hi: 'आंध्र प्रदेश'),
  'assam': (mr: 'आसाम', hi: 'असम'),
  'bihar': (mr: 'बिहार', hi: 'बिहार'),
  'chattisgarh': (mr: 'छत्तीसगड', hi: 'छत्तीसगढ़'),
  'chhattisgarh': (mr: 'छत्तीसगड', hi: 'छत्तीसगढ़'),
  'delhi': (mr: 'दिल्ली', hi: 'दिल्ली'),
  'nct of delhi': (mr: 'दिल्ली', hi: 'दिल्ली'),
  'goa': (mr: 'गोवा', hi: 'गोवा'),
  'gujarat': (mr: 'गुजरात', hi: 'गुजरात'),
  'haryana': (mr: 'हरियाणा', hi: 'हरियाणा'),
  'himachal pradesh': (mr: 'हिमाचल प्रदेश', hi: 'हिमाचल प्रदेश'),
  'jammu and kashmir': (mr: 'जम्मू आणि काश्मीर', hi: 'जम्मू और कश्मीर'),
  'jharkhand': (mr: 'झारखंड', hi: 'झारखंड'),
  'karnataka': (mr: 'कर्नाटक', hi: 'कर्नाटक'),
  'kerala': (mr: 'केरळ', hi: 'केरल'),
  'madhya pradesh': (mr: 'मध्य प्रदेश', hi: 'मध्य प्रदेश'),
  'maharashtra': (mr: 'महाराष्ट्र', hi: 'महाराष्ट्र'),
  'odisha': (mr: 'ओडिशा', hi: 'ओडिशा'),
  'punjab': (mr: 'पंजाब', hi: 'पंजाब'),
  'rajasthan': (mr: 'राजस्थान', hi: 'राजस्थान'),
  'tamil nadu': (mr: 'तमिळनाडू', hi: 'तमिलनाडु'),
  'telangana': (mr: 'तेलंगणा', hi: 'तेलंगाना'),
  'tripura': (mr: 'त्रिपुरा', hi: 'त्रिपुरा'),
  'uttar pradesh': (mr: 'उत्तर प्रदेश', hi: 'उत्तर प्रदेश'),
  'uttarakhand': (mr: 'उत्तराखंड', hi: 'उत्तराखंड'),
  'west bengal': (mr: 'पश्चिम बंगाल', hi: 'पश्चिम बंगाल'),
};

const Map<String, _Names> _commodities = {
  'orange': (mr: 'संत्री', hi: 'संतरा'),
  'mousambi(sweet lime)': (mr: 'मोसंबी', hi: 'मौसमी'),
};

const Map<String, _Names> _varieties = {
  'nagpur': (mr: 'नागपुरी', hi: 'नागपुरी'),
  'nagpuri': (mr: 'नागपुरी', hi: 'नागपुरी'),
  'orange': (mr: 'संत्री', hi: 'संतरा'),
  'mousambi': (mr: 'मोसंबी', hi: 'मौसमी'),
  'other': (mr: 'इतर', hi: 'अन्य'),
};

String _label(Map<String, _Names> names, String source, String lang) {
  final n = names[source.trim().toLowerCase()];
  return switch (lang) {
    'mr' when n != null => n.mr,
    'hi' when n != null => n.hi,
    _ => source,
  };
}

/// A mandi's name in [lang]; the source text when it is not listed (or for English).
String marketLabel(String source, String lang) =>
    _label(_markets, source, lang);

/// A state's name in [lang]; the source text when it is not listed.
String marketStateLabel(String source, String lang) =>
    _label(_states, source, lang);

/// A commodity's name in [lang]; the source text when it is not listed.
String marketCommodityLabel(String source, String lang) =>
    _label(_commodities, source, lang);

/// A variety's name in [lang]; the source text when it is not listed.
String marketVarietyLabel(String source, String lang) =>
    _label(_varieties, source, lang);

/// Letters and digits in any script (Latin, Devanagari with its vowel signs); everything
/// else — "-", "(", ")", "." and spaces — separates words.
final _wordBreak = RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true);

/// "APMC" is in front of most Agmarknet mandi names, so it never decides a match.
const _ignoredWords = {'apmc'};

List<String> _words(String text) => [
  for (final w in text.toLowerCase().split(_wordBreak))
    if (w.isNotEmpty && !_ignoredWords.contains(w)) w,
];

/// The text a mandi row is found by: its mandi, district and state as the source wrote
/// them, plus the Marathi and Hindi names this file already knows for those words
/// (e.g. "APMC Nagpur" also reads "नागपूर" / "नागपुर"). Nothing is transliterated.
String marketSearchText({
  required String market,
  required String district,
  required String state,
}) {
  final words = <String>{};
  for (final source in [market, district]) {
    final whole = _markets[source.trim().toLowerCase()];
    if (whole != null) words.addAll(_words('${whole.mr} ${whole.hi}'));
    for (final w in _words(source)) {
      words.add(w);
      if (_markets[w] case final n?) words.addAll(_words('${n.mr} ${n.hi}'));
    }
  }
  words.addAll(_words(state));
  if (_states[state.trim().toLowerCase()] case final n?) {
    words.addAll(_words('${n.mr} ${n.hi}'));
  }
  return words.join(' ');
}

/// Whether every word the grower typed is part of [searchText] (from [marketSearchText]),
/// ignoring case and punctuation. An empty query matches every row.
bool marketSearchMatches(String searchText, String query) =>
    _words(query).every(searchText.contains);
