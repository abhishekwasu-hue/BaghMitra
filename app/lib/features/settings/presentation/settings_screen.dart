import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';

/// Test-build tools: which build this is, and sending the on-device log.
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
        ],
      ),
    );
  }
}
