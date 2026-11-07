import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../app/providers.dart';
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

/// The phone's view of the L4 endpoints. Online only: an interest is decided by the server
/// (verified sender, lot still published), never queued.
abstract interface class InterestApi {
  /// Published lots for a verified trader / broker (403 `not_verified` otherwise).
  Future<List<BuyerLot>> lots();

  Future<Interest> send(String lotId, InterestDraft draft);

  Future<List<SentInterest>> mine();

  /// The interests on the grower's own lot, to compare.
  Future<List<LotInterest>> onLot(String lotId);
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
