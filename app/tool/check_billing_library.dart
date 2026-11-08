// Google Play requires Billing Library 8 or later for new apps and updates (deadline
// 31 Aug 2026, extension to 1 Nov 2026; ADR 0008). Fails when the Billing Library that the
// resolved in_app_purchase_android plugin bundles is older than [min].
// Usage (after flutter pub get): dart run tool/check_billing_library.dart [min]
import 'dart:convert';
import 'dart:io';

final _billing = RegExp(
  r'com\.android\.billingclient:billing(?:-ktx)?:(\d+)\.',
);

/// Major versions of every Billing Library dependency in a Gradle file.
List<int> billingMajors(String gradle) => [
  for (final m in _billing.allMatches(gradle)) int.parse(m.group(1)!),
];

void main(List<String> args) {
  final min = args.isEmpty ? 8 : int.parse(args.first);
  final config = File('.dart_tool/package_config.json');
  if (!config.existsSync()) {
    stderr.writeln(
      '.dart_tool/package_config.json missing: run flutter pub get',
    );
    exit(2);
  }
  final packages =
      (jsonDecode(config.readAsStringSync()) as Map)['packages'] as List;
  final plugin = packages.cast<Map<String, dynamic>>().firstWhere(
    (p) => p['name'] == 'in_app_purchase_android',
    orElse: () => {},
  );
  if (plugin.isEmpty) {
    stderr.writeln('in_app_purchase_android is not a dependency');
    exit(2);
  }
  final root = Uri.parse(plugin['rootUri'] as String);
  final dir = Directory.fromUri(
    root.isAbsolute ? root : config.parent.uri.resolveUri(root),
  );
  final majors = [
    for (final name in ['build.gradle', 'build.gradle.kts'])
      if (File('${dir.path}/android/$name') case final f when f.existsSync())
        ...billingMajors(f.readAsStringSync()),
  ];
  if (majors.isEmpty) {
    stderr.writeln(
      'No Billing Library dependency found in ${dir.path}/android',
    );
    exit(1);
  }
  final low = majors.where((v) => v < min).toList();
  if (low.isNotEmpty) {
    stderr.writeln(
      'Play Billing Library $low is below $min (Google Play requirement)',
    );
    exit(1);
  }
  stdout.writeln('Play Billing Library $majors >= $min: ok');
}
