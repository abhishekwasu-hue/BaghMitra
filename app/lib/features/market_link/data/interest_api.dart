import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../app/providers.dart';
import '../domain/deal_rating.dart';
import '../domain/interest.dart';
import 'registration_api.dart';

/// What the phone sends for an interest (spec §3 step 3): nothing more.
typedef InterestDraft = ({
  String basis,
  int ratePaise,
  double? quantityT,
  DateTime harvestDate,
  String? brokerId,
  String? traderId,
});

/// The phone's view of the L4 endpoints. Online only: an interest and an acceptance are
/// decided by the server (verified, lot still published), never queued.
abstract interface class InterestApi {
  /// Published lots for a verified trader / broker (403 `not_verified` otherwise).
  Future<List<BuyerLot>> lots();

  Future<Interest> send(String lotId, InterestDraft draft);

  Future<List<SentInterest>> mine();

  /// The interests on the grower's own lot, to compare.
  Future<List<LotInterest>> onLot(String lotId);

  /// Accepts one open interest on the grower's own lot; the introduction's deal id.
  Future<String> accept(String interestId);

  Future<Introduction> introduction(String dealId);

  /// The caller (grower or trader) says the deal is done (L5, Q67).
  Future<Introduction> dealDone(String dealId);

  Future<DealRatings> ratings(String dealId);

  /// Gives or changes the caller's rating of one party (every question once).
  Future<DealRatings> rate(
    String dealId,
    DealRole ratee,
    List<RatingAnswer> answers,
  );

  /// The admin's active tick list under each question.
  Future<List<RatingTagItem>> ratingTags();
}

class HttpInterestApi implements InterestApi {
  HttpInterestApi(this._api);

  final Bagmitra _api;
  static const _json = {'Content-Type': 'application/json'};

  Map<String, Object?> _map(Object? json) =>
      (json! as Map).cast<String, Object?>();

  List<Map<String, Object?>> _items(Object? json, String key) => [
    for (final m in (_map(json)[key]! as List))
      (m as Map).cast<String, Object?>(),
  ];

  @override
  Future<List<BuyerLot>> lots() async => [
    for (final m in _items(await marketLinkSend(_api, 'GET', '/lots'), 'lots'))
      BuyerLot.fromJson(m),
  ];

  @override
  Future<Interest> send(String lotId, InterestDraft d) async =>
      Interest.fromJson(
        _map(
          await marketLinkSend(
            _api,
            'POST',
            '/lots/$lotId/interests',
            headers: _json,
            body: jsonEncode({
              'basis': d.basis,
              'rate_paise': d.ratePaise,
              'quantity_t': d.quantityT,
              'harvest_date': d.harvestDate.toIso8601String().substring(0, 10),
              'broker_id': ?d.brokerId,
              'trader_id': ?d.traderId,
            }),
          ),
        ),
      );

  @override
  Future<List<SentInterest>> mine() async => [
    for (final m in _items(
      await marketLinkSend(_api, 'GET', '/interests/mine'),
      'interests',
    ))
      SentInterest.fromJson(m),
  ];

  @override
  Future<List<LotInterest>> onLot(String lotId) async => [
    for (final m in _items(
      await marketLinkSend(_api, 'GET', '/lots/$lotId/interests'),
      'interests',
    ))
      LotInterest.fromJson(m),
  ];

  @override
  Future<String> accept(String interestId) async =>
      _map(
            await marketLinkSend(_api, 'POST', '/interests/$interestId/accept'),
          )['deal_id']!
          as String;

  @override
  Future<Introduction> introduction(String dealId) async =>
      Introduction.fromJson(
        _map(await marketLinkSend(_api, 'GET', '/deals/$dealId')),
      );

  @override
  Future<Introduction> dealDone(String dealId) async => Introduction.fromJson(
    _map(await marketLinkSend(_api, 'POST', '/deals/$dealId/done')),
  );

  @override
  Future<DealRatings> ratings(String dealId) async => DealRatings.fromJson(
    _map(await marketLinkSend(_api, 'GET', '/deals/$dealId/ratings')),
  );

  @override
  Future<DealRatings> rate(
    String dealId,
    DealRole ratee,
    List<RatingAnswer> answers,
  ) async => DealRatings.fromJson(
    _map(
      await marketLinkSend(
        _api,
        'PUT',
        '/deals/$dealId/ratings/${ratee.name}',
        headers: _json,
        body: jsonEncode({
          'answers': [for (final a in answers) a.toJson()],
        }),
      ),
    ),
  );

  @override
  Future<List<RatingTagItem>> ratingTags() async => [
    for (final m in _items(
      await marketLinkSend(_api, 'GET', '/rating-tags'),
      'tags',
    ))
      RatingTagItem.fromJson(m),
  ];
}

final interestApiProvider = Provider<InterestApi>(
  (ref) => HttpInterestApi(ref.watch(apiProvider)),
);

final buyerLotsProvider = FutureProvider.autoDispose<List<BuyerLot>>(
  (ref) => ref.watch(interestApiProvider).lots(),
);

final myInterestsProvider = FutureProvider.autoDispose<List<SentInterest>>(
  (ref) => ref.watch(interestApiProvider).mine(),
);

final lotInterestsProvider = FutureProvider.autoDispose
    .family<List<LotInterest>, String>(
      (ref, lotId) => ref.watch(interestApiProvider).onLot(lotId),
    );

final introductionProvider = FutureProvider.autoDispose
    .family<Introduction, String>(
      (ref, dealId) => ref.watch(interestApiProvider).introduction(dealId),
    );

final dealRatingsProvider = FutureProvider.autoDispose
    .family<DealRatings, String>(
      (ref, dealId) => ref.watch(interestApiProvider).ratings(dealId),
    );

/// The tag list, saved on the phone after each fetch and read from there when offline
/// (spec §3A: the app caches it).
final ratingTagsProvider = FutureProvider.autoDispose<List<RatingTagItem>>((
  ref,
) async {
  const key = 'market_link.rating_tags';
  final db = ref.watch(databaseProvider);
  try {
    final tags = await ref.watch(interestApiProvider).ratingTags();
    await db.writeMeta(key, jsonEncode([for (final t in tags) t.toJson()]));
    return tags;
  } on MarketCallException {
    final saved = await db.readMeta(key);
    if (saved == null) rethrow;
    return [
      for (final m in jsonDecode(saved) as List)
        RatingTagItem.fromJson((m as Map).cast<String, Object?>()),
    ];
  }
});
