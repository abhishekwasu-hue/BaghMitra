import 'package:bagmitra/features/app_update/data/app_update_providers.dart';
import 'package:bagmitra/features/app_update/domain/app_update.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

const _release = AppRelease(
  latestCode: 12,
  latestName: '1.2.0',
  minCode: 8,
  downloadUrl: 'https://api.example.test/app',
);

void main() {
  for (final (name, need) in [
    ('update_banner_mr_light', UpdateNeed.available),
    ('update_required_mr_light', UpdateNeed.required),
  ]) {
    testWidgets(name, (tester) async {
      await pumpApp(
        tester,
        overrides: [
          appUpdateProvider.overrideWith(
            (ref) async => AppUpdateState(need, _release),
          ),
        ],
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$name.png'),
      );
      await unmountApp(tester);
    });
  }
}
