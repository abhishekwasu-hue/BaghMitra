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

/// Reads the position once, when the grower asks. An interface so screens and tests never touch
/// the platform plugin. Nothing is tracked in the background.
// ignore: one_member_abstracts
abstract interface class LocationService {
  Future<LocationReading> current();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationReading> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationReading.problem(LocationProblem.serviceOff);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationReading.problem(LocationProblem.deniedForever);
      }
      if (permission == LocationPermission.denied) {
        return const LocationReading.problem(LocationProblem.denied);
      }
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
}
