import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../app_update/data/app_update_providers.dart';

/// Phone settings, the introduction, sending the on-device log and the app version; shown in
/// every build (audit R2). Only the test-build label and the sample orchard (demo mode) are
/// limited to those builds.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final config = ref.watch(appConfigProvider);
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(BmSpace.lg),
        children: [
          if (config.isTestBuild)
            Text(t.buildLabel(config.testBuild), style: BmType.meta),
          if (ref.watch(installedVersionProvider).value case final v?)
            Text(
              t.settingsVersion(v.name, '${v.code}'),
              key: const Key('settings-version'),
              style: BmType.meta,
            ),
          const SizedBox(height: BmSpace.lg),
          OutlinedButton(
            key: const Key('settings-profile'),
            onPressed: () => context.push(Routes.profile),
            child: Text(t.profileTitle),
          ),
          const SizedBox(height: BmSpace.md),
          // Sample data only where nothing syncs, so it can never reach a real account.
          if (config.demoMode) ...[
            OutlinedButton(
              key: const Key('seed-orchard'),
              onPressed: () async {
                await ref.read(sampleOrchardProvider).run();
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(t.seedOrchardDone)));
                }
              },
              child: Text(t.seedOrchard),
            ),
            const SizedBox(height: BmSpace.md),
          ],
          FilledButton(
            key: const Key('settings-feedback'),
            onPressed: () => context.push(Routes.feedback),
            child: Text(t.feedbackTitle),
          ),
          const SizedBox(height: BmSpace.md),
          OutlinedButton(
            key: const Key('send-logs'),
            onPressed: () async {
              final text = await ref.read(appLogProvider).read();
              await ref
                  .read(fileSharerProvider)
                  .share(
                    fileName: 'bagmitra-logs.txt',
                    bytes: utf8.encode(text.isEmpty ? '(empty)' : text),
                    mimeType: 'text/plain',
                  );
            },
            child: Text(t.sendLogs),
          ),
          const SizedBox(height: BmSpace.md),
          OutlinedButton(
            key: const Key('show-walkthrough'),
            onPressed: () => context.push(Routes.walkthrough),
            child: Text(t.settingsShowWalkthrough),
          ),
          const SizedBox(height: BmSpace.md),
          SwitchListTile(
            key: const Key('photo-backup-mobile-data'),
            contentPadding: EdgeInsets.zero,
            title: Text(t.settingsPhotoMobileData, style: BmType.body),
            subtitle: Text(t.settingsPhotoMobileDataHint, style: BmType.meta),
            value: ref.watch(photoBackupMobileDataProvider).value ?? false,
            onChanged: (on) =>
                ref.read(photoBackupMobileDataProvider.notifier).set(on),
          ),
        ],
      ),
    );
  }
}
