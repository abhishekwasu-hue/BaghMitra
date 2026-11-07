import '../../bahar/data/stage_templates.dart';
import '../../bahar/domain/bahar_cycle.dart';

/// The harvest window a lot starts with: the bahar's harvest stage window from its
/// template (counting from the grower's own dates), else the harvest date the grower
/// entered, else none. Public stage windows only; nothing is guessed (Q57).
StageWindow? harvestWindowFor(BaharCycle cycle, StageTemplate? template) {
  const key = 'harvest';
  final dates = {...cycle.planned, ...cycle.actual};
  final fromTemplate = template?.windows(cycle.seasonYear, dates)[key];
  if (fromTemplate != null) return fromTemplate;
  final entered = dates[key];
  return entered == null ? null : StageWindow(entered, entered);
}

const _devanagariDigits = '०१२३४५६७८९';
final _phone = RegExp(r'(?:\d[\s\-.()+/]*){10,}');
final _link = RegExp(
  r'https?://|www\.|wa\.me|t\.me|\S+@\S+\.\w{2,}'
  r'|\b[a-z0-9-]+\.(?:com|in|net|org|co|info|biz|me|io|app|link|ly|xyz|online|site|shop)\b',
  caseSensitive: false,
);

/// True when lot text holds something like a phone number or a link: a buyer reads it
/// before acceptance, so the server refuses it (spec v1.5 §4B; same rule as the API's
/// `has_contact_details`).
bool hasContactDetails(String text) {
  final plain = text.split('').map((c) {
    final i = _devanagariDigits.indexOf(c);
    return i < 0 ? c : '$i';
  }).join();
  return _phone.hasMatch(plain) || _link.hasMatch(plain);
}
