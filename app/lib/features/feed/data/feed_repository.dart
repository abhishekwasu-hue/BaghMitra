import 'dart:convert';

import '../../../api/generated/bagmitra.swagger.dart';
import '../domain/feed_item.dart';

/// Where the Sarkari Sandesh feed comes from. The server endpoint is not in the generated
/// client yet, so [HttpFeedRepository] calls it by hand; once `/v1/feed` is in the OpenAPI
/// schema, swap that one class for the generated method and keep this interface.
// ignore: one_member_abstracts
abstract interface class FeedRepository {
  /// Throws [FeedUnavailableException] when the feed cannot be fetched.
  Future<FeedPage> fetch({required String lang, FeedFilter? filter});
}

class FeedUnavailableException implements Exception {
  const FeedUnavailableException(this.reason);

  final String reason;

  @override
  String toString() => 'FeedUnavailableException: $reason';
}

/// `GET /v1/feed?lang=..&type=..` through the app's Chopper client, so the base URL and the
/// signed-in grower's bearer token are the same as every generated call.
class HttpFeedRepository implements FeedRepository {
  const HttpFeedRepository(this._api);

  final Bagmitra _api;

  static const path = '/v1/feed';

  @override
  Future<FeedPage> fetch({required String lang, FeedFilter? filter}) async {
    final res = await _api.client.get<String, String>(
      Uri(path: path),
      parameters: {'lang': lang, 'type': ?filter?.value},
    );
    final body = res.bodyString;
    if (!res.isSuccessful || body.isEmpty) {
      throw FeedUnavailableException('http ${res.statusCode}');
    }
    try {
      return FeedPage.fromJson(
        (jsonDecode(body) as Map).cast<String, Object?>(),
      );
    } on Object catch (e) {
      throw FeedUnavailableException('bad body: $e');
    }
  }
}
