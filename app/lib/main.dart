import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/app_log.dart';
import 'core/config.dart';
import 'features/auth/data/demo_auth_repository.dart';
import 'features/auth/domain/auth.dart';
import 'features/auth/infra/supabase_auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final dir = await getApplicationSupportDirectory();
  final log = FileAppLog(File('${dir.path}/bagmitra.log'))
    ..log(
      'start ${config.productName} test=${config.testBuild} demo=${config.demoMode}',
    );
  FlutterError.onError = (d) =>
      log.log('flutter error: ${d.exceptionAsString()}\n${d.stack}');
  PlatformDispatcher.instance.onError = (Object e, StackTrace st) {
    log.log('error: $e\n$st');
    return true;
  };
  final AuthRepository auth;
  if (config.demoMode) {
    auth = DemoAuthRepository();
  } else {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
    );
    auth = SupabaseAuthRepository(Supabase.instance.client);
  }
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        authRepositoryProvider.overrideWithValue(auth),
        appLogProvider.overrideWithValue(log),
      ],
      child: const BagMitraApp(),
    ),
  );
}
