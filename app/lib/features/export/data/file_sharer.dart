import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Hands a generated file to the phone's share sheet (WhatsApp, Drive, email, save to files).
/// An interface so screens and tests never touch the platform plugin.
// ignore: one_member_abstracts
abstract interface class FileSharer {
  Future<void> share({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  });
}

class SharePlusFileSharer implements FileSharer {
  const SharePlusFileSharer();

  @override
  Future<void> share({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: mimeType)],
        fileNameOverrides: [fileName],
      ),
    );
  }
}
