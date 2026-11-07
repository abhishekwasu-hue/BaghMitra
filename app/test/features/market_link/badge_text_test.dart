import 'package:bagmitra/features/market_link/domain/registration.dart';
import 'package:bagmitra/features/market_link/presentation/profile_widgets.dart';
import 'package:bagmitra/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Every badge kind the API sends has its own text (L7, spec §4); a kind this app
/// version does not know never reads as a place photo.
void main() {
  setUpAll(() => initializeDateFormatting('en'));
  final t = AppLocalizationsEn();
  final on = DateTime.utc(2026, 11, 7);
  String text(String kind, {int? year}) =>
      badgeText(t, ProfileBadge(kind, on, sinceYear: year), 'en');

  test('per-check badges say what was checked', () {
    expect(text('gst_checked'), startsWith('GST checked on'));
    expect(text('gst_checked', year: 2016), endsWith('registered since 2016'));
    expect(text('apmc_seen'), startsWith('APMC licence seen'));
    expect(text('fssai_checked'), startsWith('FSSAI checked'));
    expect(text('iec_active'), startsWith('IEC active'));
    expect(text('apeda_listed'), startsWith('APEDA listed'));
    expect(text('place_photo'), startsWith('Place photo'));
  });

  test('an unknown kind is not shown as a place photo', () {
    expect(text('something_new'), startsWith('Checked by BagMitra'));
  });

  test('since_year is read from the API json', () {
    final b = ProfileBadge.fromJson({
      'kind': 'gst_checked',
      'on': '2026-11-07',
      'place': null,
      'since_year': 2016,
    });
    expect(b.sinceYear, 2016);
  });
}
