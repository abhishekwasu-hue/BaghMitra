import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/config.dart';
import '../features/accounts/presentation/accounts_screen.dart';
import '../features/accounts/presentation/add_entry_screens.dart';
import '../features/auth/domain/auth.dart';
import '../features/auth/presentation/login_screens.dart';
import '../features/bahar/presentation/bahar_screen.dart';
import '../features/bahar/presentation/start_bahar_screen.dart';
import '../features/dev/component_gallery_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/plots/presentation/add_plot_screen.dart';
import '../features/plots/presentation/plots_screen.dart';
import '../features/spray/presentation/add_spray_screen.dart';
import '../features/spray/presentation/spray_log_screen.dart';

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Stream<AuthSession?> sessions) {
    _sub = sessions.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthSession?> _sub;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}

abstract final class Routes {
  static const home = '/';
  static const login = '/login';
  static const otp = '/login/otp';
  static const gallery = '/dev/gallery';
  static const plots = '/plots';
  static const addPlot = '/plots/new';
  static String plotBahar(String plotId) => '/plots/$plotId/bahar';
  static String startBahar(String plotId) => '/plots/$plotId/bahar/new';
  static String sprays(String plotId) => '/plots/$plotId/sprays';
  static String addSpray(String plotId) => '/plots/$plotId/sprays/new';
  static String accounts(String plotId) => '/plots/$plotId/accounts';
  static String addExpense(String plotId) => '/plots/$plotId/accounts/expense';
  static String addSale(String plotId) => '/plots/$plotId/accounts/sale';
}

GoRouter buildRouter(
  AuthRepository auth,
  AppConfig config, {
  String? initialLocation,
}) {
  final refresh = _AuthListenable(auth.sessions());
  return GoRouter(
    initialLocation: initialLocation ?? Routes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = auth.current != null;
      final loc = state.matchedLocation;
      final onLogin = loc.startsWith(Routes.login);
      if (loc == Routes.gallery) return config.devGallery ? null : Routes.home;
      if (!signedIn && !onLogin) return Routes.login;
      if (signedIn && onLogin) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(path: Routes.plots, builder: (_, _) => const PlotsScreen()),
      GoRoute(path: Routes.addPlot, builder: (_, _) => const AddPlotScreen()),
      GoRoute(
        path: '/plots/:id/bahar',
        builder: (_, s) => BaharScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/sprays',
        builder: (_, s) => SprayLogScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/sprays/new',
        builder: (_, s) => AddSprayScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/accounts',
        builder: (_, s) => AccountsScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/accounts/expense',
        builder: (_, s) => AddExpenseScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/accounts/sale',
        builder: (_, s) => AddSaleScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/bahar/new',
        builder: (_, s) => StartBaharScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(path: Routes.login, builder: (_, _) => const PhoneLoginScreen()),
      GoRoute(
        path: Routes.otp,
        builder: (_, state) =>
            OtpScreen(phone: state.uri.queryParameters['phone'] ?? ''),
      ),
      GoRoute(
        path: Routes.gallery,
        builder: (_, _) => const ComponentGalleryScreen(),
      ),
    ],
  );
}
