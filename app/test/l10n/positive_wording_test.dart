import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Owner rule: "Avoid negative statement". App text tells the grower what to do or what
/// is true. Only the keys below keep a negative, because there the negative is the point.
const allowNegative = {
  // Banned ingredient: "do not use it" is the safety instruction itself.
  'sprayWarnBannedBody',
  // CIB&RC label info: the explicit "not a recommendation" disclaimer stays.
  'labelInfoBanner',
  // Consent text: says plainly that this consent cannot be switched off here.
  'profileConsentDataNote',
  // Privacy promise: the pasted text is not stored on the phone.
  'feedCheckPrivacy',
  // Forwarded-message check: "no official match found" is the warning.
  'feedCheckNoMatch',
  // Claim PDF legal note: a grower's record, not an insurer's document.
  'claimPdfMade',
};

final _negative = <String, RegExp>{
  'en': RegExp(r'\bno\s|\bnot\s|cannot', caseSensitive: false),
  'mr': RegExp('नाही|नका'),
  'hi': RegExp('नहीं'),
};

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  for (final MapEntry(key: locale, value: pattern) in _negative.entries) {
    test('$locale values avoid negative statements', () {
      final arb = _arb(locale);
      final found = [
        for (final MapEntry(:key, :value) in arb.entries)
          if (!key.startsWith('@') &&
              !allowNegative.contains(key) &&
              pattern.hasMatch(value as String))
            '$key: $value',
      ];
      expect(found, isEmpty, reason: 'negative wording in app_$locale.arb');
    });
  }

  test('every allow-listed key exists', () {
    final en = _arb('en');
    for (final k in allowNegative) {
      expect(en.containsKey(k), isTrue, reason: k);
    }
  });
}
