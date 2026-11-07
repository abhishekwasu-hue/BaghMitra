import 'package:bagmitra/core/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'market linkage is off unless the build sets MARKET_LINK (decision j)',
    () {
      expect(AppConfig.fromEnvironment().marketLink, isFalse);
      const config = AppConfig(
        productName: 'BagMitra',
        apiBaseUrl: 'http://localhost',
        supabaseUrl: '',
        supabaseAnonKey: '',
        devGallery: false,
        testBuild: '',
        speechEngine: 'on_device',
      );
      expect(config.marketLink, isFalse);
    },
  );
}
