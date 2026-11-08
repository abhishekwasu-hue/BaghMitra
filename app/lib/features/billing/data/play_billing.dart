import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// One role plan as Google Play sells it: [price] is Play's own localized text (the app never
/// builds a price itself, billing addendum §1).
class PlayOffer {
  const PlayOffer({
    required this.productId,
    required this.basePlanId,
    required this.price,
    required this.billingPeriod,
    this.raw,
  });

  final String productId;
  final String basePlanId;
  final String price;

  /// ISO 8601 period from Play, e.g. P1M.
  final String billingPeriod;

  /// The plugin's product details, needed to launch the purchase (null in fakes).
  final ProductDetails? raw;
}

enum PlayPurchaseStatus { pending, purchased, restored, canceled, error }

/// A purchase the phone reports; [token] goes to the server, which asks Google.
class PlayPurchase {
  const PlayPurchase({
    required this.productId,
    required this.token,
    required this.status,
  });

  final String productId;
  final String token;
  final PlayPurchaseStatus status;
}

/// Google Play Billing on the phone (Billing Library 9 through `in_app_purchase_android`;
/// CI checks it is 8 or later). The server verifies and acknowledges every purchase
/// (ADR 0008); the app never acknowledges and never unlocks by itself.
abstract interface class PlayBilling {
  Future<bool> available();

  /// The monthly base plan offer of [productId]; null when Play does not know it.
  Future<PlayOffer?> offer(String productId, String basePlanId);

  /// Opens Play's purchase sheet; [accountId] is the server's obfuscated account id.
  Future<bool> buy(PlayOffer offer, {required String accountId});

  /// Asks Play for owned subscriptions; they arrive on [purchases] as restored.
  Future<void> restore();

  Stream<List<PlayPurchase>> get purchases;

  /// Play's own message for an outstanding price change (shown at most once a week).
  Future<void> showPriceChangeMessage();
}

class InAppPurchasePlayBilling implements PlayBilling {
  InAppPurchasePlayBilling([InAppPurchase? iap])
    : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  @override
  Future<bool> available() => _iap.isAvailable();

  @override
  Future<PlayOffer?> offer(String productId, String basePlanId) async {
    final res = await _iap.queryProductDetails({productId});
    for (final p in res.productDetails.whereType<GooglePlayProductDetails>()) {
      final i = p.subscriptionIndex;
      final offers = p.productDetails.subscriptionOfferDetails;
      if (i == null || offers == null) continue;
      final o = offers[i];
      // The base plan itself, not a promotional offer on it.
      if (o.basePlanId != basePlanId || o.offerId != null) continue;
      return PlayOffer(
        productId: p.id,
        basePlanId: o.basePlanId,
        price: p.price,
        billingPeriod: o.pricingPhases.last.billingPeriod,
        raw: p,
      );
    }
    return null;
  }

  @override
  Future<bool> buy(PlayOffer offer, {required String accountId}) {
    final details = offer.raw;
    if (details == null) return Future.value(false);
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: details,
        applicationUserName: accountId,
      ),
    );
  }

  @override
  Future<void> restore() => _iap.restorePurchases();

  @override
  Stream<List<PlayPurchase>> get purchases => _iap.purchaseStream.map(
    (list) => [
      for (final p in list)
        PlayPurchase(
          productId: p.productID,
          token: p.verificationData.serverVerificationData,
          status: switch (p.status) {
            PurchaseStatus.pending => PlayPurchaseStatus.pending,
            PurchaseStatus.purchased => PlayPurchaseStatus.purchased,
            PurchaseStatus.restored => PlayPurchaseStatus.restored,
            PurchaseStatus.canceled => PlayPurchaseStatus.canceled,
            PurchaseStatus.error => PlayPurchaseStatus.error,
          },
        ),
    ],
  );

  @override
  Future<void> showPriceChangeMessage() async {
    await _iap
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
        .showInAppMessages();
  }
}

/// Play's subscriptions page for one product: where a user accepts a price increase,
/// cancels or changes payment (the "Manage subscription" link, addendum §2.3).
Uri playSubscriptionPage({
  required String productId,
  required String package,
}) => Uri.https('play.google.com', '/store/account/subscriptions', {
  'sku': productId,
  'package': package,
});
