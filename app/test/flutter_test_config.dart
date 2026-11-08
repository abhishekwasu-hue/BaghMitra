import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pin_time_zone.dart';

/// Loads the real brand fonts (and Material icons) so golden images show actual glyphs
/// instead of the Ahem test font, and pins the time zone to UTC (audit L11).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  pinTimeZoneToUtc();
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await load('Baloo2', ['assets/fonts/Baloo2-Variable.ttf']);
  await load('Mukta', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
      'assets/fonts/Mukta-$w.ttf',
  ]);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final icons = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (flutterRoot != null && icons.existsSync()) {
    await load('MaterialIcons', [icons.path]);
  }
  await testMain();
}
