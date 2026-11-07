import 'dart:async';

import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart' as geo;

import '../domain/geo.dart';

/// The nearest place to a block's location, as the phone's own geocoder names it. Shown on
/// the add-block form only, so the grower sees the location was taken in the right place;
/// it is never stored or synced (Q53, Q59).
class PlaceAddress {
  const PlaceAddress({
    this.place,
    this.area,
    this.district,
    this.state,
    this.postalCode,
  });

  /// Village, town or city (the geocoder's locality).
  final String? place;

  /// A part of [place] (the geocoder's sub-locality), when it names one.
  final String? area;

  /// The district (the geocoder's sub-administrative area).
  final String? district;

  /// The state (the geocoder's administrative area).
  final String? state;
  final String? postalCode;

  bool get isEmpty =>
      [place, area, district, state, postalCode].every((s) => s == null);
}

/// How long the address may take before the form says it was not found.
abstract final class PlaceLookup {
  static const within = Duration(seconds: 10);
}

/// Names the place at a point. An interface so screens and tests never touch the platform
/// plugin. Returns null when there is no network, no result or an error: the address is a
/// help for the grower and never blocks saving.
abstract interface class PlaceGeocoder {
  Future<PlaceAddress?> addressOf(LatLon point, {required String languageCode});
}

/// The phone's own geocoder (Android `Geocoder`, iOS `CLGeocoder`) through the `geocoding`
/// plugin: no API key, no paid service and no server of ours. Asked in the app's language
/// for India ("mr_IN"); the platform answers in that language where it can, else in its own.
class PlatformPlaceGeocoder implements PlaceGeocoder {
  const PlatformPlaceGeocoder();

  @override
  Future<PlaceAddress?> addressOf(
    LatLon point, {
    required String languageCode,
  }) async {
    try {
      final marks = await geo.Geocoding(locale: Locale(languageCode, 'IN'))
          .placemarkFromCoordinates(point.lat, point.lon)
          .timeout(PlaceLookup.within);
      if (marks.isEmpty) return null;
      final address = placeAddressOf(marks.first);
      return address.isEmpty ? null : address;
    } on Object {
      return null;
    }
  }
}

/// The fields of one platform placemark the form shows; blank ones are dropped.
PlaceAddress placeAddressOf(geo.Placemark m) {
  String? clean(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
  final place = clean(m.locality);
  final area = clean(m.subLocality);
  return PlaceAddress(
    place: place ?? area,
    area: place == null || area == place ? null : area,
    district: clean(m.subAdministrativeArea),
    state: clean(m.administrativeArea),
    postalCode: clean(m.postalCode),
  );
}
