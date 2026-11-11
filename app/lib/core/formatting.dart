import 'package:intl/intl.dart';

/// Indian-format numbers per locale: lakh grouping, native digits where the locale uses
/// them (e.g. Marathi ३,२००), Latin digits for English (en_IN).
String _intlLocale(String languageCode) =>
    languageCode == 'en' ? 'en_IN' : languageCode;

String formatInt(int value, String languageCode) =>
    NumberFormat.decimalPattern(_intlLocale(languageCode)).format(value);

String formatRupees(int value, String languageCode) =>
    '₹${formatInt(value, languageCode)}';

String formatPercent(int value, String languageCode) =>
    '${formatInt(value, languageCode)}%';

String formatMonth(DateTime date, String languageCode) =>
    DateFormat.MMMM(_intlLocale(languageCode)).format(date);

/// Up to two decimals, Indian grouping, locale digits (e.g. Marathi ४.५).
String formatDecimal(double value, String languageCode) =>
    NumberFormat('#,##,##0.##', _intlLocale(languageCode)).format(value);

/// Day, short month, year in the locale's script, e.g. "10 Feb 2027" / "१० फेब्रु, २०२७".
String formatDate(DateTime date, String languageCode) =>
    DateFormat.yMMMd(_intlLocale(languageCode)).format(date);

/// Short weekday in the locale's script, e.g. "Wed" / "बुध".
String formatWeekday(DateTime date, String languageCode) =>
    DateFormat.E(_intlLocale(languageCode)).format(date);

/// Day / month as numbers in the locale's digits, e.g. "14/10" / "१४/१०".
String formatDayMonth(DateTime date, String languageCode) =>
    DateFormat('d/M', _intlLocale(languageCode)).format(date);

/// Day, short month and time of day in the locale's script, for "updated at" lines:
/// "25 Oct 2026, 11:30 am" in English, a 24-hour clock elsewhere ("२५ ऑक्टो, २०२६ १८:३०"),
/// where the locale's am / pm marks are single letters.
String formatDateTime(DateTime date, String languageCode) {
  final day = DateFormat.yMMMd(_intlLocale(languageCode));
  return (languageCode == 'en' ? day.add_jm() : day.add_Hm()).format(date);
}

/// A number typed as text by the grower (a lab value such as "7.9" or "<0.5"), shown with
/// the locale's digits like every other number on screen. Only the digits change: the
/// stored text and everything else in it stay as typed.
String localDigits(String text, String languageCode) {
  final zero = NumberFormat.decimalPattern(_intlLocale(languageCode))
      .symbols
      .ZERO_DIGIT
      .codeUnitAt(0);
  if (zero == 0x30) return text;
  return String.fromCharCodes([
    for (final u in text.codeUnits)
      u >= 0x30 && u <= 0x39 ? zero + u - 0x30 : u,
  ]);
}

/// A latitude or longitude with five decimals (about one metre), in locale digits.
String formatCoordinate(double value, String languageCode) =>
    NumberFormat('0.00000', _intlLocale(languageCode)).format(value);

/// A year without grouping, in locale digits (e.g. Marathi २०२७).
String formatYear(int year, String languageCode) =>
    NumberFormat('0', _intlLocale(languageCode)).format(year);

/// Exact paise as rupees: whole rupees without decimals, otherwise two decimals.
String formatPaise(int paise, String languageCode) {
  if (paise % 100 == 0) return formatRupees(paise ~/ 100, languageCode);
  final f = NumberFormat('#,##,##0.00', _intlLocale(languageCode));
  return '₹${f.format(paise / 100)}';
}

/// Exact paise as a plain decimal rupee amount ("1500.00", "-12.50") for spreadsheets: no
/// symbol, no grouping, no locale digits, and no floating point.
String plainRupees(int paise) {
  final abs = paise.abs();
  final text = '${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
  return paise < 0 ? '-$text' : text;
}

const _devanagariDigits = '०१२३४५६७८९';

/// Parses a rupee amount typed by a grower ("1,500", "12.5", Devanagari digits) into
/// exact paise. Returns null for anything that is not a non-negative amount with at
/// most two decimals.
int? parseRupeesToPaise(String input) {
  final digits = input.split('').map((c) {
    final i = _devanagariDigits.indexOf(c);
    return i < 0 ? c : '$i';
  }).join();
  final clean = digits.replaceAll(RegExp(r'[,\s₹]'), '');
  final m = RegExp(r'^(\d{1,10})(?:\.(\d{1,2}))?$').firstMatch(clean);
  if (m == null) return null;
  final fraction = (m.group(2) ?? '').padRight(2, '0');
  return int.parse(m.group(1)!) * 100 + int.parse(fraction);
}
