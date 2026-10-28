import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/glyphs.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../feed/domain/feed_item.dart';
import '../../voice/presentation/share_speak_buttons.dart';
import '../data/scheme_catalog.dart';

/// The checklist as text for the share sheet (a son in town, the CSC operator): which
/// documents the grower has and which are still to get, where to apply, and the
/// "check the official page" line.
String schemeShareText(
  AppLocalizations t,
  SchemesData data,
  Scheme scheme,
  Set<String> have,
  String lang,
  String productName,
) => [
  scheme.name(lang),
  scheme.summary(lang),
  '',
  t.schemeShareDocs(scheme.name(lang)),
  for (final d in scheme.documents)
    '${have.contains(d.key) ? '✔' : '☐'} ${data.documentLabel(d.key, lang)}'
        ' (${have.contains(d.key) ? t.schemeShareHave : t.schemeShareMissing})',
  '',
  '${t.schemeWhereToApply}:',
  for (final a in scheme.apply)
    a.url == null ? '• ${a.label(lang)}' : '• ${a.label(lang)}: ${a.url}',
  '',
  t.schemeWhoCheck,
  shareFooter(t, productName),
].join('\n');

Future<void> _copyLink(BuildContext context, String url) async {
  final t = AppLocalizations.of(context);
  await Clipboard.setData(ClipboardData(text: url));
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t.feedLinkCopied)));
  }
}

/// The schemes growers here ask about, each with how many of its documents the grower
/// ticked. General information only: no amounts and no eligibility decision.
class SchemesScreen extends ConsumerWidget {
  const SchemesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final data = ref.watch(schemesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.schemesTitle)),
      body: switch (data) {
        AsyncData(:final value) when value.schemes.isEmpty => EmptyState(
          glyph: BmGlyph.ledger,
          message: t.schemesIntro,
        ),
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.fromLTRB(
            BmSpace.lg,
            BmSpace.sm,
            BmSpace.lg,
            BmSpace.xxl,
          ),
          children: [
            Text(
              t.schemesIntro,
              style: BmType.body.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: BmSpace.md),
            for (final s in value.schemes)
              Padding(
                padding: const EdgeInsets.only(bottom: BmSpace.sm),
                child: _SchemeTile(scheme: s, lang: lang),
              ),
          ],
        ),
        _ => LoadingState(label: t.loadingLabel),
      },
    );
  }
}

class _SchemeTile extends ConsumerWidget {
  const _SchemeTile({required this.scheme, required this.lang});

  final Scheme scheme;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final have = ref.watch(schemeTicksProvider(scheme.id)).value ?? const {};
    final ready = scheme.documents.where((d) => have.contains(d.key)).length;
    return InkWell(
      key: Key('scheme-${scheme.id}'),
      borderRadius: BorderRadius.circular(BmRadius.card),
      onTap: () => context.push(Routes.scheme(scheme.id)),
      child: BmCard(
        elevated: false,
        radius: BmRadius.card,
        padding: const EdgeInsets.all(BmSpace.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scheme.name(lang), style: BmType.bodyStrong),
                  const SizedBox(height: BmSpace.xxs),
                  Text(
                    scheme.summary(lang),
                    style: BmType.body.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(height: BmSpace.xxs),
                  Text(
                    t.schemeDocsReady(ready, scheme.documents.length),
                    style: BmType.meta.copyWith(color: c.brandStrong),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// One scheme: what it is, who can apply (general, "check the official page"), the
/// document checklist the grower ticks on this phone, where to apply, related govt notices
/// from the feed, and the sources with the date they were checked.
class SchemeDetailScreen extends ConsumerWidget {
  const SchemeDetailScreen({super.key, required this.schemeId});

  final String schemeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final config = ref.watch(appConfigProvider);
    final data = ref.watch(schemesProvider).value;
    final ticks = ref.watch(schemeTicksProvider(schemeId));
    if (data == null || !ticks.hasValue) {
      return Scaffold(
        appBar: AppBar(title: Text(t.schemesTitle)),
        body: LoadingState(label: t.loadingLabel),
      );
    }
    final scheme = data.byId(schemeId);
    if (scheme == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.schemesTitle)),
        body: EmptyState(glyph: BmGlyph.ledger, message: t.schemesIntro),
      );
    }
    final have = ticks.value!;
    final now = ref.watch(clockProvider)();
    final feedItems = config.sarkariSandeshEnabled
        ? scheme.matchingFeedItems(
            ref.watch(feedProvider(lang)).value?.page.items ??
                const <FeedItem>[],
            now,
          )
        : const <FeedItem>[];
    final store = ref.read(schemeTicksStoreProvider);
    final notConfirmed = BmType.meta.copyWith(color: c.inkMuted);
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: BmSpace.lg, bottom: BmSpace.xs),
      child: Text(title, style: BmType.section.copyWith(color: c.brand)),
    );
    Widget link(Key key, String label, String url, {String? note}) => Semantics(
      button: true,
      hint: t.feedCopyLink,
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(BmRadius.chip),
        onTap: () => _copyLink(context, url),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: BmSpace.tapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: BmSpace.xs),
            child: Row(
              children: [
                Icon(Icons.link, color: c.brandStrong),
                const SizedBox(width: BmSpace.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: BmType.bodyStrong),
                      Text(
                        url,
                        style: BmType.meta.copyWith(color: c.brandStrong),
                      ),
                      if (note != null)
                        Text(
                          note,
                          style: BmType.meta.copyWith(color: c.inkMuted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(scheme.name(lang)),
        actions: [
          ShareSpeakButtons(
            keyPrefix: 'scheme',
            shareText: schemeShareText(
              t,
              data,
              scheme,
              have,
              lang,
              config.productName,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BmSpace.lg,
          BmSpace.sm,
          BmSpace.lg,
          BmSpace.xxl,
        ),
        children: [
          Text(scheme.summary(lang), style: BmType.body),
          section(t.schemeWho),
          Text(scheme.whoCanApply(lang), style: BmType.body),
          const SizedBox(height: BmSpace.xxs),
          Text(
            t.schemeWhoCheck,
            style: BmType.bodyStrong.copyWith(color: c.accentInk),
          ),
          section(t.schemeDocuments),
          Text(
            t.schemeDocumentsHint,
            style: BmType.meta.copyWith(color: c.inkMuted),
          ),
          Text(
            t.schemeDocsReady(
              scheme.documents.where((d) => have.contains(d.key)).length,
              scheme.documents.length,
            ),
            style: BmType.meta.copyWith(color: c.brandStrong),
          ),
          for (final d in scheme.documents)
            CheckboxListTile(
              key: Key('scheme-doc-${d.key}'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: have.contains(d.key),
              onChanged: (v) => store.set(scheme.id, d.key, has: v ?? false),
              title: Text(data.documentLabel(d.key, lang), style: BmType.body),
              subtitle: d.verified
                  ? null
                  : Text(t.schemeNotConfirmed, style: notConfirmed),
            ),
          section(t.schemeWhereToApply),
          for (final (i, a) in scheme.apply.indexed)
            if (a.url case final url?)
              link(
                Key('scheme-apply-$i'),
                a.label(lang),
                url,
                note: a.verified ? null : t.schemeNotConfirmed,
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: BmSpace.tapTarget),
                child: Row(
                  children: [
                    Icon(Icons.place_outlined, color: c.brandStrong),
                    const SizedBox(width: BmSpace.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.label(lang), style: BmType.bodyStrong),
                          if (!a.verified)
                            Text(t.schemeNotConfirmed, style: notConfirmed),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          if (feedItems.isNotEmpty) ...[
            section(t.schemeFeedItems),
            for (final item in feedItems)
              ListTile(
                key: Key('scheme-feed-${item.id}'),
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.account_balance_outlined, color: c.brand),
                title: Text(item.title, style: BmType.bodyStrong),
                subtitle: Text(
                  formatDate(item.publishedAt, lang),
                  style: BmType.meta,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(Routes.feedItem(item.id)),
              ),
          ],
          section(t.schemeSources(formatDate(data.checkedOn, lang))),
          for (final (i, s) in scheme.sources.indexed)
            link(Key('scheme-source-$i'), s.title, s.url),
        ],
      ),
    );
  }
}
