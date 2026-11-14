import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Owner (2026-11-13): "records are safe / saved on the phone / sent when the network comes"
/// belongs once in the privacy policy, never repeated on screens. Audit:
/// docs/design/reassurance-audit.md.
const removedKeys = {
  'offlineBanner',
  'syncServerBanner',
  'pendingSync',
  'reactionPending',
  'feedbackQueued',
  'claimKitLocalOnly',
  'labTestReportLocal',
  'billPhotoHint',
  'feedCheckPrivacy',
};

/// Kept although they mention the phone or later sending: each is a one-time consent or
/// dialog fact, an action to take, or a line the owner is to decide on (audit table).
const allowed = {
  'localModeBanner',
  'syncFailed',
  'profileSignOutBody',
  'walkthroughRecordsBody',
  'syncRejectedHelp',
};

final _reassurance = <String, RegExp>{
  'mr': RegExp(
    'फोनवर[^.;]{0,12}(सुरक्षित|जतन|ठेवले)'
    '|(या|याच) फोनवर(च)? (राहते|राहतो|राहतात|राहतील)'
    '|(नेट|इंटरनेट|नेटवर्क|सर्व्हर)[^.;]{0,20}(आल्यावर|तयार)[^.;]{0,30}'
    '(पाठवल्या|पाठवली|जाईल|जातील|जातात)'
    '|फोनवर साठवला',
  ),
  'en': RegExp(
    r'(saved|safe|kept|stays?) (on|with)[^.;]{0,25}phone'
    r'|(will|it) (sync|be sent|goes) (when|once)',
    caseSensitive: false,
  ),
  'hi': RegExp(
    'फ़ोन पर[^।;]{0,12}(सुरक्षित|सहेज|रखा)'
    '|इसी फ़ोन पर (रहता|रहती|रहते)'
    '|(नेटवर्क|इंटरनेट|सर्वर)[^।;]{0,20}(आने|तैयार)[^।;]{0,30}(भेजी|जाएगा|जाएँगी)',
  ),
};

/// Owner (2026-11-14): no line that vouches for the content ("checked", "verified", "written
/// by AI from checked sources", "every number checked"). BagMitra gives no guarantee that its
/// information is checked. Market-link keys (`ml*`) are exempt: "checked trader" there is the
/// real verification status of a trader, a feature. Admin keys (`admin*`) are never shown to
/// growers.
const removedGuaranteeKeys = {
  'feedKnowledgeByline',
  'feedArticleByline',
  'askStoredNote',
};

/// Kept although they use the word: each is an instruction to the reader or an honest
/// "still to be checked" status, not a claim that the content was checked.
const allowedGuarantee = {
  // "Get it checked by a lab or an expert before you decide" (instruction).
  'lookalikesCheckLine',
  // "Draft: a source is still to be checked" (status of an unfinished card).
  'lookalikesDraft',
};

final _guarantee = <String, RegExp>{
  'mr': RegExp(
    'तपासले|सत्यापित|पडताळलेल|AI ने|प्रत्येक आकडा स्रोताशी|अचूक माहिती',
  ),
  'en': RegExp(
    r'\bchecked\b|verified|fact-?checked|written by AI|by AI\b|accurate information',
    caseSensitive: false,
  ),
  // "जाँचें" (please check) is an instruction; "जाँचे / जाँची / जाँचा" (checked) is not.
  'hi': RegExp(
    'जाँचे(?!ं)|जाँची|जाँचा|सत्यापित|AI द्वारा|हर संख्या स्रोत|सटीक जानकारी',
  ),
};

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  for (final MapEntry(key: locale, value: pattern) in _reassurance.entries) {
    test('$locale: no repeated "saved on the phone / sent later" lines', () {
      final arb = _arb(locale);
      for (final k in removedKeys) {
        expect(arb.containsKey(k), isFalse, reason: 'app_$locale.arb: $k');
      }
      final found = [
        for (final MapEntry(:key, :value) in arb.entries)
          if (!key.startsWith('@') &&
              !allowed.contains(key) &&
              value is String &&
              pattern.hasMatch(value))
            '$key: $value',
      ];
      expect(found, isEmpty, reason: 'reassurance wording in app_$locale.arb');
    });
  }

  for (final MapEntry(key: locale, value: pattern) in _guarantee.entries) {
    test(
      '$locale: no "checked / verified / written by AI" guarantee lines',
      () {
        final arb = _arb(locale);
        for (final k in removedGuaranteeKeys) {
          expect(arb.containsKey(k), isFalse, reason: 'app_$locale.arb: $k');
        }
        final found = [
          for (final MapEntry(:key, :value) in arb.entries)
            if (!key.startsWith('@') &&
                !key.startsWith('ml') &&
                !key.startsWith('admin') &&
                !allowedGuarantee.contains(key) &&
                value is String &&
                pattern.hasMatch(value))
              '$key: $value',
        ];
        expect(found, isEmpty, reason: 'guarantee wording in app_$locale.arb');
      },
    );
  }

  test('every allowed key exists', () {
    final mr = _arb('mr');
    for (final k in {...allowed, ...allowedGuarantee}) {
      expect(mr.containsKey(k), isTrue, reason: k);
    }
  });
}
