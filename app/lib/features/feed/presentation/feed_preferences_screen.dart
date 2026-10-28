import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design_system/sync_banner.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/feed_repository.dart';
import '../domain/feed_preferences.dart';

/// Sarkari Sandesh alert settings: quiet hours, how many alerts a week, which alert kinds,
/// and the weekly summary. Loaded from the server on open; offline the last saved values
/// are shown and saving is switched off until the phone is online.
class FeedPreferencesScreen extends ConsumerStatefulWidget {
  const FeedPreferencesScreen({super.key});

  @override
  ConsumerState<FeedPreferencesScreen> createState() =>
      _FeedPreferencesScreenState();
}

class _FeedPreferencesScreenState extends ConsumerState<FeedPreferencesScreen> {
  FeedPreferences? _prefs;
  bool _online = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await ref.read(feedPreferencesStoreProvider).load();
    if (!mounted) return;
    setState(() {
      _prefs = loaded.prefs.copyWith(weeklyCap: loaded.prefs.shownWeeklyCap);
      _online = loaded.online;
    });
  }

  /// Applies [change] to the current values (never to a copy captured by an older build).
  void _edit(FeedPreferences Function(FeedPreferences p) change) =>
      setState(() => _prefs = change(_prefs!));

  Future<void> _pickTime({required bool start}) async {
    final p = _prefs!;
    final (h, m) = FeedPreferences.parseHhmm(start ? p.quietStart : p.quietEnd);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: h, minute: m),
    );
    if (picked == null || !mounted) return;
    final v = FeedPreferences.hhmm(picked.hour, picked.minute);
    _edit((p) => start ? p.copyWith(quietStart: v) : p.copyWith(quietEnd: v));
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final stored = await ref.read(feedPreferencesStoreProvider).save(_prefs!);
      if (!mounted) return;
      setState(
        () => _prefs = stored.copyWith(weeklyCap: stored.shownWeeklyCap),
      );
      messenger.showSnackBar(SnackBar(content: Text(t.feedPrefsSaved)));
    } on FeedUnavailableException {
      messenger.showSnackBar(SnackBar(content: Text(t.feedPrefsSaveFailed)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _time(String hhmm) {
    final (h, m) = FeedPreferences.parseHhmm(hhmm);
    return MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay(hour: h, minute: m));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = _prefs;
    final categories = {
      'deadline': t.feedPrefsCatDeadline,
      'payment': t.feedPrefsCatPayment,
      'window_open': t.feedPrefsCatWindowOpen,
    };
    return Scaffold(
      appBar: AppBar(title: Text(t.feedPrefsTitle)),
      body: p == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(BmSpace.lg),
              children: [
                if (!_online)
                  // The same offline strip as Home, not a one-off box.
                  Padding(
                    padding: const EdgeInsets.only(bottom: BmSpace.md),
                    child: SyncBanner(
                      key: const Key('feed-prefs-offline'),
                      kind: SyncBannerKind.offline,
                      message: t.feedPrefsOffline,
                    ),
                  ),
                Text(t.feedPrefsQuietTitle, style: BmType.bodyStrong),
                ListTile(
                  key: const Key('feed-prefs-quiet-start'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bedtime_outlined),
                  title: Text(t.feedPrefsQuietStart),
                  trailing: Text(_time(p.quietStart), style: BmType.bodyStrong),
                  onTap: () => _pickTime(start: true),
                ),
                ListTile(
                  key: const Key('feed-prefs-quiet-end'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.wb_sunny_outlined),
                  title: Text(t.feedPrefsQuietEnd),
                  trailing: Text(_time(p.quietEnd), style: BmType.bodyStrong),
                  onTap: () => _pickTime(start: false),
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.feedPrefsWeeklyCap('${p.weeklyCap}'),
                        key: const Key('feed-prefs-cap'),
                        style: BmType.bodyStrong,
                      ),
                    ),
                    IconButton(
                      key: const Key('feed-prefs-cap-less'),
                      tooltip: t.feedPrefsCapLess,
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: p.weeklyCap > FeedPreferences.minWeeklyCap
                          ? () => _edit(
                              (p) => p.copyWith(weeklyCap: p.weeklyCap - 1),
                            )
                          : null,
                    ),
                    IconButton(
                      key: const Key('feed-prefs-cap-more'),
                      tooltip: t.feedPrefsCapMore,
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: p.weeklyCap < FeedPreferences.maxWeeklyCap
                          ? () => _edit(
                              (p) => p.copyWith(weeklyCap: p.weeklyCap + 1),
                            )
                          : null,
                    ),
                  ],
                ),
                const Divider(),
                Text(t.feedPrefsCategoriesTitle, style: BmType.bodyStrong),
                for (final MapEntry(key: cat, value: label)
                    in categories.entries)
                  SwitchListTile(
                    key: Key('feed-prefs-cat-$cat'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(label),
                    value: !p.optedOut.contains(cat),
                    onChanged: (on) =>
                        _edit((p) => p.withCategory(cat, on: on)),
                  ),
                const Divider(),
                SwitchListTile(
                  key: const Key('feed-prefs-digest'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.feedPrefsDigest),
                  subtitle: Text(t.feedPrefsDigestHint),
                  value: p.digestWeekly,
                  onChanged: (on) => _edit((p) => p.copyWith(digestWeekly: on)),
                ),
                const SizedBox(height: BmSpace.md),
                FilledButton(
                  key: const Key('feed-prefs-save'),
                  onPressed: _online && !_saving ? _save : null,
                  child: Text(t.feedPrefsSave),
                ),
              ],
            ),
    );
  }
}
