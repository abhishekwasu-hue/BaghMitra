import 'package:bagmitra/core/config.dart';
import 'package:bagmitra/core/formatting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);

  test('Indian lakh grouping and native digits per locale', () {
    expect(formatInt(125000, 'en'), '1,25,000');
    expect(formatInt(3200, 'mr'), '३,२००');
    expect(formatInt(3200, 'hi'), '3,200');
    expect(formatRupees(3200, 'mr'), '₹३,२००');
    expect(formatPercent(8, 'en'), '8%');
  });

  test('month names are localised', () {
    expect(formatMonth(DateTime(2027, 2), 'en'), 'February');
    expect(formatMonth(DateTime(2027, 2), 'mr'), 'फेब्रुवारी');
  });

  test('config defaults to demo mode without Supabase credentials', () {
    final c = AppConfig.fromEnvironment();
    expect(c.productName, 'BagMitra');
    expect(c.demoMode, isTrue);
    expect(c.devGallery, isFalse);
  });
  test('years have no grouping and use locale digits', () {
    expect(formatYear(2027, 'en'), '2027');
    expect(formatYear(2027, 'mr'), '२०२७');
  });

  test('typed text takes the locale digits, nothing else changes', () {
    expect(localDigits('0.42 dS/m', 'mr'), '०.४२ dS/m');
    expect(localDigits('<0.5', 'mr'), '<०.५');
    expect(localDigits('7.9', 'en'), '7.9');
    // Hindi numbers in the app use Latin digits (formatInt), so typed text does too.
    expect(localDigits('7.9', 'hi'), '7.9');
  });

  test('coordinates keep five decimals in locale digits', () {
    expect(formatCoordinate(21.2305, 'en'), '21.23050');
    expect(formatCoordinate(79.0882, 'mr'), '७९.०८८२०');
    expect(formatCoordinate(-0.5, 'en'), '-0.50000');
  });
}
