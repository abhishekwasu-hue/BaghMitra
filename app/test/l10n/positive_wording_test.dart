import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Owner rule: "Avoid negative statement". App text tells the grower what to do or what
/// is true. Only the keys below keep a negative, because there the negative is the point.
const allowNegative = {
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
  // Label screen (owner Q57): "no registered label claim for this target" is the fact the
  // owner asked to show plainly.
  'labelInfoNoClaim',
  // Market link (owner's disclaimer, spec v1.5 §1 / §5): what BagMitra is not and does not
  // do is the legal point; and the fixed safety notice "never asks for money, OTP or bank
  // details" (§4C).
  'mlTermsNotParty',
  'mlTermsNoMoney',
  'mlTermsNoGainLoss',
  'mlTermsNoPart',
  'mlSafetyNotice',
  // No negative: "वजनकाटा" (weighbridge, owner's word) happens to contain "नका".
  'mlRoleProviderKinds',
  // Market linkage admin: the plain "No" answer to a yes / no field (refrigerated).
  'adminMlNo',
  // वजनकाटा (weighbridge, GLOSSARY_mr.md) only contains the letters of नका.
  'adminMlKindWeighbridge',
  // Market linkage disclaimer (decision k): "BagMitra is not a buyer, seller, ..." is the
  // statement the owner asked for.
  'mlDisclaimerShort',
  // Spec v1.5 §4E names this exact status: "Package active until <date>" or "Not active".
  'mlPackageNotActive',
  // The lot is hidden from traders while the package is not active (§4E); said plainly.
  'mlPackageHiddenNow',
  // False match, not a negative: "वजनकाटा" (weighbridge, GLOSSARY_mr.md) contains "नका".
  'mlKindWeighbridge',
  'mlDocCertificate',
  'mlServicesEmpty',
  // Export record PDF footer (spec v1.5 §4A): an information record, not a certificate.
  'exportRecordFooter',
  // False match: "नकाशावर" (on the map) contains "नका".
  'mlIntroOpenMap',
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
