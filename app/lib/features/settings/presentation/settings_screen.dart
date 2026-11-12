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
import '../../photo_analysis/domain/offline_check.dart';
import '../../push/domain/push_topics.dart';

/// Phone settings, the introduction, sending the on-device log, the app version and the photo
/// model's data sources (CC BY attribution); shown in every build (audit R2). Only the
/// test-build label and the sample orchard (demo mode) are limited to those builds.
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
          const SizedBox(height: BmSpace.lg),
          const _PushTopicSwitches(),
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
          // CC BY 4.0 attribution of the photo model's data sets (Q135), folded away.
          ExpansionTile(
            key: const Key('settings-model-sources'),
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            expandedAlignment: AlignmentDirectional.centerStart,
            title: Text(t.settingsModelSources, style: BmType.body),
            children: [
              Text(t.settingsModelSourcesIntro, style: BmType.meta),
              for (final c in offlineModelCitations)
                Padding(
                  padding: const EdgeInsets.only(top: BmSpace.xs),
                  child: Text('• $c', style: BmType.meta),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "सूचना": the three update pushes the server sends (Q147), each on unless switched off.
/// A change is kept on the phone and reaches the server when the network is there.
class _PushTopicSwitches extends ConsumerWidget {
  const _PushTopicSwitches();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final topics = ref.watch(pushTopicsProvider).value ?? PushTopics.defaults;
    final rows = [
      (
        PushTopic.articles,
        Icons.menu_book_rounded,
        t.settingsPushArticles,
        t.settingsPushArticlesHint,
      ),
      (
        PushTopic.market,
        Icons.currency_rupee_rounded,
        t.settingsPushMarket,
        t.settingsPushMarketHint,
      ),
      (
        PushTopic.weather,
        Icons.cloud_rounded,
        t.settingsPushWeather,
        t.settingsPushWeatherHint,
      ),
    ];
    return Column(
      key: const Key('settings-notifications'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.settingsNotifications, style: BmType.section),
        for (final (topic, icon, title, hint) in rows)
          SwitchListTile(
            key: Key('push-topic-${topic.name}'),
            contentPadding: EdgeInsets.zero,
            secondary: Icon(icon, color: context.bm.brand),
            title: Text(title, style: BmType.body),
            subtitle: Text(hint, style: BmType.meta),
            value: topics.isOn(topic),
            onChanged: (on) =>
                ref.read(pushTopicsProvider.notifier).set(topic, on: on),
          ),
      ],
    );
  }
}
