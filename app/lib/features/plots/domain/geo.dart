import 'dart:math' as math;

import 'plot.dart';

/// A point on the ground, in degrees (WGS84, as a phone's GPS reports it).
class LatLon {
  const LatLon(this.lat, this.lon);
  final double lat;
  final double lon;

  @override
  bool operator ==(Object other) =>
      other is LatLon && other.lat == lat && other.lon == lon;

  @override
  int get hashCode => Object.hash(lat, lon);
}

const _earthRadiusM = 6371008.8;

/// Corners projected to metres on a flat plane around their own middle. Over the size of a
/// farm block (a few hundred metres) this is accurate far better than phone GPS itself.
List<(double, double)> _toMetres(List<LatLon> corners) {
  final lat0 =
      corners.map((c) => c.lat).reduce((a, b) => a + b) / corners.length;
  final lon0 =
      corners.map((c) => c.lon).reduce((a, b) => a + b) / corners.length;
  final cosLat = math.cos(lat0 * math.pi / 180);
  return [
    for (final c in corners)
      (
        (c.lon - lon0) * math.pi / 180 * _earthRadiusM * cosLat,
        (c.lat - lat0) * math.pi / 180 * _earthRadiusM,
      ),
  ];
}

/// Area enclosed by the corners, in square metres, whichever way they were walked.
/// Fewer than three corners enclose nothing.
double polygonAreaSqM(List<LatLon> corners) {
  if (corners.length < 3) return 0;
  final p = _toMetres(corners);
  var twiceArea = 0.0;
  for (var i = 0; i < p.length; i++) {
    final (x1, y1) = p[i];
    final (x2, y2) = p[(i + 1) % p.length];
    twiceArea += x1 * y2 - x2 * y1;
  }
  return twiceArea.abs() / 2;
}

/// The middle of the enclosed area (area-weighted); the plain average for a degenerate shape.
LatLon centroidOf(List<LatLon> corners) {
  final meanLat =
      corners.map((c) => c.lat).reduce((a, b) => a + b) / corners.length;
  final meanLon =
      corners.map((c) => c.lon).reduce((a, b) => a + b) / corners.length;
  if (corners.length < 3) return LatLon(meanLat, meanLon);
  final p = _toMetres(corners);
  var twiceArea = 0.0;
  var cx = 0.0;
  var cy = 0.0;
  for (var i = 0; i < p.length; i++) {
    final (x1, y1) = p[i];
    final (x2, y2) = p[(i + 1) % p.length];
    final cross = x1 * y2 - x2 * y1;
    twiceArea += cross;
    cx += (x1 + x2) * cross;
    cy += (y1 + y2) * cross;
  }
  if (twiceArea == 0) return LatLon(meanLat, meanLon);
  final cosLat = math.cos(meanLat * math.pi / 180);
  return LatLon(
    meanLat + cy / (3 * twiceArea) / _earthRadiusM * 180 / math.pi,
    meanLon + cx / (3 * twiceArea) / (_earthRadiusM * cosLat) * 180 / math.pi,
  );
}

/// GeoJSON Polygon for the plot's `boundary`: one closed ring, longitude first.
Map<String, Object?> toGeoJsonPolygon(List<LatLon> corners) => {
  'type': 'Polygon',
  'coordinates': [
    [
      for (final c in [...corners, corners.first]) [c.lon, c.lat],
    ],
  ],
};

/// The corners of a GeoJSON Polygon made by [toGeoJsonPolygon] (null when there is no boundary).
List<LatLon>? cornersFromGeoJson(Map<String, Object?>? polygon) {
  final rings = polygon?['coordinates'];
  if (rings is! List || rings.isEmpty || rings.first is! List) return null;
  final ring = (rings.first as List).cast<List<Object?>>();
  // The ring is closed (last point repeats the first), so the corners are one fewer.
  final corners = [
    for (final p in ring.take(ring.length - 1))
      LatLon((p[1]! as num).toDouble(), (p[0]! as num).toDouble()),
  ];
  return corners.length >= 3 ? corners : null;
}

double sqMToAcres(double sqM) => sqM / Plot.sqMPerAcre;
