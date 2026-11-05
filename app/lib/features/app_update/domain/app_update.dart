/// The app update path (audit BG-06): what the server says about releases, and what that
/// means for the installed APK.
library;

/// The server's release info (`GET /v1/app/version`). A code of 0 means "not set".
class AppRelease {
  const AppRelease({
    required this.latestCode,
    required this.latestName,
    required this.minCode,
    required this.downloadUrl,
  });

  factory AppRelease.fromJson(Map<String, Object?> json) => AppRelease(
    latestCode: json['latest_version_code']! as int,
    latestName: json['latest_version_name']! as String,
    minCode: json['min_version_code']! as int,
    downloadUrl: json['download_url']! as String,
  );

  final int latestCode;
  final String latestName;
  final int minCode;
  final String downloadUrl;

  Map<String, Object?> toJson() => {
    'latest_version_code': latestCode,
    'latest_version_name': latestName,
    'min_version_code': minCode,
    'download_url': downloadUrl,
  };
}

enum UpdateNeed {
  /// Up to date, not known, or the check is off.
  none,

  /// A newer APK exists: a small notice that can be closed.
  available,

  /// This APK is older than the oldest one still allowed: a blocking screen.
  required,
}

class AppUpdateState {
  const AppUpdateState(this.need, [this.release]);

  static const none = AppUpdateState(UpdateNeed.none);

  final UpdateNeed need;
  final AppRelease? release;
}

/// [installedCode] 0 or below means the installed version is unknown: nothing is shown.
UpdateNeed updateNeed(int installedCode, AppRelease release) {
  if (installedCode <= 0 || release.downloadUrl.isEmpty) return UpdateNeed.none;
  if (release.minCode > installedCode) return UpdateNeed.required;
  if (release.latestCode > installedCode) return UpdateNeed.available;
  return UpdateNeed.none;
}
