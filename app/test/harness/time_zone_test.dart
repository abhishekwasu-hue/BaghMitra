import 'package:flutter_test/flutter_test.dart';

/// Audit L11: goldens draw times with `toLocal()`; test/flutter_test_config.dart pins the
/// process time zone to UTC so they look the same on any machine (CI runs in UTC).
void main() {
  test('tests run in UTC whatever the machine time zone', () {
    expect(DateTime(2026, 10, 13, 6).timeZoneOffset, Duration.zero);
    expect(DateTime.utc(2026, 10, 13, 6).toLocal().hour, 6);
  });
}
