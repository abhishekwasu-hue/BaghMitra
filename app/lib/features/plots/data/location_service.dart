import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../domain/geo.dart';

enum LocationProblem { serviceOff, denied, deniedForever, failed }

/// One attempt to read the phone's position: a point with its accuracy, or why there is none.
class LocationReading {
  const LocationReading.at(LatLon this.position, {this.accuracyM})
    : problem = null;
  const LocationReading.problem(LocationProblem this.problem)
    : position = null,
      accuracyM = null;

  final LatLon? position;
  final double? accuracyM;
  final LocationProblem? problem;
}

/// How long a "stand in the block" fix may take, and the accuracy that ends the wait early.
abstract final class PointFix {
  static const within = Duration(seconds: 15);
  static const goodEnoughM = 15.0;
}

/// Reads the position once, when the grower asks. An interface so screens and tests never touch
/// the platform plugin. Nothing is tracked in the background.
abstract interface class LocationService {
  /// The next fix (one boundary corner, one claim photo).
  Future<LocationReading> current();

  /// Fixes for up to [within], ended early by one within [goodEnoughM]; returns the most
  /// accurate one (see [bestFixOf]).
  Future<LocationReading> settled({
    Duration within = PointFix.within,
    double goodEnoughM = PointFix.goodEnoughM,
  });

  /// Opens the phone setting that clears [problem] (GPS switch or app permission).
  Future<void> openSettings(LocationProblem problem);
}

/// Keeps the most accurate fix of [fixes] until one is within [goodEnoughM], [within] passes
/// or the stream ends. A problem before any fix is returned as it is; after a fix it is ignored.
Future<LocationReading> bestFixOf(
  Stream<LocationReading> fixes, {
  required Duration within,
  required double goodEnoughM,
}) async {
  LocationReading? best;
  LocationProblem? problem;
  final done = Completer<void>();
  void finish() {
    if (!done.isCompleted) done.complete();
  }

  double accuracy(LocationReading r) => r.accuracyM ?? double.infinity;
  final sub = fixes.listen(
    (r) {
      if (r.position == null) {
        problem ??= r.problem;
        if (best == null) finish();
        return;
      }
      if (best == null || accuracy(r) < accuracy(best!)) best = r;
      if (accuracy(best!) <= goodEnoughM) finish();
    },
    onError: (Object _) {
      problem ??= LocationProblem.failed;
      finish();
    },
    onDone: finish,
  );
  final timer = Timer(within, finish);
  await done.future;
  timer.cancel();
  await sub.cancel();
  return best ?? LocationReading.problem(problem ?? LocationProblem.failed);
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  /// Asks for the permission when needed; null when the position can be read.
  Future<LocationProblem?> _ready() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationProblem.serviceOff;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.deniedForever => LocationProblem.deniedForever,
      LocationPermission.denied => LocationProblem.denied,
      _ => null,
    };
  }

  @override
  Future<LocationReading> current() async {
    try {
      final problem = await _ready();
      if (problem != null) return LocationReading.problem(problem);
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LocationReading.at(
        LatLon(p.latitude, p.longitude),
        accuracyM: p.accuracy,
      );
    } on Exception {
      return const LocationReading.problem(LocationProblem.failed);
    }
  }

  @override
  Future<LocationReading> settled({
    Duration within = PointFix.within,
    double goodEnoughM = PointFix.goodEnoughM,
  }) async {
    try {
      final problem = await _ready();
      if (problem != null) return LocationReading.problem(problem);
      final fixes =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(),
          ).map(
            (p) => LocationReading.at(
              LatLon(p.latitude, p.longitude),
              accuracyM: p.accuracy,
            ),
          );
      return await bestFixOf(fixes, within: within, goodEnoughM: goodEnoughM);
    } on Exception {
      return const LocationReading.problem(LocationProblem.failed);
    }
  }

  @override
  Future<void> openSettings(LocationProblem problem) async {
    try {
      problem == LocationProblem.serviceOff
          ? await Geolocator.openLocationSettings()
          : await Geolocator.openAppSettings();
    } on Exception {
      // The grower can still open the settings by hand; nothing else depends on this.
    }
  }
}
