import 'package:bagmitra/features/billing/data/play_billing.dart';
import 'package:bagmitra/features/billing/data/subscription_flow.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_play_billing.dart';

const _plan = PlanOffer(
  inForce: true,
  accountId: 'acct-hash',
  productId: 'bagmitra_grower',
  basePlanId: 'monthly',
);

PlayPurchase _p(String token, PlayPurchaseStatus status) =>
    PlayPurchase(productId: 'bagmitra_grower', token: token, status: status);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('a purchase unlocks only after the server confirmed it', () async {
    final play = FakePlayBilling();
    final server = FakeBillingServer();
    var refreshed = 0;
    final flow = SubscriptionFlow(
      play: play,
      server: server,
      onVerified: () async => refreshed++,
    );
    await flow.start();
    final offer = await play.offer('bagmitra_grower', 'monthly');
    await flow.buy(offer!, _plan);
    expect(play.calls, ['restore', 'buy bagmitra_grower acct-hash']);
    expect(flow.step.value, FlowStep.waitingForPlay);
    play.emit([_p('tok-1', PlayPurchaseStatus.purchased)]);
    await _settle();
    expect(server.verified, ['tok-1']);
    expect(refreshed, 1);
    expect(flow.step.value, FlowStep.done);
  });

  test('the server refusing keeps everything as it was', () async {
    final play = FakePlayBilling();
    final server = FakeBillingServer(accepts: false);
    var refreshed = 0;
    final flow = SubscriptionFlow(
      play: play,
      server: server,
      onVerified: () async => refreshed++,
    );
    await flow.start();
    play.emit([_p('tok-2', PlayPurchaseStatus.purchased)]);
    await _settle();
    expect(refreshed, 0);
    expect(flow.step.value, FlowStep.failed);
    // Sent again at the next start / restore (not remembered as sent).
    server.accepts = true;
    play.emit([_p('tok-2', PlayPurchaseStatus.restored)]);
    await _settle();
    expect(server.verified, ['tok-2', 'tok-2']);
    expect(refreshed, 1);
  });

  test('startup reconcile sends what the phone already owns', () async {
    // The app was killed mid-purchase, or this is a new phone: restore at start.
    final play = FakePlayBilling(
      owned: [_p('tok-old', PlayPurchaseStatus.restored)],
    );
    final server = FakeBillingServer();
    final flow = SubscriptionFlow(
      play: play,
      server: server,
      onVerified: () async {},
    );
    await flow.start();
    await _settle();
    expect(server.verified, ['tok-old']);
  });

  test('no Play on the phone: nothing is asked', () async {
    final play = FakePlayBilling(isAvailable: false);
    final flow = SubscriptionFlow(
      play: play,
      server: FakeBillingServer(),
      onVerified: () async {},
    );
    await flow.start();
    expect(play.calls, isEmpty);
  });

  test('pending, cancel and restore with nothing owned', () async {
    final play = FakePlayBilling();
    final flow = SubscriptionFlow(
      play: play,
      server: FakeBillingServer(),
      onVerified: () async {},
    );
    await flow.start();
    play.emit([_p('tok-3', PlayPurchaseStatus.pending)]);
    await _settle();
    expect(flow.step.value, FlowStep.pending);
    play.emit([_p('tok-3', PlayPurchaseStatus.canceled)]);
    await _settle();
    expect(flow.step.value, FlowStep.idle);
    await flow.restore();
    expect(flow.step.value, FlowStep.idle);
  });

  test('the same token is verified once', () async {
    final play = FakePlayBilling();
    final server = FakeBillingServer();
    final flow = SubscriptionFlow(
      play: play,
      server: server,
      onVerified: () async {},
    );
    await flow.start();
    play
      ..emit([_p('tok-4', PlayPurchaseStatus.purchased)])
      ..emit([_p('tok-4', PlayPurchaseStatus.restored)]);
    await _settle();
    await _settle();
    expect(server.verified, ['tok-4']);
  });

  test('Manage subscription opens Play for this product and app', () {
    expect(
      playSubscriptionPage(
        productId: 'bagmitra_grower',
        package: 'app.bagmitra.bagmitra',
      ).toString(),
      'https://play.google.com/store/account/subscriptions'
      '?sku=bagmitra_grower&package=app.bagmitra.bagmitra',
    );
  });

  test(
    'only a shown plan when the switch is on and the role has an amount',
    () {
      expect(_plan.showsPlan, isTrue);
      expect(
        const PlanOffer(inForce: false, accountId: 'a').showsPlan,
        isFalse,
      );
    },
  );
}
