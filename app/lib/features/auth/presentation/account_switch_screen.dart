import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../l10n/app_localizations.dart';
import '../../../sync/account_guard.dart';

/// Shown when an account signs in on a phone that holds another account's records
/// (OPEN_QUESTIONS Q36). If everything of the other account was sent, the grower may go on
/// and the phone is cleared for them; if not, that account has to sign back in first.
class AccountSwitchScreen extends ConsumerStatefulWidget {
  const AccountSwitchScreen({super.key});

  @override
  ConsumerState<AccountSwitchScreen> createState() =>
      _AccountSwitchScreenState();
}

class _AccountSwitchScreenState extends ConsumerState<AccountSwitchScreen> {
  bool _busy = false;

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      await ref.read(accountGateProvider.notifier).confirmSwitch();
    } on StateError {
      // A write was queued meanwhile: check again, which now blocks.
      ref.invalidate(accountGateProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    ref.read(languagePreviewProvider.notifier).set(null);
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final gate = ref.watch(accountGateProvider).value;
    final blocked = gate == AccountCheck.blocked;
    final guard = ref.watch(accountGuardProvider);
    final details = ref.watch(_blockedDetailsProvider(guard)).value;

    return Scaffold(
      key: Key(blocked ? 'account-blocked' : 'account-switch'),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(blocked ? t.accountBlockedTitle : t.accountSwitchTitle),
      ),
      bottomNavigationBar: BottomActions(
        children: [
          if (blocked)
            FilledButton(
              key: const Key('account-switch-sign-out'),
              onPressed: _signOut,
              child: Text(t.profileSignOut),
            )
          else ...[
            OutlinedButton(
              key: const Key('account-switch-sign-out'),
              onPressed: _busy ? null : _signOut,
              child: Text(t.profileSignOut),
            ),
            FilledButton(
              key: const Key('account-switch-continue'),
              onPressed: _busy ? null : _continue,
              child: Text(t.accountSwitchContinue),
            ),
          ],
        ],
      ),
      body: EmptyState(
        glyph: BmGlyph.warning,
        message: [
          if (blocked)
            t.accountBlockedBody(details?.unsent ?? 1)
          else
            t.accountSwitchBody,
          if (details?.phone case final phone? when phone.isNotEmpty)
            t.accountPreviousPhone(phone),
        ].join('\n\n'),
      ),
    );
  }
}

final _blockedDetailsProvider = FutureProvider.autoDispose
    .family<({int unsent, String? phone}), AccountGuard>(
      (ref, guard) async =>
          (unsent: await guard.unsentCount(), phone: await guard.ownerPhone()),
    );
