import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin/admin_app.dart';
import 'admin/admin_auth.dart';
import 'admin/kb_admin_repository.dart';
import 'api/api_client.dart';
import 'core/config.dart';

/// Admin web entrypoint: flutter run -d chrome -t lib/main_admin.dart
/// (with SUPABASE_URL, SUPABASE_ANON_KEY and API_BASE_URL defines).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
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
    ),
  );
}
