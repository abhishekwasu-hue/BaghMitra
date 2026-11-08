import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/providers.dart';
import 'feedback_outbox.dart';

final feedbackServerProvider = Provider<FeedbackServer>(
  (ref) => ApiFeedbackServer(ref.watch(apiProvider)),
);

final feedbackOutboxProvider = Provider<FeedbackOutbox>(
  (ref) => FeedbackOutbox(
    ref.watch(databaseProvider),
    ref.watch(feedbackServerProvider),
  ),
);

/// "Redmi Note 12 · Android 14"; the platform name alone when the model cannot be read.
final deviceNameProvider = FutureProvider<String>((ref) async {
  try {
    if (Platform.isAndroid) {
      final a = await DeviceInfoPlugin().androidInfo;
      return '${a.manufacturer} ${a.model} · Android ${a.version.release}';
    }
  } on Object {
    // fall through to the platform name
  }
  return Platform.operatingSystem;
});

/// Picks one screenshot from the phone's gallery; null when cancelled.
final screenshotPickerProvider = Provider<Future<String?> Function()>(
  (ref) => () async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    return file?.path;
  },
);

/// Feedback written offline goes at the next start (never in demo mode).
final feedbackStartupProvider = FutureProvider<void>((ref) async {
  if (ref.watch(appConfigProvider).demoMode) return;
  await ref.read(feedbackOutboxProvider).flush();
});
