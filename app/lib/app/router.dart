import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../core/config.dart';
import '../features/accounts/presentation/accounts_screen.dart';
import '../features/accounts/presentation/add_entry_screens.dart';
import '../features/accounts/presentation/compare_screen.dart';
import '../features/auth/domain/auth.dart';
import '../features/auth/presentation/login_screens.dart';
import '../features/bahar/presentation/bahar_compare_screen.dart';
import '../features/bahar/presentation/bahar_screen.dart';
import '../features/bahar/presentation/start_bahar_screen.dart';
import '../features/calendar/presentation/season_calendar_screen.dart';
import '../features/dev/component_gallery_screen.dart';
import '../features/field_work/presentation/harvest_screen.dart';
import '../features/field_work/presentation/labour_screens.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/inputs/presentation/add_input_screens.dart';
import '../features/inputs/presentation/field_log_screen.dart';
import '../features/labels/presentation/label_info_screen.dart';
import '../features/market/presentation/market_prices_screen.dart';
import '../features/plots/presentation/add_plot_screen.dart';
import '../features/plots/presentation/boundary_screen.dart';
import '../features/plots/presentation/plot_detail_screen.dart';
import '../features/plots/presentation/plots_screen.dart';
import '../features/practices/presentation/practices_screen.dart';
import '../features/profile/presentation/onboarding_screen.dart';
import '../features/scouting/presentation/scouting_screens.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/spray/presentation/add_spray_screen.dart';
import '../features/spray/presentation/spray_log_screen.dart';
import '../features/tasks/presentation/add_task_screen.dart';
import '../features/tasks/presentation/tasks_screen.dart';
import '../features/walkthrough/presentation/walkthrough_screen.dart';

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
  static const onboarding = '/onboarding';
  static const walkthrough = '/welcome';
  static const gallery = '/dev/gallery';
  static const settings = '/settings';
  static const tasks = '/tasks';
  static const addTask = '/tasks/new';
  static const calendar = '/calendar';
  static const market = '/market';
  static const practices = '/practices';
  static const plots = '/plots';
  static const addPlot = '/plots/new';
  static const walkBoundary = '/plots/new/boundary';
  static String plot(String plotId) => '/plots/$plotId';
  static String editPlot(String plotId) => '/plots/$plotId/edit';
  static String plotBahar(String plotId) => '/plots/$plotId/bahar';
  static String startBahar(String plotId) => '/plots/$plotId/bahar/new';
  static String compareBahars(String plotId) => '/plots/$plotId/bahar/compare';
  static String sprays(String plotId) => '/plots/$plotId/sprays';
  static String addSpray(String plotId) => '/plots/$plotId/sprays/new';
  static String labels(String plotId) => '/plots/$plotId/labels';
  static String labour(String plotId) => '/plots/$plotId/labour';
  static String addLabour(String plotId) => '/plots/$plotId/labour/new';
  static String harvest(String plotId) => '/plots/$plotId/harvest';
  static String addHarvest(String plotId) => '/plots/$plotId/harvest/new';
  static String scouting(String plotId) => '/plots/$plotId/scouting';
  static String addScouting(String plotId) => '/plots/$plotId/scouting/new';
  static String fieldLog(String plotId) => '/plots/$plotId/log';
  static String addInput(String plotId) => '/plots/$plotId/log/input';
  static String addIrrigation(String plotId) => '/plots/$plotId/log/irrigation';
  static String accounts(String plotId) => '/plots/$plotId/accounts';
  static String compare(String plotId) => '/plots/$plotId/compare';
  static String addExpense(String plotId) => '/plots/$plotId/accounts/expense';
  static String addSale(String plotId) => '/plots/$plotId/accounts/sale';
}

GoRouter buildRouter(
  AuthRepository auth,
  AppConfig config, {
  String? initialLocation,
  ValueListenable<bool?>? onboarded,
  ValueListenable<bool?>? walkthroughSeen,
}) {
  final refresh = _AuthListenable(auth.sessions());
  return GoRouter(
    initialLocation: initialLocation ?? Routes.home,
    refreshListenable: Listenable.merge([
      refresh,
      ?onboarded,
      ?walkthroughSeen,
    ]),
    redirect: (context, state) {
      final signedIn = auth.current != null;
      final loc = state.matchedLocation;
      final onLogin = loc.startsWith(Routes.login);
      if (loc == Routes.gallery) return config.devGallery ? null : Routes.home;
      if (loc == Routes.settings && !config.isTestBuild && !config.devGallery) {
        return Routes.home;
      }
      // First run on this phone: the short walkthrough comes before anything else. Once seen
      // it stays reachable (settings opens it again); unknown (still loading) waits.
      final onWalkthrough = loc == Routes.walkthrough;
      if (walkthroughSeen?.value == false && !onWalkthrough) {
        return Routes.walkthrough;
      }
      if (onWalkthrough) return null;
      if (!signedIn && !onLogin) return Routes.login;
      if (signedIn && onLogin) return Routes.home;
      // Signed in but not set up yet: finish onboarding first. Unknown (still loading) waits.
      final done = onboarded?.value;
      final onOnboarding = loc == Routes.onboarding;
      if (signedIn && done == false && !onOnboarding) return Routes.onboarding;
      if (signedIn && done == true && onOnboarding) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: Routes.walkthrough,
        builder: (_, _) => const WalkthroughScreen(),
      ),
      GoRoute(
        path: Routes.calendar,
        builder: (_, _) => const SeasonCalendarScreen(),
      ),
      GoRoute(
        path: Routes.market,
        builder: (_, _) => const MarketPricesScreen(),
      ),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(path: Routes.tasks, builder: (_, _) => const TasksScreen()),
      GoRoute(path: Routes.addTask, builder: (_, _) => const AddTaskScreen()),
      GoRoute(path: Routes.plots, builder: (_, _) => const PlotsScreen()),
      GoRoute(
        path: Routes.practices,
        builder: (_, _) => const PracticesScreen(),
      ),
      GoRoute(path: Routes.addPlot, builder: (_, _) => const AddPlotScreen()),
      GoRoute(
        path: Routes.walkBoundary,
        builder: (_, _) => const BoundaryScreen(),
      ),
      GoRoute(
        path: '/plots/:id',
        builder: (_, s) => PlotDetailScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/edit',
        builder: (_, s) => AddPlotScreen(plotId: s.pathParameters['id']),
      ),
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
        path: '/plots/:id/labels',
        builder: (_, s) => LabelInfoScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/labour',
        builder: (_, s) => LabourScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/labour/new',
        builder: (_, s) => AddLabourScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/harvest',
        builder: (_, s) => HarvestScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/harvest/new',
        builder: (_, s) => AddHarvestScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/scouting',
        builder: (_, s) => ScoutingScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/scouting/new',
        builder: (_, s) => AddScoutingScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/log',
        builder: (_, s) => FieldLogScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/log/input',
        builder: (_, s) => AddInputScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/log/irrigation',
        builder: (_, s) => AddIrrigationScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/accounts',
        builder: (_, s) => AccountsScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/compare',
        builder: (_, s) => CompareScreen(plotId: s.pathParameters['id']!),
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
      GoRoute(
        path: '/plots/:id/bahar/compare',
        builder: (_, s) => BaharCompareScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
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
