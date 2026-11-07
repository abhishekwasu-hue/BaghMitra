import 'package:bagmitra/api/generated/bagmitra.swagger.dart';
import 'package:bagmitra/core/config.dart';
import 'package:bagmitra/features/market_link/safety/safety_photo.dart';
import 'package:bagmitra/features/market_link/safety/safety_repository.dart';
import 'package:bagmitra/features/market_link/safety/safety_screens.dart';
import 'package:bagmitra/l10n/app_localizations.dart';
import 'package:bagmitra/l10n/app_localizations_en.dart';
import 'package:bagmitra/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/pump_app.dart';
import '../plots/plots_screen_test.dart' show settle;

const marketLinkConfig = AppConfig(
  productName: 'BagMitra',
  apiBaseUrl: 'http://localhost:8000',
  supabaseUrl: '',
  supabaseAnonKey: '',
  devGallery: true,
  testBuild: '',
  speechEngine: 'on_device',
  marketLink: true,
);

AccountActionOut action(
  String id,
  String act,
  String reason, {
  String state = 'none',
  String? appealReason,
}) => AccountActionOut(
  id: id,
  subjectType: 'buyer',
  subjectId: 'b1',
  action: act,
  reasonCode: reason,
  actedAt: DateTime.utc(2026, 11, 3, 10),
  appealState: state,
  appealReason: appealReason,
  appealPhotoCount: 0,
  appealedAt: null,
  appealDecidedAt: null,
  canAppeal: state == 'none' && act != 'verify' && act != 'restore',
);

/// Records every call; [fail] makes the next write throw (network down).
class FakeSafety implements SafetyRepository {
  FakeSafety({List<AccountActionOut>? actions}) : actions = actions ?? [];
  final List<AccountActionOut> actions;
  final calls = <String>[];
  final blocked = <String>{};
  bool fail = false;

  void _maybeFail() {
    if (fail) throw const SafetyException(503);
  }

  @override
  Future<void> report(
    String subjectType,
    String subjectId,
    String reason, {
    List<int>? photo,
  }) async {
    _maybeFail();
    calls.add('report $subjectType $subjectId $reason ${photo?.length}');
  }

  @override
  Future<Set<String>> blockedUsers() async => blocked;

  @override
  Future<void> setBlocked(String userId, {required bool blocked}) async {
    _maybeFail();
    calls.add('${blocked ? 'block' : 'unblock'} $userId');
    blocked ? this.blocked.add(userId) : this.blocked.remove(userId);
  }

  @override
  Future<List<AccountActionOut>> myActions() async => actions;

  @override
  Future<void> appeal(
    String actionId,
    String reason, {
    List<int>? photo,
  }) async {
    _maybeFail();
    calls.add('appeal $actionId $reason ${photo?.length}');
    final i = actions.indexWhere((a) => a.id == actionId);
    actions[i] = action(
      actionId,
      actions[i].action,
      actions[i].reasonCode,
      state: 'appealed',
      appealReason: reason,
    );
  }
}

Future<void> pumpSafety(
  WidgetTester tester,
  FakeSafety fake, {
  required String location,
  AppConfig config = marketLinkConfig,
  ThemeMode themeMode = ThemeMode.light,
  Locale locale = const Locale('mr'),
  Size size = const Size(360, 780),
  GrievanceOfficer? officer,
}) async {
  await pumpApp(
    tester,
    locale: locale,
    themeMode: themeMode,
    size: size,
    config: config,
    initialLocation: location,
    overrides: [
      safetyRepositoryProvider.overrideWithValue(fake),
      safetyPhotoProvider.overrideWithValue(() async => [0xff, 0xd8, 0xff]),
      grievanceOfficerProvider.overrideWith((ref) async => officer),
    ],
  );
  await settle(tester);
}

void main() {
  final en = AppLocalizationsEn();

  testWidgets(
    'report: reason chips, optional photo, one main action, no text field',
    (tester) async {
      final fake = FakeSafety();
      await pumpSafety(
        tester,
        fake,
        location: '/market-link/report/lot/lot-1',
        locale: const Locale('en'),
      );
      expect(find.byType(TextField), findsNothing);
      for (final r in reportReasons) {
        expect(find.byKey(ValueKey('reason-$r')), findsOneWidget);
      }
      final send = find.byKey(const ValueKey('safety-send'));
      expect(tester.widget<FilledButton>(send).onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('reason-fake_lot')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('safety-photo')));
      await settle(tester);
      expect(find.text(en.mlSafetyPhotoAdded), findsOneWidget);
      await tester.tap(send);
      await settle(tester);
      expect(fake.calls, ['report lot lot-1 fake_lot 3']);
      expect(find.text(en.mlSafetySent), findsOneWidget);
      await unmountApp(tester);
    },
  );

  testWidgets('a failed report keeps the screen and says to retry', (
    tester,
  ) async {
    final fake = FakeSafety()..fail = true;
    await pumpSafety(
      tester,
      fake,
      location: '/market-link/report/buyer/b1',
      locale: const Locale('en'),
    );
    await tester.tap(find.byKey(const ValueKey('reason-abuse')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('safety-send')));
    await settle(tester);
    expect(find.text(en.mlSafetyRetry), findsOneWidget);
    expect(find.byKey(const ValueKey('safety-send')), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('with the flag off the safety screens are unreachable', (
    tester,
  ) async {
    await pumpSafety(
      tester,
      FakeSafety(),
      location: '/market-link/report/lot/lot-1',
      config: testConfig,
    );
    expect(find.byType(ReportScreen), findsNothing);
    await unmountApp(tester);
  });

  testWidgets(
    'profile menu: block with a confirm, unblock; report button opens the form',
    (tester) async {
      final fake = FakeSafety();
      var changed = 0;
      var blocked = false;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => StatefulBuilder(
              builder: (context, setState) => Scaffold(
                appBar: AppBar(
                  actions: [
                    ProfileSafetyMenu(
                      subjectType: 'broker',
                      subjectId: 'br1',
                      userId: 'u-broker',
                      blocked: blocked,
                      onChanged: () => setState(() {
                        changed++;
                        blocked = !blocked;
                      }),
                    ),
                  ],
                ),
                body: const ReportButton(
                  subjectType: 'broker',
                  subjectId: 'br1',
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/market-link/report/:type/:id',
            builder: (_, s) => ReportScreen(
              subjectType: s.pathParameters['type']!,
              subjectId: s.pathParameters['id']!,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [safetyRepositoryProvider.overrideWithValue(fake)],
          child: MaterialApp.router(
            routerConfig: router,
            theme: BmTheme.light(),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.mlBlock));
      await tester.pumpAndSettle();
      expect(find.text(en.mlBlockNote), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, en.mlBlock));
      await tester.pumpAndSettle();
      expect(fake.calls, ['block u-broker']);
      expect(changed, 1);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.mlUnblock));
      await tester.pumpAndSettle();
      expect(fake.calls.last, 'unblock u-broker');
      await tester.tap(find.text(en.mlSafetyReport));
      await tester.pumpAndSettle();
      expect(find.byType(ReportScreen), findsOneWidget);
    },
  );
}
