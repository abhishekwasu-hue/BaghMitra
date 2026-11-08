import 'dart:async';

import 'package:bagmitra/features/billing/data/play_billing.dart';
import 'package:bagmitra/features/billing/data/subscription_flow.dart';

/// Play on the phone, faked: Google is never reached in tests.
class FakePlayBilling implements PlayBilling {
  FakePlayBilling({this.isAvailable = true, this.owned = const []});

  final bool isAvailable;
  final List<PlayPurchase> owned;
  final _stream = StreamController<List<PlayPurchase>>.broadcast();
  final calls = <String>[];
  String price = '₹99.00';

  void emit(List<PlayPurchase> list) => _stream.add(list);

  @override
  Future<bool> available() async => isAvailable;

  @override
  Future<PlayOffer?> offer(String productId, String basePlanId) async =>
      PlayOffer(
        productId: productId,
        basePlanId: basePlanId,
        price: price,
        billingPeriod: 'P1M',
      );

  @override
  Future<bool> buy(PlayOffer offer, {required String accountId}) async {
    calls.add('buy ${offer.productId} $accountId');
    return true;
  }

  @override
  Future<void> restore() async {
    calls.add('restore');
    if (owned.isNotEmpty) _stream.add(owned);
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Stream<List<PlayPurchase>> get purchases => _stream.stream;

  @override
  Future<void> showPriceChangeMessage() async => calls.add('message');
}

class FakeBillingServer implements BillingServer {
  FakeBillingServer({this.offer, this.accepts = true});

  PlanOffer? offer;
  bool accepts;
  final verified = <String>[];

  @override
  Future<PlanOffer?> plan() async => offer;

  @override
  Future<bool> verify(String token) async {
    verified.add(token);
    return accepts;
  }
}
