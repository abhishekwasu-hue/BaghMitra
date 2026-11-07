import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../scouting/data/scouting_photos.dart';

/// One optional photo from the in-app camera, as JPEG bytes (null when cancelled). The
/// server strips its EXIF before storing it (spec §4B).
typedef SafetyPhotoTaker = Future<List<int>?> Function();

final safetyPhotoProvider = Provider<SafetyPhotoTaker>((ref) {
  final photos = ref.watch(scoutingPhotosProvider);
  return () async {
    final path = await photos.pick(PhotoSource.camera);
    if (path == null) return null;
    final bytes = await File(path).readAsBytes();
    await photos.discard(path);
    return bytes;
  };
});
