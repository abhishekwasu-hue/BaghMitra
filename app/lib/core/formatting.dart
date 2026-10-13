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

/// A year without grouping, in locale digits (e.g. Marathi २०२७).
String formatYear(int year, String languageCode) =>
    NumberFormat('0', _intlLocale(languageCode)).format(year);
