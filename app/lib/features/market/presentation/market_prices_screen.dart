import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/generated/bagmitra.swagger.dart';
import '../../../app/providers.dart';
import '../../../app/refresh.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../../sync/presentation/refresh_note.dart';
import '../../../theme/app_theme.dart';
import '../../voice/presentation/share_speak_buttons.dart';
import '../data/market_prices_cache.dart';
import '../domain/market_labels.dart';

/// Mandi prices for the grower's crop, exactly as the API published them (never estimated),
/// from the phone's cache so the list works offline. Mandi, state and variety names are
/// shown in the grower's language where known ([marketLabel]), else as the source wrote them.
class MarketPricesScreen extends ConsumerStatefulWidget {
  const MarketPricesScreen({super.key});

  @override
  ConsumerState<MarketPricesScreen> createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends ConsumerState<MarketPricesScreen> {
  var _scope = V1MarketPricesGetScope.all;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final crop = ref.watch(marketCropProvider);
    final loaded = ref.watch(marketPricesProvider((crop, _scope)));
    final cached = loaded.value;
    final prices = cached?.prices.prices ?? const <MarketPriceOut>[];
    String rs(int? v) => v == null ? '–' : formatRupees(v, lang);
    Future<void> refresh() =>
        ref.read(refresherProvider).marketPrices(crop, _scope);

    final scopes = {
      V1MarketPricesGetScope.all: t.marketScopeAll,
      V1MarketPricesGetScope.local: t.marketScopeLocal,
      V1MarketPricesGetScope.major: t.marketScopeMajor,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(t.marketPricesTitle),
        actions: [
          IconButton(
            key: const Key('open-market-directory'),
            tooltip: t.marketDirectoryOpen,
            icon: Icon(Icons.store_mall_directory_outlined, color: c.brand),
            onPressed: () => context.push(Routes.marketDirectory),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(BmSpace.lg),
          children: [
            Wrap(
              spacing: BmSpace.xs,
              children: [
                for (final MapEntry(key: scope, value: label) in scopes.entries)
                  ChoiceChip(
                    key: Key('market-scope-${scope.value}'),
                    label: Text(label),
                    selected: _scope == scope,
                    onSelected: (_) => setState(() => _scope = scope),
                  ),
              ],
            ),
            const SizedBox(height: BmSpace.xs),
            RefreshNote(
              cacheKey: MarketPricesCache.keyFor(crop, _scope),
              updated: cached == null
                  ? null
                  : t.marketUpdated(
                      formatDateTime(cached.savedAt.toLocal(), lang),
                    ),
              onRetry: refresh,
            ),
            if (cached != null && cached.prices.stale)
              // The server sends a reason code; the grower sees plain words for it.
              Text(switch (cached.prices.reason) {
                final String reason => t.marketStale(reason),
                null => t.marketStaleNoReason,
              }, style: BmType.meta.copyWith(color: c.accentInk)),
            if (prices.isEmpty)
              loaded.isLoading && !loaded.hasValue
                  ? LoadingState(label: t.loadingLabel)
                  : EmptyNote(t.marketEmpty),
            for (final p in prices)
              // A plain row, not a ListTile: a ListTile caps the trailing price's height,
              // which clipped it at larger text sizes.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: BmSpace.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: BmSpace.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                marketLabel(p.market, lang),
                                style: BmType.bodyStrong,
                              ),
                              if (p.isLocal) _Tag(t.marketTagLocal),
                              if (p.isMajor) _Tag(t.marketTagMajor),
                            ],
                          ),
                          Text(
                            '${marketStateLabel(p.state, lang)} · '
                            '${formatDate(p.day, lang)}',
                            style: BmType.meta,
                          ),
                          if (p.minRsPerQuintal != null ||
                              p.maxRsPerQuintal != null)
                            Text(
                              t.marketRange(
                                rs(p.minRsPerQuintal),
                                rs(p.maxRsPerQuintal),
                              ),
                              style: BmType.meta,
                            ),
                          if (p.variety case final variety?)
                            Text(
                              t.marketVariety(
                                marketVarietyLabel(variety, lang),
                              ),
                              style: BmType.meta,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: BmSpace.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          rs(p.modalRsPerQuintal),
                          style: BmType.cardTitle.copyWith(color: c.brand),
                        ),
                        Text(t.marketPerQuintal, style: BmType.meta),
                        ShareSpeakButtons(
                          keyPrefix:
                              'market-${p.market}-${p.day.toIso8601String()}',
                          shareText: marketPriceShareText(
                            t,
                            p,
                            lang,
                            ref.watch(appConfigProvider).productName,
                          ),
                          speakText: marketPriceShareText(t, p, lang, null),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A small label marking a local APMC or a major terminal market.
class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.brandSoft,
        borderRadius: BorderRadius.circular(BmRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BmSpace.xs,
          vertical: BmSpace.xxs,
        ),
        child: Text(text, style: BmType.label.copyWith(color: c.ink)),
      ),
    );
  }
}

/// What sharing a mandi price hands on: market and modal price, the min–max range, state
/// and day, the source and (unless read aloud, [productName] null) where it came from.
/// Exactly the published numbers, never an estimate.
String marketPriceShareText(
  AppLocalizations t,
  MarketPriceOut p,
  String lang,
  String? productName,
) {
  String rs(int? v) => v == null ? '–' : formatRupees(v, lang);
  return [
    t.marketShareLine(marketLabel(p.market, lang), rs(p.modalRsPerQuintal)),
    if (p.minRsPerQuintal != null || p.maxRsPerQuintal != null)
      t.marketRange(rs(p.minRsPerQuintal), rs(p.maxRsPerQuintal)),
    if (p.variety case final variety?)
      t.marketVariety(marketVarietyLabel(variety, lang)),
    '${marketStateLabel(p.state, lang)} · ${formatDate(p.day, lang)}',
    t.shareSource(p.source),
    if (productName != null) shareFooter(t, productName),
  ].join('\n');
}
