import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/features/market_link/data/package_status.dart';
import 'package:bagmitra/features/market_link/presentation/package_chip.dart';
import 'package:bagmitra/l10n/app_localizations.dart';
import 'package:bagmitra/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A status source that answers [status] (or throws when null).
class FixedPackageStatus implements PackageStatusSource {
  const FixedPackageStatus(this.status);
  final PackageStatus? status;

  @override
  Future<PackageStatus> load() async => status ?? (throw Exception('offline'));
}

Future<void> _pump(
  WidgetTester tester,
  PackageStatus? status, {
  String lot = 'l1',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        packageStatusSourceProvider.overrideWithValue(
          FixedPackageStatus(status),
        ),
      ],
      child: MaterialApp(
        theme: BmTheme.light(),
        locale: const Locale('mr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: PackageChip(lot)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final until = DateTime.utc(2026, 12, 31, 6);

  testWidgets('active lot: package until <date>', (tester) async {
    await _pump(tester, PackageStatus(switchOn: true, covers: {'l1': until}));
    expect(find.textContaining('पर्यंत चालू'), findsOneWidget);
    expect(find.textContaining('पॅकेज'), findsOneWidget);
  });

  testWidgets('an all-lots package covers every lot', (tester) async {
    await _pump(
      tester,
      PackageStatus(switchOn: true, covers: {null: until}),
      lot: 'other',
    );
    expect(find.textContaining('पर्यंत चालू'), findsOneWidget);
  });

  testWidgets('no package: not active', (tester) async {
    await _pump(tester, const PackageStatus(switchOn: true));
    expect(find.text('पॅकेज चालू नाही'), findsOneWidget);
  });

  testWidgets('switch OFF or offline: no chip', (tester) async {
    for (final status in [
      PackageStatus(switchOn: false, covers: {'l1': until}),
      null,
    ]) {
      await _pump(tester, status);
      expect(find.byKey(const Key('package-l1')), findsNothing);
    }
  });

  test('the later end date wins', () {
    final status = PackageStatus(
      switchOn: true,
      covers: {'l1': until, null: until.add(const Duration(days: 3))},
    );
    expect(status.untilFor('l1'), until.add(const Duration(days: 3)));
    expect(status.untilFor('l9'), until.add(const Duration(days: 3)));
    expect(const PackageStatus(switchOn: true).untilFor('l1'), isNull);
  });

  test('the HTTP source reads switch and end dates only', () async {
    Future<PackageStatus> load(int code, String body) =>
        HttpPackageStatusSource(
          createApi(
            baseUrl: Uri.parse('https://api.example.test'),
            token: () => 'tok',
            httpClient: MockClient(
              (req) async => http.Response(
                body,
                code,
                headers: {'content-type': 'application/json'},
              ),
            ),
          ),
        ).load();
    final status = await load(
      200,
      '{"switch_on": true, "active": ['
      '{"lot_id": "l1", "valid_until": "2026-12-01T00:00:00Z"},'
      '{"lot_id": "l1", "valid_until": "2026-12-31T00:00:00Z"},'
      '{"lot_id": null, "valid_until": "2026-12-10T00:00:00Z"}]}',
    );
    expect(status.switchOn, isTrue);
    expect(status.untilFor('l1'), DateTime.utc(2026, 12, 31));
    expect(status.untilFor('l2'), DateTime.utc(2026, 12, 10));
    expect((await load(404, '{}')).switchOn, isFalse);
  });
}
