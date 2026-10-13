import 'dart:convert';

import 'package:chopper/chopper.dart';

import '../api/generated/bagmitra.swagger.dart';

/// A refused or failed admin call, carrying the server's reason (e.g. publish blockers).
class KbAdminException implements Exception {
  const KbAdminException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Knowledge-base admin operations (API `/v1/admin/kb`). Online only, by design.
abstract interface class KbAdminRepository {
  Future<List<CardOut>> cards({String? status});
  Future<CardOut> review(
    String cardId,
    ReviewInDecision decision,
    String? comments,
  );
  Future<CardOut> publish(String cardId);
  Future<ImportOut> import(String kind, String sourceKey, String csv);
  Future<List<AlertOut>> alerts();
  Future<void> resolve(String alertId);
  Future<List<SourceOut>> sources();
}

class ApiKbAdminRepository implements KbAdminRepository {
  const ApiKbAdminRepository(this._api);
  final Bagmitra _api;

  static T _ok<T>(Response<T> res) {
    final body = res.body;
    if (res.isSuccessful && body != null) return body;
    throw KbAdminException(_message(res.error) ?? 'HTTP ${res.statusCode}');
  }

  static String? _message(Object? error) {
    Object? decoded = error;
    if (error is String) {
      try {
        decoded = jsonDecode(error);
      } on FormatException {
        return error;
      }
    }
    if (decoded case {'error': {'message': final String message}}) {
      return message;
    }
    return null;
  }

  @override
  Future<List<CardOut>> cards({String? status}) async =>
      _ok(await _api.v1AdminKbCardsGet(status: status)).cards;

  @override
  Future<CardOut> review(
    String cardId,
    ReviewInDecision decision,
    String? comments,
  ) async => _ok(
    await _api.v1AdminKbCardsCardIdReviewsPost(
      cardId: cardId,
      body: ReviewIn(decision: decision, comments: comments),
    ),
  );

  @override
  Future<CardOut> publish(String cardId) async =>
      _ok(await _api.v1AdminKbCardsCardIdPublishPost(cardId: cardId));

  @override
  Future<ImportOut> import(String kind, String sourceKey, String csv) async =>
      _ok(
        await _api.v1AdminKbImportsKindPost(
          kind: V1AdminKbImportsKindPostKind.values.byName(kind),
          body: ImportIn(sourceKey: sourceKey, csv: csv),
        ),
      );

  @override
  Future<List<AlertOut>> alerts() async =>
      _ok(await _api.v1AdminKbAlertsGet()).alerts;

  @override
  Future<void> resolve(String alertId) async =>
      _ok(await _api.v1AdminKbAlertsAlertIdResolvePost(alertId: alertId));

  @override
  Future<List<SourceOut>> sources() async =>
      _ok(await _api.v1AdminKbSourcesGet()).sources;
}
