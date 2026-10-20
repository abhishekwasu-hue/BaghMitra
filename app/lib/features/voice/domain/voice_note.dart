import '../../../core/formatting.dart';

/// What a spoken note adds up to: an amount (when a number was said) and the words around it.
class VoiceNote {
  const VoiceNote({required this.text, this.amountPaise});

  /// The transcript with the amount removed, trimmed.
  final String text;
  final int? amountPaise;
}

final _number = RegExp(r'[0-9०-९][0-9०-९,]*(?:\.[0-9०-९]{1,2})?');

/// Pulls the first number out of a transcript as a rupee amount. Speech engines write numbers as
/// digits in every language this app supports, so number words are not parsed; when no number is
/// found the whole transcript is the note and the grower types the amount.
VoiceNote parseVoiceNote(String transcript) {
  final m = _number.firstMatch(transcript);
  if (m == null) return VoiceNote(text: transcript.trim());
  final paise = parseRupeesToPaise(m.group(0)!);
  if (paise == null) return VoiceNote(text: transcript.trim());
  final rest = transcript
      .replaceRange(m.start, m.end, ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return VoiceNote(text: rest, amountPaise: paise);
}

/// The amount as it is typed into a form field: whole rupees without decimals ("500"), otherwise
/// two decimals ("12.50").
String amountFieldText(int paise) =>
    paise % 100 == 0 ? '${paise ~/ 100}' : plainRupees(paise);
