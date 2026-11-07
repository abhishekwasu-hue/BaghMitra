import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../scouting/data/scouting_photos.dart';
import '../data/registration_api.dart';
import '../domain/registration.dart';
import 'profile_widgets.dart';
import 'registration_screen.dart';

/// "My market registration": each role the user registered in, the state of BagMitra's
/// check, document photos (in-app camera; EXIF stripped by the server) and the optional
/// address; and big cards to register in another role (spec §2.1: one account, many roles).
class MyProfilesScreen extends ConsumerWidget {
  const MyProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final mine = ref.watch(myMarketProfilesProvider);
    final profiles = mine.value ?? const <MarketProfile>[];
    final taken = {
      for (final p in profiles)
        switch (p.subjectType) {
          'buyer' => RegistrationRole.fromName(p.kind),
          'broker' => RegistrationRole.broker,
          _ => null,
        },
    };
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.mlMyProfilesTitle)),
      body: mine.isLoading && !mine.hasValue
          ? LoadingState(label: t.loadingLabel)
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                0,
                BmSpace.lg,
                BmSpace.xxl,
              ),
              children: [
                if (mine.error case final error?)
                  MarketCallBanner(
                    error,
                    onRetry: () => ref.invalidate(myMarketProfilesProvider),
                  ),
                if (mine.hasValue && profiles.isEmpty)
                  EmptyNote(t.mlMyProfilesEmpty),
                for (final p in profiles) ...[
                  _OwnProfileCard(profile: p),
                  const SizedBox(height: BmSpace.sm),
                ],
                const SizedBox(height: BmSpace.sm),
                Text(t.mlRegisterAs, style: BmType.section),
                const SizedBox(height: BmSpace.xs),
                for (final role in RegistrationRole.values)
                  // A trader cannot also hold an exporter profile (one buyer profile, Q89).
                  if (!taken.contains(role) &&
                      !(role.index <= 1 &&
                          (taken.contains(RegistrationRole.trader) ||
                              taken.contains(RegistrationRole.exporter))))
                    Padding(
                      padding: const EdgeInsets.only(bottom: BmSpace.xs),
                      child: ChoiceCard(
                        key: Key('ml-register-${role.name}'),
                        label: roleLabel(t, role),
                        icon: switch (role) {
                          RegistrationRole.trader => Icons.storefront_rounded,
                          RegistrationRole.exporter => Icons.flight_rounded,
                          RegistrationRole.broker => Icons.handshake_rounded,
                          RegistrationRole.provider =>
                            Icons.local_shipping_rounded,
                        },
                        selected: false,
                        onTap: () =>
                            context.push(Routes.marketLinkRegister(role.name)),
                      ),
                    ),
              ],
            ),
    );
  }
}

class _OwnProfileCard extends ConsumerStatefulWidget {
  const _OwnProfileCard({required this.profile});

  final MarketProfile profile;

  @override
  ConsumerState<_OwnProfileCard> createState() => _OwnProfileCardState();
}

class _OwnProfileCardState extends ConsumerState<_OwnProfileCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    final t = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(myMarketProfilesProvider);
    } on MarketCallException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                e.problem == MarketCallProblem.offline
                    ? t.mlOffline
                    : t.mlServerBusy,
              ),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _photo(DocKind doc) async {
    DateTime? until;
    if (doc == DocKind.certificate) {
      final now = ref.read(clockProvider)();
      until = await showDatePicker(
        context: context,
        helpText: AppLocalizations.of(context).mlFieldCertUntil,
        initialDate: now,
        firstDate: now.subtract(const Duration(days: 365 * 3)),
        lastDate: now.add(const Duration(days: 365 * 5)),
      );
      if (until == null) return;
    }
    // The in-app camera only (no gallery): a document photographed now.
    final path = await ref
        .read(scoutingPhotosProvider)
        .pick(PhotoSource.camera);
    if (path == null) return;
    final p = widget.profile;
    await _run(() async {
      final bytes = await File(path).readAsBytes();
      await ref
          .read(registrationApiProvider)
          .addDocument(p.subjectType, p.id, doc, bytes, validUntil: until);
    });
  }

  Future<void> _address() async {
    final p = widget.profile;
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _AddressDialog(initial: p.address ?? ''),
    );
    if (value == null) return;
    await _run(
      () => ref
          .read(registrationApiProvider)
          .setAddress(p.subjectType, p.id, value.isEmpty ? null : value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final p = widget.profile;
    final (status, colour) = switch (p.status) {
      'approved' => (t.mlStatusApproved, c.brandStrong),
      'rejected' => (t.mlStatusRejected, c.danger),
      _ => (t.mlStatusPending, c.caution),
    };
    return BmCard(
      key: Key('ml-own-${p.id}'),
      elevated: false,
      radius: BmRadius.card,
      padding: const EdgeInsets.all(BmSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(profileKindLabel(t, p), style: BmType.meta),
          Text(p.name, style: BmType.cardTitle),
          Text(p.place, style: BmType.meta.copyWith(color: c.inkMuted)),
          const SizedBox(height: BmSpace.xs),
          Text(
            status,
            key: Key('ml-status-${p.id}'),
            style: BmType.bodyStrong.copyWith(color: colour),
          ),
          if (p.status == 'rejected' && p.reason != null)
            Text(p.reason!, style: BmType.body),
          if (p.status != 'approved') InfoNote(t.mlCheckNote),
          if (p.certificateExpired)
            Text(
              t.mlCertExpired(formatDate(p.certValidUntil!, lang)),
              style: BmType.bodyStrong.copyWith(color: c.danger),
            ),
          for (final b in p.badges)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.task_alt_rounded, size: 18, color: c.brand),
                const SizedBox(width: BmSpace.xs),
                Expanded(
                  child: Text(badgeText(t, b, lang), style: BmType.meta),
                ),
              ],
            ),
          if (p.documentKinds.isNotEmpty) ...[
            const SizedBox(height: BmSpace.sm),
            Text(
              t.mlDocsCount(formatInt(p.documents, lang)),
              style: BmType.formLabel,
            ),
            const SizedBox(height: BmSpace.xs),
            Wrap(
              spacing: BmSpace.xs,
              runSpacing: BmSpace.xs,
              children: [
                for (final doc in p.documentKinds)
                  ActionChip(
                    key: Key('ml-doc-${doc.name}-${p.id}'),
                    avatar: const Icon(Icons.photo_camera_rounded),
                    label: Text(docLabel(t, doc)),
                    onPressed: _busy ? null : () => _photo(doc),
                  ),
              ],
            ),
          ],
          const SizedBox(height: BmSpace.xs),
          if (p.address case final address?) Text(address, style: BmType.body),
          TextButton.icon(
            key: Key('ml-address-${p.id}'),
            onPressed: _busy ? null : _address,
            icon: const Icon(Icons.edit_location_alt_rounded),
            label: Text(p.address == null ? t.mlAddressAdd : t.mlAddressEdit),
          ),
        ],
      ),
    );
  }
}

/// The optional address (addendum 2): the owner types and changes it; saving sends it.
class _AddressDialog extends StatefulWidget {
  const _AddressDialog({required this.initial});

  final String initial;

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(t.mlFieldAddress),
      content: TextField(
        key: const Key('ml-address-input'),
        controller: _controller,
        maxLength: 300,
        minLines: 2,
        maxLines: 4,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.mlCancel),
        ),
        FilledButton(
          key: const Key('ml-address-save'),
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(t.mlSave),
        ),
      ],
    );
  }
}
