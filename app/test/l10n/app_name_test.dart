import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The product name is localized (BagMitra / बागमित्र). The Android launcher label lives in
/// res/values*/strings.xml and must match appName in the ARB of the same language.
void main() {
  String arbName(String lang) =>
      (jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
              as Map<String, dynamic>)['appName']
          as String;

  String androidName(String dir) {
    final xml = File('android/app/src/main/res/$dir/strings.xml')
        .readAsStringSync();
    return RegExp(r'<string name="app_name">([^<]+)</string>')
        .firstMatch(xml)!
        .group(1)!;
  }

  test('product name per language', () {
    expect(arbName('en'), 'BagMitra');
    expect(arbName('mr'), 'बागमित्र');
    expect(arbName('hi'), 'बागमित्र');
  });

  test('Android launcher labels match the ARB names', () {
    expect(androidName('values'), arbName('en'));
    expect(androidName('values-mr'), arbName('mr'));
    expect(androidName('values-hi'), arbName('hi'));
  });
}
