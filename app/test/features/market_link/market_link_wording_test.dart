import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

/// Market-link wording rules (spec v1.5 §2.1, §4; GLOSSARY_mr.md).
void main() {
  for (final locale in ['en', 'mr', 'hi']) {
    test('$locale: badges and market-link text never promise a guarantee', () {
      final arb = _arb(locale);
      final ml = {
        for (final e in arb.entries)
          if (e.key.startsWith('ml')) e.key: e.value as String,
      };
      expect(ml.keys, containsAll(['mlBadgeChecked', 'mlBadgePlacePhoto']));
      final bad = RegExp(
        'guarantee|guaranteed|हमी|गारंटी|खात्रीशीर',
        caseSensitive: false,
      );
      // The disclaimers (decision k, L1 terms) say BagMitra gives NO guarantee: the only keys
      // that may name the word.
      const statesNoGuarantee = {'mlDisclaimerShort', 'mlTermsNoMoney'};
      expect([
        for (final e in ml.entries)
          if (bad.hasMatch(e.value) && !statesNoGuarantee.contains(e.key))
            e.key,
      ], isEmpty);
      // Badges say what was checked and when.
      for (final k in [
        'mlBadgeChecked',
        'mlBadgePlacePhoto',
        'mlBadgeGstChecked',
        'mlBadgeGstSince',
        'mlBadgeApmcSeen',
        'mlBadgeFssaiChecked',
        'mlBadgeIecActive',
        'mlBadgeApedaListed',
      ]) {
        expect(ml[k], contains('{date}'), reason: k);
      }
    });
  }

  test('mr: "मध्यस्थ (दलाल)" and "व्यवहार"; never "अडत्या" or "सौदा"', () {
    final mr = {
      for (final e in _arb('mr').entries)
        if (e.key.startsWith('ml')) e.key: e.value as String,
    };
    expect(mr['mlRoleBroker'], 'मध्यस्थ (दलाल)');
    expect(mr['mlSortDeals'], contains('व्यवहार'));
    expect([
      for (final e in mr.entries)
        if (e.value.contains('अडत्या') || e.value.contains('सौदा')) e.key,
    ], isEmpty);
  });

  test('no Aadhaar wording anywhere in market-link text', () {
    for (final locale in ['en', 'mr', 'hi']) {
      final values = [
        for (final e in _arb(locale).entries)
          if (e.key.startsWith('ml')) e.value as String,
      ];
      expect(
        values.where(
          (v) => RegExp('aadhaar|आधार', caseSensitive: false).hasMatch(v),
        ),
        isEmpty,
      );
    }
  });
}
