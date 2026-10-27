import 'package:share_plus/share_plus.dart';

/// Hands a short text to the phone's share sheet. An interface so screens and tests never
/// touch the platform plugin.
// ignore: one_member_abstracts
abstract interface class TextSharer {
  Future<void> shareText(String text);
}

class SharePlusTextSharer implements TextSharer {
  const SharePlusTextSharer();

  @override
  Future<void> shareText(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }
}
