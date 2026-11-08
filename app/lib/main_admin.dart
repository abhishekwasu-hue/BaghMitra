import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin/admin_app.dart';
import 'admin/admin_auth.dart';
import 'admin/admin_web_config.dart';
import 'admin/billing_admin_repository.dart';
import 'admin/feed_admin_repository.dart';
import 'admin/kb_admin_repository.dart';
import 'admin/market_link_admin_repository.dart';
import 'admin/market_link_safety_admin.dart';
import 'admin/package_admin_repository.dart';
import 'api/api_client.dart';
import 'core/config.dart';

/// Admin web entrypoint: flutter run -d chrome -t lib/main_admin.dart
/// (with SUPABASE_URL, SUPABASE_ANON_KEY and API_BASE_URL defines). The production build is
/// served by the API at /admin/ and reads those values from /admin/config.json instead
/// (docs/runbooks/admin-web.md).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final client = http.Client();
  final config = await resolveAdminConfig(
    AppConfig.fromEnvironment(),
    isWeb: kIsWeb,
    pageUri: Uri.base,
    client: client,
  );
  client.close();
  if (config.demoMode) {
    // No backend: the KB sections explain that admin sign-in needs Supabase.
    runApp(AdminApp(productName: config.productName));
    return;
  }
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabaseAnonKey,
  );
  final auth = SupabaseAdminAuth(Supabase.instance.client);
  final api = createApi(
    baseUrl: Uri.parse(config.apiBaseUrl),
    token: () => auth.accessToken,
  );
  runApp(
    AdminApp(
      productName: config.productName,
      auth: auth,
      kb: ApiKbAdminRepository(api),
      feed: ApiFeedAdminRepository(api),
      // Legal gate (decision j): no market linkage section unless MARKET_LINK is on.
      marketLink: config.marketLink ? ApiMarketLinkAdminRepository(api) : null,
      safety: config.marketLink ? ApiMarketLinkSafetyAdmin(api) : null,
      package: config.marketLink ? ApiPackageAdminRepository(api) : null,
      billing: ApiBillingAdminRepository(api),
    ),
  );
}
