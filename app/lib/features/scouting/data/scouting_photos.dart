import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum PhotoSource { camera, gallery }

/// The optional scouting photo. It stays on this phone (app documents folder); nothing is
/// uploaded and the path is never synced (photo upload needs signed URLs, OPEN_QUESTIONS Q34).
abstract interface class ScoutingPhotos {
  /// Lets the grower take or pick one photo; a temporary path, or null when cancelled.
  Future<String?> pick(PhotoSource source);

  /// Copies a picked photo into the app's own folder for [recordId]; the kept path.
  Future<String> keep(String pickedPath, String recordId);

  /// Removes a kept photo; a missing file is not an error.
  Future<void> discard(String path);
}

class DeviceScoutingPhotos implements ScoutingPhotos {
  DeviceScoutingPhotos({
    ImagePicker? picker,
    Future<Directory> Function()? documents,
  }) : _picker = picker ?? ImagePicker(),
       _documents = documents ?? getApplicationDocumentsDirectory;

  /// Phone photos are large; this is plenty to see a pest on a leaf.
  static const maxWidth = 1280.0;
  static const imageQuality = 70;
  static const folder = 'scouting_photos';

  final ImagePicker _picker;
  final Future<Directory> Function() _documents;

  @override
  Future<String?> pick(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: maxWidth,
      imageQuality: imageQuality,
      requestFullMetadata: false,
    );
    return file?.path;
  }

  @override
  Future<String> keep(String pickedPath, String recordId) async {
    final dir = Directory(p.join((await _documents()).path, folder));
    await dir.create(recursive: true);
    final ext = p.extension(pickedPath);
    final dest = p.join(dir.path, '$recordId${ext.isEmpty ? '.jpg' : ext}');
    await File(pickedPath).copy(dest);
    return dest;
  }

  @override
  Future<void> discard(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
