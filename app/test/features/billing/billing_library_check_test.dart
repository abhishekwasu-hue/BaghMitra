import 'package:flutter_test/flutter_test.dart';

import '../../../tool/check_billing_library.dart';

void main() {
  test(
    'reads the Billing Library major version from the plugin Gradle file',
    () {
      expect(
        billingMajors(
          'implementation("com.android.billingclient:billing:9.1.0")',
        ),
        [9],
      );
      expect(
        billingMajors(
          "implementation 'com.android.billingclient:billing-ktx:7.0.0'",
        ),
        [7],
      );
      expect(
        billingMajors('implementation("androidx.core:core:1.0.0")'),
        isEmpty,
      );
    },
  );
}
