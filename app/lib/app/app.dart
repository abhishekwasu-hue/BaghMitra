import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/app_update/presentation/app_update_gate.dart';
import '../features/feedback/data/feedback_providers.dart';
import '../features/market_link/data/market_link_providers.dart';
import '../features/market_link/domain/market_link.dart';
import '../features/reactions/data/reaction_providers.dart';
import '../l10n/app_localizations.dart';
import '../sync/account_guard.dart';
import '../theme/app_theme.dart';
import 'providers.dart';
import 'refresh.dart';
import 'router.dart';

class BagMitraApp extends ConsumerStatefulWidget {
  const BagMitraApp({
    super.key,
    this.locale,
    this.initialLocation,
    this.themeMode,
  });

  /// Forced locale (tests, user preference). Null follows the device, falling back to English.
  final Locale? locale;
  final String? initialLocation;
  final ThemeMode? themeMode;

  @override
  ConsumerState<BagMitraApp> createState() => _BagMitraAppState();
}

class _BagMitraAppState extends ConsumerState<BagMitraApp> {
  /// What the router knows about onboarding; null while that is still loading.
  final _onboarded = ValueNotifier<bool?>(null);

  /// Whether the first-run walkthrough was seen; null while loading. A read error counts as
  /// seen, so a broken flag never keeps the grower out of the app.
  final _walkthroughSeen = ValueNotifier<bool?>(null);

  /// Whose records the phone holds for the signed-in account; null while checking.
  final _accountGate = ValueNotifier<AccountCheck?>(null);

  /// The market-link role whose home `/` opens (flag MARKET_LINK only); null: the grower app.
  final _marketRole = ValueNotifier<MarketRole?>(null);

  /// Reloads weather, prices and feed (when old) and syncs when the app comes back.
  late final AppLifecycleListener _lifecycle;

  late final GoRouter _router = buildRouter(
    ref.read(authRepositoryProvider),
    ref.read(appConfigProvider),
    initialLocation: widget.initialLocation,
    onboarded: _onboarded,
    walkthroughSeen: _walkthroughSeen,
    accountGate: _accountGate,
    marketRole: _marketRole,
  );

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(refresherProvider).onResume(),
    );
    // Sync runs from the app root once the records are this account's, not only while the
    // home screen is open, so a returning grower's records arrive before onboarding (LG-05).
    ref.listenManual(syncEngineProvider, (_, _) {}, fireImmediately: true);
    // Purchases left from a killed app or another phone reach the server (billing §2.3).
    // Feedback written offline goes once the app starts online.
    ref.listenManual(feedbackStartupProvider, (_, _) {}, fireImmediately: true);
    // Reactions tapped offline go the same way (Q146).
    ref.listenManual(reactionStartupProvider, (_, _) {}, fireImmediately: true);
    ref.listenManual(
      subscriptionStartupProvider,
      (_, _) {},
      fireImmediately: true,
    );
    ref.listenManual(
      onboardedProvider,
      (_, done) => _onboarded.value = done,
      fireImmediately: true,
    );
    ref.listenManual(
      walkthroughSeenProvider,
      (_, seen) => _walkthroughSeen.value = switch (seen) {
        AsyncData(:final value) => value,
        AsyncError() => true,
        _ => null,
      },
      fireImmediately: true,
    );
    // A read error counts as the same account, so a broken check never locks the grower out.
    ref.listenManual(
      accountGateProvider,
      (_, gate) => _accountGate.value = switch (gate) {
        AsyncValue(isLoading: true) => null,
        AsyncData(:final value) => value,
        AsyncError() => AccountCheck.same,
        _ => null,
      },
      fireImmediately: true,
    );
    if (ref.read(appConfigProvider).marketLink) {
      ref.listenManual(
        activeMarketRoleProvider,
        (_, role) => _marketRole.value = role.value,
        fireImmediately: true,
      );
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _router.dispose();
    _onboarded.dispose();
    _walkthroughSeen.dispose();
    _accountGate.dispose();
    _marketRole.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(reminderSyncProvider);
    ref.watch(pushRegistrationProvider);
    // A forced locale wins (tests); otherwise the language being picked, then the saved one.
    final language =
        ref.watch(languagePreviewProvider) ??
        ref.watch(profileProvider).value?.language;
    final chosen = AppLocalizations.supportedLocales
        .where((l) => l.languageCode == language)
        .firstOrNull;
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: BmTheme.light(),
      darkTheme: BmTheme.dark(),
      themeMode: widget.themeMode ?? ThemeMode.system,
      locale: widget.locale ?? chosen,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: (device, supported) {
        for (final l in supported) {
          if (l.languageCode == device?.languageCode) return l;
        }
        return const Locale('en');
      },
      routerConfig: _router,
      // Update notice / blocking screen above every route (audit BG-06).
      builder: (context, child) =>
          AppUpdateGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
