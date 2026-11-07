import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../core/config.dart';
import '../features/accounts/presentation/accounts_screen.dart';
import '../features/accounts/presentation/add_entry_screens.dart';
import '../features/accounts/presentation/compare_screen.dart';
import '../features/auth/domain/auth.dart';
import '../features/auth/presentation/account_switch_screen.dart';
import '../features/auth/presentation/login_screens.dart';
import '../features/bahar/presentation/bahar_compare_screen.dart';
import '../features/bahar/presentation/bahar_screen.dart';
import '../features/bahar/presentation/start_bahar_screen.dart';
import '../features/calendar/presentation/season_calendar_screen.dart';
import '../features/dev/component_gallery_screen.dart';
import '../features/directory/presentation/directory_screen.dart';
import '../features/export_info/presentation/export_info_screen.dart';
import '../features/export_info/presentation/export_record_screen.dart';
import '../features/feed/presentation/feed_check_screen.dart';
import '../features/feed/presentation/feed_preferences_screen.dart';
import '../features/feed/presentation/feed_screen.dart';
import '../features/field_work/presentation/harvest_screen.dart';
import '../features/field_work/presentation/labour_screens.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/inputs/presentation/add_input_screens.dart';
import '../features/inputs/presentation/field_log_screen.dart';
import '../features/insurance/presentation/claim_kit_screen.dart';
import '../features/insurance/presentation/insurance_screens.dart';
import '../features/knowledge/presentation/knowledge_cards_screen.dart';
import '../features/lab_tests/presentation/lab_test_screens.dart';
import '../features/labels/presentation/label_info_screen.dart';
import '../features/lookalikes/presentation/lookalikes_screen.dart';
import '../features/market/presentation/market_prices_screen.dart';
import '../features/market_link/domain/market_link.dart';
import '../features/market_link/domain/market_link_role.dart';
import '../features/market_link/domain/registration.dart';
import '../features/market_link/presentation/introduction_screen.dart';
import '../features/market_link/presentation/lot_form_screen.dart';
import '../features/market_link/presentation/lot_offers_screen.dart';
import '../features/market_link/presentation/my_lots_screen.dart';
import '../features/market_link/presentation/my_profiles_screen.dart';
import '../features/market_link/presentation/offer_screens.dart';
import '../features/market_link/presentation/people_screen.dart';
import '../features/market_link/presentation/rating_screen.dart';
import '../features/market_link/presentation/registration_screen.dart';
import '../features/market_link/presentation/role_home_screen.dart';
import '../features/market_link/presentation/role_picker_screen.dart';
import '../features/market_link/presentation/services_screen.dart';
import '../features/market_link/presentation/terms_acceptance_screen.dart';
import '../features/more/presentation/more_screen.dart';
import '../features/plots/presentation/add_plot_screen.dart';
import '../features/plots/presentation/boundary_screen.dart';
import '../features/plots/presentation/plot_detail_screen.dart';
import '../features/plots/presentation/plots_screen.dart';
import '../features/practices/presentation/irrigation_guide_screen.dart';
import '../features/practices/presentation/practices_screen.dart';
import '../features/profile/presentation/onboarding_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/schemes/presentation/scheme_screens.dart';
import '../features/scouting/presentation/scouting_screens.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/spray/presentation/add_spray_screen.dart';
import '../features/spray/presentation/spray_log_screen.dart';
import '../features/tasks/presentation/add_task_screen.dart';
import '../features/tasks/presentation/tasks_screen.dart';
import '../features/walkthrough/presentation/walkthrough_screen.dart';
import '../sync/account_guard.dart';
import 'app_shell.dart';

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
  static const accountSwitch = '/account-switch';
  static const walkthrough = '/welcome';
  static const gallery = '/dev/gallery';
  static const settings = '/settings';
  static const profile = '/profile';
  static const tasks = '/tasks';
  static const addTask = '/tasks/new';
  static const calendar = '/calendar';
  static const market = '/market';
  static const feed = '/feed';
  static String feedItem(String itemId) => '/feed/$itemId';
  static const feedSettings = '/feed-settings';
  static const feedCheck = '/feed-check';
  static const practices = '/practices';

  /// The विचारा tab: the practices guide inside the tab shell. Tabs ([home], [plots],
  /// [ask]) are opened with `go`, never pushed.
  static const ask = '/ask';

  /// "All features": an entry to every screen (audit H1).
  static const more = '/more';
  static const irrigation = '/irrigation';
  static const knowledge = '/knowledge';
  static String knowledgeTopic(String topic) =>
      '$knowledge?topic=${Uri.encodeQueryComponent(topic)}';
  static const lookalikes = '/lookalikes';
  static String lookalikesFor(String? plotId) =>
      plotId == null ? lookalikes : '$lookalikes?plot=$plotId';
  static const labs = '/labs';
  static const marketDirectory = '/market/directory';
  // Market linkage (L2), behind AppConfig.marketLink (decision j).
  static const marketLink = '/market-link';
  static const marketLinkMine = '/market-link/me';
  static const marketLinkPeople = '/market-link/people';
  static String marketLinkProfile(String type, String id) =>
      '/market-link/profile/$type/$id';
  static const marketLinkServices = '/market-link/services';
  static String marketLinkRegister(String role) =>
      '/market-link/register/$role';
  static const exportInfo = '/market/export';
  static const exportRecord = '/market/export/record';
  static const marketLots = '$marketLink/lots';
  static String newMarketLot({String? plotId}) =>
      '$marketLots/new${plotId == null ? '' : '?plot=$plotId'}';
  static String marketLot(String lotId) => '$marketLots/$lotId';
  static String marketLotOffers(String lotId) => '$marketLots/$lotId/offers';

  /// Traders' and brokers' side (L4): published lots, an offer on one, own offers.
  static const marketBrowse = '$marketLink/market';
  static String marketOffer(String lotId) => '$marketBrowse/$lotId/offer';
  static const marketMyOffers = '$marketLink/offers';

  /// The introduction (contacts) after an acceptance, opened as the grower or the trader.
  static String marketIntro(String dealId, {bool asGrower = false}) =>
      '$marketLink/deals/$dealId${asGrower ? '?as=grower' : ''}';

  /// Rating after both tapped "deal done" (L5), as the grower or the trader / broker.
  static String marketRate(String dealId, {bool asGrower = false}) =>
      '$marketLink/deals/$dealId/rate${asGrower ? '?as=grower' : ''}';

  /// Market link (flag MARKET_LINK only): the five role cards, a role's own home, and the
  /// terms screen pushed by `ensureMarketRoleAccepted` (it returns true when accepted).
  static const roles = '/roles';
  static String roleHome(MarketRole role) => '$roles/${role.name}';
  static String roleTerms(MarketRole role) => '$roles/${role.name}/terms';
  static const plots = '/plots';
  static const addPlot = '/plots/new';
  static const walkBoundary = '/plots/new/boundary';
  static String plot(String plotId) => '/plots/$plotId';
  static String editPlot(String plotId) => '/plots/$plotId/edit';
  static String plotBahar(String plotId) => '/plots/$plotId/bahar';
  static String startBahar(String plotId) => '/plots/$plotId/bahar/new';
  static String compareBahars(String plotId) => '/plots/$plotId/bahar/compare';
  static String irrigationGuide(String plotId) =>
      '/plots/$plotId/irrigation-guide';
  static String sprays(String plotId) => '/plots/$plotId/sprays';
  static String addSpray(String plotId) => '/plots/$plotId/sprays/new';
  static String labels(String plotId, {String? target}) =>
      '/plots/$plotId/labels${target == null ? '' : '?target=$target'}';

  /// Label information without a block (practices, look-alikes): crop and target chosen.
  static const labelsAll = '/labels';
  static String labelsFor({String? plotId, String? crop, String? target}) {
    if (plotId != null) return labels(plotId, target: target);
    final q = {'crop': ?crop, 'target': ?target};
    return Uri(
      path: labelsAll,
      queryParameters: q.isEmpty ? null : q,
    ).toString();
  }

  static String labour(String plotId) => '/plots/$plotId/labour';
  static String addLabour(String plotId) => '/plots/$plotId/labour/new';
  static String harvest(String plotId) => '/plots/$plotId/harvest';
  static String addHarvest(String plotId) => '/plots/$plotId/harvest/new';
  static String scouting(String plotId) => '/plots/$plotId/scouting';
  static String addScouting(String plotId, {String? item}) =>
      '/plots/$plotId/scouting/new${item == null ? '' : '?item=$item'}';
  static String insurance(String plotId) => '/plots/$plotId/insurance';
  static String addPolicy(String plotId) => '/plots/$plotId/insurance/new';
  static String editPolicy(String plotId, String policyId) =>
      '/plots/$plotId/insurance/$policyId';
  static String labTests(String plotId) => '/plots/$plotId/lab-tests';
  static String addLabTest(String plotId) => '/plots/$plotId/lab-tests/new';
  static String labTest(String plotId, String testId) =>
      '/plots/$plotId/lab-tests/$testId';
  static String editLabTest(String plotId, String testId) =>
      '/plots/$plotId/lab-tests/$testId/edit';
  static const schemes = '/schemes';
  static String scheme(String schemeId) => '$schemes/$schemeId';
  static const claimKit = '/claim-kit';
  static String newClaimKit([String? plotId]) =>
      plotId == null ? claimKit : '$claimKit?plot=$plotId';
  static String openClaimKit(String claimId) => '$claimKit/$claimId';
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
  ValueListenable<AccountCheck?>? accountGate,
  ValueListenable<MarketRole?>? marketRole,
}) {
  final refresh = _AuthListenable(auth.sessions());
  return GoRouter(
    initialLocation: initialLocation ?? Routes.home,
    refreshListenable: Listenable.merge([
      refresh,
      ?onboarded,
      ?walkthroughSeen,
      ?accountGate,
      ?marketRole,
    ]),
    redirect: (context, state) {
      final signedIn = auth.current != null;
      final loc = state.matchedLocation;
      final onLogin = loc.startsWith(Routes.login);
      if (loc == Routes.gallery) return config.devGallery ? null : Routes.home;
      if (loc.startsWith(Routes.feed) && !config.sarkariSandeshEnabled) {
        return Routes.home;
      }
      // Market-link screens exist only in builds with the flag on (spec v1.5 §5, decision j).
      if ((loc.startsWith(Routes.marketLink) ||
              loc.startsWith(Routes.exportInfo)) &&
          !config.marketLink) {
        return Routes.home;
      }
      // First run on this phone: the short walkthrough comes before anything else. Once seen
      // it stays reachable (settings opens it again); unknown (still loading) waits.
      final onWalkthrough = loc == Routes.walkthrough;
      if (walkthroughSeen?.value == false && !onWalkthrough) {
        return Routes.walkthrough;
      }
      if (onWalkthrough) return null;
      // Market link (spec v1.5 §2.1, Q86): signed out, the five role cards come first and the
      // card leads to the same sign-in. Without the flag no role screen exists.
      final onRoles = loc.startsWith(Routes.roles);
      if (onRoles && !config.marketLink) return Routes.home;
      if (!signedIn && !onLogin) {
        if (!config.marketLink) return Routes.login;
        return loc == Routes.roles ? null : Routes.roles;
      }
      // Another account's records on the phone (Q36): warn (or block) before anything of
      // them shows. Unknown (still checking) waits where it is, so a sign-in stays on the
      // login screen until the check is done.
      final gate = accountGate == null ? AccountCheck.same : accountGate.value;
      final onSwitch = loc == Routes.accountSwitch;
      if (signedIn &&
          (gate == AccountCheck.switchable || gate == AccountCheck.blocked)) {
        return onSwitch ? null : Routes.accountSwitch;
      }
      if (signedIn && gate == null) return null;
      if (onSwitch) return Routes.home;
      if (signedIn && onLogin) return Routes.home;
      // Signed in but not set up yet: finish onboarding first. Unknown (still loading) waits.
      final done = onboarded?.value;
      final onOnboarding = loc == Routes.onboarding;
      if (signedIn && done == false && !onOnboarding) return Routes.onboarding;
      if (signedIn && done == true && onOnboarding) return Routes.home;
      // The chosen role's own home opens at `/`; the grower role is the grower app itself.
      final role = config.marketLink ? marketRole?.value : null;
      if (loc == Routes.home && role != null && role != MarketRole.grower) {
        return Routes.roleHome(role);
      }
      return null;
    },
    routes: [
      // The three tabs of the bottom bar (audit M3); every other page opens above them.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.plots,
                builder: (_, _) => const PlotsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.ask,
                builder: (_, _) => const PracticesScreen(),
              ),
            ],
          ),
        ],
      ),
      // The same guide opened from a page (a block, a scouting record): above the tabs,
      // with a back arrow to that page. A tab route cannot be pushed on top of the shell.
      GoRoute(
        path: Routes.practices,
        builder: (_, _) => const PracticesScreen(),
      ),
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
      GoRoute(path: Routes.feed, builder: (_, _) => const FeedScreen()),
      GoRoute(
        path: Routes.feedSettings,
        builder: (_, _) => const FeedPreferencesScreen(),
      ),
      GoRoute(
        path: Routes.feedCheck,
        builder: (_, _) => const FeedCheckScreen(),
      ),
      GoRoute(
        path: '/feed/:id',
        builder: (_, s) => FeedItemScreen(itemId: s.pathParameters['id']!),
      ),
      GoRoute(path: Routes.more, builder: (_, _) => const MoreScreen()),
      GoRoute(path: Routes.marketLots, builder: (_, _) => const MyLotsScreen()),
      GoRoute(
        path: '${Routes.marketLots}/new',
        builder: (_, s) => LotFormScreen(plotId: s.uri.queryParameters['plot']),
      ),
      GoRoute(
        path: '${Routes.marketLots}/:lotId',
        builder: (_, s) => LotFormScreen(lotId: s.pathParameters['lotId']),
      ),
      GoRoute(
        path: '${Routes.marketLots}/:lotId/offers',
        builder: (_, s) => LotOffersScreen(
          lotId: s.pathParameters['lotId']!,
          onIntroduced: (context, dealId) =>
              context.push(Routes.marketIntro(dealId, asGrower: true)),
        ),
      ),
      GoRoute(
        path: '${Routes.marketLink}/deals/:dealId',
        builder: (_, s) => IntroductionScreen(
          dealId: s.pathParameters['dealId']!,
          role: s.uri.queryParameters['as'] == 'grower'
              ? MarketLinkRole.grower
              : MarketLinkRole.trader,
        ),
      ),
      GoRoute(
        path: '${Routes.marketLink}/deals/:dealId/rate',
        builder: (_, s) => RatingScreen(
          dealId: s.pathParameters['dealId']!,
          role: s.uri.queryParameters['as'] == 'grower'
              ? MarketLinkRole.grower
              : MarketLinkRole.trader,
        ),
      ),
      GoRoute(
        path: Routes.marketBrowse,
        builder: (_, _) => const BrowseLotsScreen(),
      ),
      GoRoute(
        path: '${Routes.marketBrowse}/:lotId/offer',
        builder: (_, s) =>
            SendInterestScreen(lotId: s.pathParameters['lotId']!),
      ),
      GoRoute(
        path: Routes.marketMyOffers,
        builder: (_, _) => const MyInterestsScreen(),
      ),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen()),
      GoRoute(
        path: Routes.accountSwitch,
        builder: (_, _) => const AccountSwitchScreen(),
      ),
      GoRoute(path: Routes.tasks, builder: (_, _) => const TasksScreen()),
      GoRoute(path: Routes.addTask, builder: (_, _) => const AddTaskScreen()),
      GoRoute(
        path: Routes.irrigation,
        builder: (_, _) => const IrrigationGuideScreen(),
      ),
      GoRoute(
        path: Routes.knowledge,
        builder: (_, s) =>
            KnowledgeCardsScreen(topic: s.uri.queryParameters['topic']),
      ),
      GoRoute(
        path: Routes.lookalikes,
        builder: (_, s) =>
            LookalikesScreen(plotId: s.uri.queryParameters['plot']),
      ),
      GoRoute(path: Routes.labs, builder: (_, _) => const LabDirectoryScreen()),
      GoRoute(
        path: Routes.marketDirectory,
        builder: (_, _) => const MarketDirectoryScreen(),
      ),
      GoRoute(
        path: Routes.marketLinkMine,
        builder: (_, _) => const MyProfilesScreen(),
      ),
      GoRoute(
        path: '/market-link/register/:role',
        redirect: (_, s) =>
            RegistrationRole.fromName(s.pathParameters['role']) == null
            ? Routes.marketLinkMine
            : null,
        builder: (_, s) => RegistrationScreen(
          role: RegistrationRole.fromName(s.pathParameters['role'])!,
        ),
      ),
      GoRoute(
        path: Routes.marketLinkPeople,
        builder: (_, _) => const PeopleScreen(),
      ),
      GoRoute(
        path: '/market-link/profile/:type/:id',
        builder: (_, s) => ProfileDetailScreen(
          subjectType: s.pathParameters['type']!,
          id: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: Routes.marketLinkServices,
        builder: (_, _) => const ServicesScreen(),
      ),
      GoRoute(
        path: Routes.exportInfo,
        builder: (_, _) => const ExportInfoScreen(),
      ),
      GoRoute(
        path: Routes.exportRecord,
        builder: (_, _) => const ExportRecordScreen(),
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
        builder: (_, s) => LabelInfoScreen(
          plotId: s.pathParameters['id'],
          target: s.uri.queryParameters['target'],
        ),
      ),
      GoRoute(
        path: Routes.labelsAll,
        builder: (_, s) => LabelInfoScreen(
          crop: s.uri.queryParameters['crop'],
          target: s.uri.queryParameters['target'],
        ),
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
        builder: (_, s) => AddScoutingScreen(
          plotId: s.pathParameters['id']!,
          initialItem: s.uri.queryParameters['item'],
        ),
      ),
      GoRoute(
        path: '/plots/:id/insurance',
        builder: (_, s) => InsuranceScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/insurance/new',
        builder: (_, s) => PolicyFormScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/insurance/:policyId',
        builder: (_, s) => PolicyFormScreen(
          plotId: s.pathParameters['id']!,
          policyId: s.pathParameters['policyId'],
        ),
      ),
      GoRoute(
        path: '/plots/:id/lab-tests',
        builder: (_, s) => LabTestsScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/lab-tests/new',
        builder: (_, s) => LabTestFormScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plots/:id/lab-tests/:testId',
        builder: (_, s) => LabTestDetailScreen(
          plotId: s.pathParameters['id']!,
          testId: s.pathParameters['testId']!,
        ),
      ),
      GoRoute(
        path: '/plots/:id/lab-tests/:testId/edit',
        builder: (_, s) => LabTestFormScreen(
          plotId: s.pathParameters['id']!,
          testId: s.pathParameters['testId'],
        ),
      ),
      GoRoute(path: Routes.schemes, builder: (_, _) => const SchemesScreen()),
      GoRoute(
        path: '${Routes.schemes}/:schemeId',
        builder: (_, s) =>
            SchemeDetailScreen(schemeId: s.pathParameters['schemeId']!),
      ),
      GoRoute(
        path: Routes.claimKit,
        builder: (_, s) =>
            ClaimKitScreen(plotId: s.uri.queryParameters['plot']),
      ),
      GoRoute(
        path: '${Routes.claimKit}/:claimId',
        builder: (_, s) => ClaimKitScreen(claimId: s.pathParameters['claimId']),
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
        path: '/plots/:id/irrigation-guide',
        builder: (_, s) =>
            IrrigationGuideScreen(plotId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      // Before `/roles/:role`, so the terms page is not read as a role home.
      GoRoute(
        path: '${Routes.roles}/:role/terms',
        redirect: (_, s) => _role(s) == null ? Routes.roles : null,
        builder: (_, s) => TermsAcceptanceScreen(role: _role(s)!),
      ),
      GoRoute(path: Routes.roles, builder: (_, _) => const RolePickerScreen()),
      // The grower's home is the grower app itself.
      GoRoute(
        path: '${Routes.roles}/:role',
        redirect: (_, s) => switch (_role(s)) {
          null => Routes.roles,
          MarketRole.grower => Routes.home,
          _ => null,
        },
        builder: (_, s) => RoleHomeScreen(role: _role(s)!),
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

MarketRole? _role(GoRouterState s) =>
    MarketRole.fromName(s.pathParameters['role']);
