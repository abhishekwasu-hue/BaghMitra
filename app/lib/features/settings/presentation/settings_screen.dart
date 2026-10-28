import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';

/// Test-build tools (which build this is, sending the on-device log) and phone settings.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final config = ref.watch(appConfigProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(BmSpace.lg),
        children: [
          if (config.isTestBuild)
            Text(t.buildLabel(config.testBuild), style: BmType.meta),
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
