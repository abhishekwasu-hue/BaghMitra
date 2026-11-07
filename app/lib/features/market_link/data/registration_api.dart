import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../app/providers.dart';
import '../../plots/data/location_service.dart';
import '../../plots/data/place_geocoder.dart';
import '../domain/registration.dart';

/// Why a market-link call ended without an answer: [offline] (no network), [server]
/// (the server could not answer), or [refused] with the server's error [code].
enum MarketCallProblem { offline, server, refused }

class MarketCallException implements Exception {
  const MarketCallException(this.problem, [this.code]);
  final MarketCallProblem problem;
  final String? code;

  @override
  String toString() => 'market link call: ${problem.name} $code';
}

/// The phone's view of the L2 endpoints. An interface so screens and tests never reach a
/// server. Online only: registration needs the fix taken now and the server's check.
abstract interface class RegistrationApi {
  Future<void> register(RegistrationRole role, Map<String, Object?> body);

  Future<List<MarketProfile>> mine();

  /// Verified traders / exporters / brokers in a taluka ([role] trader, exporter or broker).
  Future<List<MarketProfile>> people({
    required String role,
    String? taluka,
    String? district,
    String sort = 'rating',
  });

  Future<MarketProfile> profile(String subjectType, String id);

  /// Verified providers, nearest to [plotId] first when it has a pin.
  Future<List<MarketProfile>> providers({
    ProviderKind? kind,
    String? district,
    String? taluka,
    String? plotId,
  });

  Future<MarketProfile> setAddress(
    String subjectType,
    String id,
    String? address,
  );

  /// Sends one photo; the server strips EXIF before storing it (spec §4B).
  Future<MarketProfile> addDocument(
    String subjectType,
    String id,
    DocKind doc,
    List<int> jpeg, {
    DateTime? validUntil,
  });
}

class HttpRegistrationApi implements RegistrationApi {
  HttpRegistrationApi(this._api);

  final Bagmitra _api;
  static const _base = '/v1/market-link';

  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final chopper.Response<String> res;
    try {
      res = await _api.client.send<String, String>(
        chopper.Request(
          method,
          Uri.parse('$_base$path'),
          _api.client.baseUrl,
          body: body,
          parameters: query,
          headers: headers,
        ),
      );
    } on SocketException {
      throw const MarketCallException(MarketCallProblem.offline);
    } on TimeoutException {
      throw const MarketCallException(MarketCallProblem.offline);
    } on chopper.ChopperException {
      throw const MarketCallException(MarketCallProblem.server);
    }
    final text = res.bodyString;
    if (res.isSuccessful) return text.isEmpty ? null : jsonDecode(text);
    if (res.statusCode >= 500) {
      throw const MarketCallException(MarketCallProblem.server);
    }
    String? code;
    try {
      code = ((jsonDecode(text) as Map)['error'] as Map?)?['code'] as String?;
    } on Object {
      code = null;
    }
    throw MarketCallException(MarketCallProblem.refused, code);
  }

  MarketProfile _one(Object? json) =>
      MarketProfile.fromJson((json! as Map).cast<String, Object?>());

  List<MarketProfile> _list(Object? json) => [
    for (final m in ((json! as Map)['profiles'] as List))
      MarketProfile.fromJson((m as Map).cast<String, Object?>()),
  ];

  @override
  Future<void> register(RegistrationRole role, Map<String, Object?> body) =>
      _send('POST', '/${role.path}', body: jsonEncode(body), headers: _json);

  static const _json = {'Content-Type': 'application/json'};

  @override
  Future<List<MarketProfile>> mine() async =>
      _list(await _send('GET', '/me/profiles'));

  @override
  Future<List<MarketProfile>> people({
    required String role,
    String? taluka,
    String? district,
    String sort = 'rating',
  }) async => _list(
    await _send(
      'GET',
      '/profiles',
      query: {
        'role': role,
        'sort': sort,
        'taluka': ?taluka,
        'district': ?district,
      },
    ),
  );

  @override
  Future<MarketProfile> profile(String subjectType, String id) async =>
      _one(await _send('GET', '/profiles/$subjectType/$id'));

  @override
  Future<List<MarketProfile>> providers({
    ProviderKind? kind,
    String? district,
    String? taluka,
    String? plotId,
  }) async => _list(
    await _send(
      'GET',
      '/providers',
      query: {
        'type': ?kind?.api,
        'district': ?district,
        'taluka': ?taluka,
        'plot_id': ?plotId,
      },
    ),
  );

  @override
  Future<MarketProfile> setAddress(
    String subjectType,
    String id,
    String? address,
  ) async => _one(
    await _send(
      'PUT',
      '/profiles/$subjectType/$id/address',
      body: jsonEncode({'address': address}),
      headers: _json,
    ),
  );

  @override
  Future<MarketProfile> addDocument(
    String subjectType,
    String id,
    DocKind doc,
    List<int> jpeg, {
    DateTime? validUntil,
  }) async => _one(
    await _send(
      'POST',
      '/profiles/$subjectType/$id/documents',
      body: jpeg,
      query: {
        'doc': doc.name,
        if (validUntil != null)
          'valid_until': validUntil.toIso8601String().substring(0, 10),
      },
      headers: const {'Content-Type': 'image/jpeg'},
    ),
  );
}

/// Why no fix could be taken; [problem] is the phone's location problem.
class FixFailure implements Exception {
  const FixFailure(this.problem);
  final LocationProblem problem;
}

/// Takes the ONE foreground registration fix (addendum 3): asks the permission, reads a
/// settled position, names the place with the phone's own geocoder (no paid service) and
/// keeps the plugin's mock-location flag. Nothing is tracked afterwards.
Future<RegistrationFix> takeRegistrationFix(
  LocationService location,
  PlaceGeocoder geocoder, {
  required String languageCode,
  required DateTime Function() now,
}) async {
  final reading = await location.settled();
  final point = reading.position;
  if (point == null) {
    throw FixFailure(reading.problem ?? LocationProblem.failed);
  }
  final address = await geocoder.addressOf(point, languageCode: languageCode);
  return RegistrationFix(
    lat: point.lat,
    lon: point.lon,
    accuracyM: reading.accuracyM ?? 0,
    capturedAt: now(),
    place: address?.place,
    district: address?.district,
    state: address?.state,
    pin: address?.postalCode,
    isMocked: reading.isMocked,
  );
}

final registrationApiProvider = Provider<RegistrationApi>(
  (ref) => HttpRegistrationApi(ref.watch(apiProvider)),
);

/// The signed-in user's own market-link profiles (online).
final myMarketProfilesProvider = FutureProvider<List<MarketProfile>>(
  (ref) => ref.watch(registrationApiProvider).mine(),
);
