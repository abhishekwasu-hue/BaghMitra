import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import 'play_billing.dart';

/// What the subscription page shows while Play and the server work.
enum FlowStep { idle, waitingForPlay, pending, verifying, done, failed }

/// The server's offer for this user (`GET /v1/billing/plan`): shown only while the
/// switch is ON and the user's role has an amount (billing addendum §7).
class PlanOffer {
  const PlanOffer({
    required this.inForce,
    required this.accountId,
    this.productId,
    this.basePlanId,
    this.covered = false,
    this.priceChange,
  });

  factory PlanOffer.fromApi(PlanOfferOut o) => PlanOffer(
    inForce: o.inForce,
    accountId: o.accountId,
    productId: o.productId,
    basePlanId: o.basePlanId,
    covered: o.covered,
    priceChange: o.priceChange,
  );

  final bool inForce;
  final String accountId;
  final String? productId;
  final String? basePlanId;
  final bool covered;

  /// A pending price increase Play announced: the app must show a notice (§7).
  final PriceChangeOut? priceChange;

  bool get showsPlan => inForce && productId != null && basePlanId != null;
}

/// The server side of a purchase: `GET /v1/billing/plan`, `POST /v1/billing/google/verify`.
abstract interface class BillingServer {
  Future<PlanOffer?> plan();

  /// True when the server confirmed the token with Google (it also acknowledges).
  Future<bool> verify(String token);
}

class ApiBillingServer implements BillingServer {
  const ApiBillingServer(this._api);
  final Bagmitra _api;

  @override
  Future<PlanOffer?> plan() async {
    try {
      final res = await _api.v1BillingPlanGet();
      final body = res.body;
      return res.isSuccessful && body != null ? PlanOffer.fromApi(body) : null;
    } on Object {
      return null; // offline: no offer shown, the app stays fully usable
    }
  }

  @override
  Future<bool> verify(String token) async {
    try {
      final res = await _api.v1BillingGoogleVerifyPost(
        body: VerifyIn(purchaseToken: token),
      );
      return res.isSuccessful;
    } on Object {
      return false;
    }
  }
}

/// Purchase, restore and startup reconcile (addendum §2.3). Every token Play reports
/// (bought now, restored, or found at start after the app was killed mid-purchase) goes to
/// the server; only after the server confirms does [onVerified] refresh the entitlement
/// snapshot. A token that could not be sent is retried at the next start or restore.
class SubscriptionFlow {
  SubscriptionFlow({
    required this.play,
    required this.server,
    required this.onVerified,
  });

  final PlayBilling play;
  final BillingServer server;
  final Future<void> Function() onVerified;
  final step = ValueNotifier<FlowStep>(FlowStep.idle);
  StreamSubscription<List<PlayPurchase>>? _sub;
  final _sent = <String>{};

  /// Listen to Play and reconcile what the phone already owns. Safe without Play.
  Future<void> start() async {
    _sub ??= play.purchases.listen(_onPurchases);
    if (await play.available()) await play.restore();
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    step.dispose();
  }

  Future<void> buy(PlayOffer offer, PlanOffer plan) async {
    step.value = FlowStep.waitingForPlay;
    final opened = await play.buy(offer, accountId: plan.accountId);
    if (!opened) step.value = FlowStep.failed;
  }

  Future<void> restore() async {
    step.value = FlowStep.waitingForPlay;
    await play.restore();
    // Nothing owned: Play reports no purchase at all.
    if (step.value == FlowStep.waitingForPlay) step.value = FlowStep.idle;
  }

  Future<void> _onPurchases(List<PlayPurchase> list) async {
    for (final p in list) {
      switch (p.status) {
        case PlayPurchaseStatus.pending:
          step.value = FlowStep.pending;
        case PlayPurchaseStatus.canceled:
          step.value = FlowStep.idle;
        case PlayPurchaseStatus.error:
          step.value = FlowStep.failed;
        case PlayPurchaseStatus.purchased || PlayPurchaseStatus.restored:
          if (p.token.isEmpty || _sent.contains(p.token)) continue;
          step.value = FlowStep.verifying;
          if (await server.verify(p.token)) {
            _sent.add(p.token);
            await onVerified();
            step.value = FlowStep.done;
          } else {
            step.value = FlowStep.failed;
          }
      }
    }
  }
}
