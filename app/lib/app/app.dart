import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../sync/account_guard.dart';
import '../theme/app_theme.dart';
import 'providers.dart';
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

  late final GoRouter _router = buildRouter(
    ref.read(authRepositoryProvider),
    ref.read(appConfigProvider),
    initialLocation: widget.initialLocation,
    onboarded: _onboarded,
    walkthroughSeen: _walkthroughSeen,
    accountGate: _accountGate,
  );

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _router.dispose();
    _onboarded.dispose();
    _walkthroughSeen.dispose();
    _accountGate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(reminderSyncProvider);
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
    );
  }
}
