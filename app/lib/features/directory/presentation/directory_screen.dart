import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../voice/presentation/share_speak_buttons.dart';
import '../data/directory_config.dart';

/// Labs and experts near Nagpur / Vidarbha / Marathwada (ICAR-CCRI, Dr. PDKV, KVKs,
/// soil testing), from config (research gap #8).
class LabDirectoryScreen extends StatelessWidget {
  const LabDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) => _DirectoryScreen(
    title: AppLocalizations.of(context).labsTitle,
    provider: labDirectoryProvider,
    keyPrefix: 'labs',
  );
}

/// Markets, buyers and processing for santra / mosambi, from config (research gap #3).
/// A directory only: no trading, no offers, no price forecasts.
class MarketDirectoryScreen extends StatelessWidget {
  const MarketDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) => _DirectoryScreen(
    title: AppLocalizations.of(context).marketDirectoryTitle,
    provider: marketDirectoryProvider,
    keyPrefix: 'markets',
  );
}

String _kindLabel(AppLocalizations t, String kind) => switch (kind) {
  'research' => t.directoryKindResearch,
  'university' => t.directoryKindUniversity,
  'kvk' => t.directoryKindKvk,
  'soil_lab' => t.directoryKindSoilLab,
  'portal' => t.directoryKindPortal,
  'apmc' => t.directoryKindApmc,
  'export' => t.directoryKindExport,
  _ => t.directoryKindProcessor,
};

/// What sharing an entry hands on: name, district, what it offers, phone, address and web
/// page, exactly as listed, and (unless read aloud, [productName] null) where it came from.
String directoryShareText(
  AppLocalizations t,
  DirectoryData data,
  DirectoryEntry e,
  String lang,
  String? productName,
) => [
  e.nameIn(lang),
  data.districtLabel(e.district, lang),
  e.offersIn(lang),
  if (e.phone case final phone?) t.directoryPhone(phone),
  ?e.address,
  if (productName != null) t.directoryWebPage(e.url),
  if (!e.verified) t.directoryUnverified,
  if (productName != null) shareFooter(t, productName),
].join('\n');

Future<void> _copy(BuildContext context, String text, String done) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(done)));
  }
}

class _DirectoryScreen extends ConsumerStatefulWidget {
  const _DirectoryScreen({
    required this.title,
    required this.provider,
    required this.keyPrefix,
  });

  final String title;
  final FutureProvider<DirectoryData> provider;
  final String keyPrefix;

  @override
  ConsumerState<_DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<_DirectoryScreen> {
  String? _district;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final data = ref.watch(widget.provider).value;
    final prefix = widget.keyPrefix;
    final entries = data?.inDistrict(_district) ?? const <DirectoryEntry>[];
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: data == null
          ? LoadingState(label: t.loadingLabel)
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                0,
                BmSpace.lg,
                BmSpace.xxl,
              ),
              children: [
                Wrap(
                  spacing: BmSpace.xs,
                  runSpacing: BmSpace.xs,
                  children: [
                    ChoiceChip(
                      key: Key('$prefix-district-all'),
                      label: Text(t.directoryAll),
                      selected: _district == null,
                      onSelected: (_) => setState(() => _district = null),
                    ),
                    for (final d in data.districtsInUse)
                      ChoiceChip(
                        key: Key('$prefix-district-$d'),
                        label: Text(data.districtLabel(d, lang)),
                        selected: _district == d,
                        onSelected: (_) => setState(() => _district = d),
                      ),
                  ],
                ),
                const SizedBox(height: BmSpace.md),
                if (entries.isEmpty) EmptyNote(t.directoryEmpty),
                for (final e in entries) ...[
                  _EntryCard(entry: e, data: data, keyPrefix: prefix),
                  const SizedBox(height: BmSpace.sm),
                ],
                const SizedBox(height: BmSpace.sm),
                Text(
                  t.directoryCheckLine,
                  style: BmType.meta.copyWith(color: c.inkMuted),
                ),
              ],
            ),
    );
  }
}

class _EntryCard extends ConsumerWidget {
  const _EntryCard({
    required this.entry,
    required this.data,
    required this.keyPrefix,
  });

  final DirectoryEntry entry;
  final DirectoryData data;
  final String keyPrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final e = entry;
    final id = e.id;
    return BmCard(
      key: Key('$keyPrefix-entry-$id'),
      elevated: false,
      radius: BmRadius.card,
      padding: const EdgeInsets.all(BmSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.nameIn(lang), style: BmType.bodyStrong),
                    Text(
                      '${data.districtLabel(e.district, lang)} · '
                      '${_kindLabel(t, e.kind)}',
                      style: BmType.meta,
                    ),
                  ],
                ),
              ),
              ShareSpeakButtons(
                keyPrefix: '$keyPrefix-$id',
                shareText: directoryShareText(
                  t,
                  data,
                  e,
                  lang,
                  ref.watch(appConfigProvider).productName,
                ),
                speakText: directoryShareText(t, data, e, lang, null),
              ),
            ],
          ),
          if (!e.verified)
            Padding(
              padding: const EdgeInsets.only(top: BmSpace.xxs),
              child: Text(
                t.directoryUnverified,
                style: BmType.meta.copyWith(color: c.accentInk),
              ),
            ),
          const SizedBox(height: BmSpace.xs),
          Text(e.offersIn(lang), style: BmType.body),
          if (e.address case final address?) ...[
            const SizedBox(height: BmSpace.xs),
            Text(address, style: BmType.meta),
          ],
          if (e.phone case final phone?)
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.directoryPhone(phone),
                    style: BmType.bodyStrong,
                  ),
                ),
                IconButton(
                  key: Key('$keyPrefix-copy-phone-$id'),
                  tooltip: t.directoryCopyNumber,
                  color: c.brandStrong,
                  constraints: const BoxConstraints(
                    minWidth: BmSpace.tapTarget,
                    minHeight: BmSpace.tapTarget,
                  ),
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () =>
                      _copy(context, phone, t.directoryNumberCopied),
                ),
              ],
            ),
          _LinkRow(
            key: Key('$keyPrefix-link-$id'),
            url: e.url,
            onTap: () => _copy(context, e.url, t.feedLinkCopied),
          ),
          if (e.source != e.url)
            Text(
              t.directoryDetailsFrom(e.source),
              style: BmType.meta.copyWith(color: c.inkMuted),
            ),
          if (e.checked case final checked?)
            Text(
              t.directoryChecked(formatDate(checked, lang)),
              style: BmType.meta.copyWith(color: c.inkMuted),
            ),
        ],
      ),
    );
  }
}

/// The entry's web page as a row at least 48 dp tall: tapping copies the link (the app
/// opens no browser), as on feed items.
class _LinkRow extends StatelessWidget {
  const _LinkRow({super.key, required this.url, required this.onTap});

  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    return Semantics(
      button: true,
      hint: t.directoryCopyLink,
      child: InkWell(
        borderRadius: BorderRadius.circular(BmRadius.chip),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: BmSpace.tapTarget),
          child: Row(
            children: [
              Icon(Icons.link, color: c.brandStrong),
              const SizedBox(width: BmSpace.xs),
              Expanded(
                child: Text(
                  t.directoryWebPage(url),
                  style: BmType.meta.copyWith(color: c.brandStrong),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
