import '../../../data/local/database.dart';

/// Whether the grower said "no" to writing his name in the app language's script, per
/// language. Kept in the local meta table (per install, never synced), like the other flags.
class NameScriptFlag {
  NameScriptFlag(this._db);

  static String metaKey(String languageCode) =>
      'name_script_prompt_dismissed_$languageCode';

  final AppDatabase _db;

  Future<bool> dismissed(String languageCode) async =>
      await _db.readMeta(metaKey(languageCode)) == '1';

  Future<void> dismiss(String languageCode) =>
      _db.writeMeta(metaKey(languageCode), '1');
}

/// Languages written in Devanagari, where a name typed in Latin letters is offered to be
/// written again (no machine transliteration: a guessed spelling of a name can be wrong).
const devanagariLanguages = {'mr', 'hi'};

/// True for a name with Latin letters and no Devanagari, e.g. "Abhishek" (not "अभिषेक").
bool nameNeedsScript(String name) =>
    RegExp('[A-Za-z]').hasMatch(name) && !RegExp('[ऀ-ॿ]').hasMatch(name);
