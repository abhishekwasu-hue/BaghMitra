import 'dart:math' as math;

import 'package:bagmitra/features/plots/domain/geo.dart';
import 'package:flutter_test/flutter_test.dart';

/// A square of [side] metres whose south-west corner is at [origin].
List<LatLon> square(
  double side, {
  LatLon origin = const LatLon(21.1458, 79.0882),
}) {
  const metresPerDegree = 111194.9;
  final dLat = side / metresPerDegree;
  final dLon = side / (metresPerDegree * math.cos(origin.lat * math.pi / 180));
  return [
    origin,
    LatLon(origin.lat, origin.lon + dLon),
    LatLon(origin.lat + dLat, origin.lon + dLon),
    LatLon(origin.lat + dLat, origin.lon),
  ];
}

void main() {
  test('a 100 m square near Nagpur is about one hectare', () {
    final area = polygonAreaSqM(square(100));
    expect(area, closeTo(10000, 50)); // within 0.5 %
  });

  test('area does not depend on the direction the grower walked', () {
    final s = square(80);
    expect(
      polygonAreaSqM(s.reversed.toList()),
      closeTo(polygonAreaSqM(s), 1e-6),
    );
  });

  test('fewer than three corners enclose nothing', () {
    expect(polygonAreaSqM(const []), 0);
    expect(polygonAreaSqM(const [LatLon(21, 79)]), 0);
    expect(polygonAreaSqM(const [LatLon(21, 79), LatLon(21.001, 79)]), 0);
  });

  test('the centroid of a square is its middle', () {
    final s = square(100);
    final c = centroidOf(s);
    expect(c.lat, closeTo((s[0].lat + s[2].lat) / 2, 1e-7));
    expect(c.lon, closeTo((s[0].lon + s[2].lon) / 2, 1e-7));
  });

  test('GeoJSON polygon is closed and lists longitude first', () {
    final s = square(100);
    final g = toGeoJsonPolygon(s);
    expect(g['type'], 'Polygon');
    final ring = (g['coordinates']! as List<Object?>).first! as List<Object?>;
    expect(ring, hasLength(5));
    expect(ring.first, [s[0].lon, s[0].lat]);
    expect(ring.last, ring.first);
  });

  test('acres are the area divided by the acre in square metres', () {
    expect(sqMToAcres(4046.8564224), closeTo(1, 1e-9));
  });
}
