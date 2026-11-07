import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/formatting.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/cards.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/registration_api.dart';
import '../domain/registration.dart';
import 'profile_widgets.dart';

/// Where a list looks: the grower's own taluka, own district, or everywhere. Chips from
/// the grower's profile, so nobody types a place name (big choices, spec UI rules).
enum AreaScope { taluka, district, all }

typedef PeopleQuery = ({
  String role,
  String sort,
  String? taluka,
  String? district,
});

final marketPeopleProvider =
    FutureProvider.family<List<MarketProfile>, PeopleQuery>(
      (ref, q) => ref
          .read(registrationApiProvider)
          .people(
            role: q.role,
            sort: q.sort,
            taluka: q.taluka,
            district: q.district,
          ),
    );

typedef ProfileRef = ({String subjectType, String id});

final marketProfileProvider = FutureProvider.family<MarketProfile, ProfileRef>(
  (ref, r) => ref.read(registrationApiProvider).profile(r.subjectType, r.id),
);

/// Area chips from the grower's profile; [onPick] gets the scope.
class AreaChips extends ConsumerWidget {
  const AreaChips({super.key, required this.scope, required this.onPick});

  final AreaScope scope;
  final ValueChanged<AreaScope> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider).value;
    return Wrap(
      spacing: BmSpace.xs,
      runSpacing: BmSpace.xs,
      children: [
        if (profile?.taluka case final taluka?)
          ChoiceChip(
            key: const Key('ml-area-taluka'),
            label: Text(t.mlAreaTaluka(taluka)),
            selected: scope == AreaScope.taluka,
            onSelected: (_) => onPick(AreaScope.taluka),
          ),
        if (profile?.district case final district?)
          ChoiceChip(
            key: const Key('ml-area-district'),
            label: Text(t.mlAreaDistrict(district)),
            selected: scope == AreaScope.district,
            onSelected: (_) => onPick(AreaScope.district),
          ),
        ChoiceChip(
          key: const Key('ml-area-all'),
          label: Text(t.mlAreaAll),
          selected: scope == AreaScope.all,
          onSelected: (_) => onPick(AreaScope.all),
        ),
      ],
    );
  }
}

({String? taluka, String? district}) areaFilter(WidgetRef ref, AreaScope s) {
  final profile = ref.watch(profileProvider).value;
  return switch (s) {
    AreaScope.taluka => (taluka: profile?.taluka, district: profile?.district),
    AreaScope.district => (taluka: null, district: profile?.district),
    AreaScope.all => (taluka: null, district: null),
  };
}

/// The list per taluka (decision g): verified traders, exporters and brokers, sorted by
/// rating or completed deals. Grower profiles are never listed.
class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  String _role = 'trader';
  String _sort = 'rating';
  AreaScope? _scope;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scope =
        _scope ??
        (ref.watch(profileProvider).value?.taluka != null
            ? AreaScope.taluka
            : AreaScope.all);
    final area = areaFilter(ref, scope);
    final query = (
      role: _role,
      sort: _sort,
      taluka: area.taluka,
      district: area.district,
    );
    final people = ref.watch(marketPeopleProvider(query));
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.mlPeopleTitle)),
      body: ListView(
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
              for (final (role, label) in [
                ('trader', t.mlRoleTrader),
                ('exporter', t.mlRoleExporter),
                ('broker', t.mlRoleBroker),
              ])
                ChoiceChip(
                  key: Key('ml-role-$role'),
                  label: Text(label),
                  selected: _role == role,
                  onSelected: (_) => setState(() => _role = role),
                ),
            ],
          ),
          const SizedBox(height: BmSpace.xs),
          AreaChips(scope: scope, onPick: (s) => setState(() => _scope = s)),
          const SizedBox(height: BmSpace.xs),
          Wrap(
            spacing: BmSpace.xs,
            children: [
              for (final (sort, label) in [
                ('rating', t.mlSortRating),
                ('deals', t.mlSortDeals),
              ])
                ChoiceChip(
                  key: Key('ml-sort-$sort'),
                  label: Text(label),
                  selected: _sort == sort,
                  onSelected: (_) => setState(() => _sort = sort),
                ),
            ],
          ),
          const SizedBox(height: BmSpace.md),
          if (people.error case final error?)
            MarketCallBanner(
              error,
              onRetry: () => ref.invalidate(marketPeopleProvider(query)),
            )
          else if (!people.hasValue)
            LoadingState(label: t.loadingLabel)
          else if (people.value!.isEmpty)
            EmptyNote(t.mlPeopleEmpty)
          else
            for (final p in people.value!) ...[
              ProfileCard(
                profile: p,
                onTap: () =>
                    context.push(Routes.marketLinkProfile(p.subjectType, p.id)),
              ),
              const SizedBox(height: BmSpace.sm),
            ],
          const SizedBox(height: BmSpace.sm),
          InfoNote(t.mlBadgeNote),
        ],
      ),
    );
  }
}

/// One verified public profile: everything on the card, plus crops, areas, address, the
/// average stars per question and the count of each ticked tag; the phone to call.
class ProfileDetailScreen extends ConsumerWidget {
  const ProfileDetailScreen({
    super.key,
    required this.subjectType,
    required this.id,
  });

  final String subjectType;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final key = (subjectType: subjectType, id: id);
    final profile = ref.watch(marketProfileProvider(key));
    final p = profile.value;
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(p?.name ?? t.mlPeopleTitle)),
      bottomNavigationBar: p == null
          ? null
          : BottomActions(
              children: [
                FilledButton.icon(
                  key: const Key('ml-call-main'),
                  onPressed: () => ref.read(phoneDialerProvider)(p.phone),
                  icon: const Icon(Icons.call_rounded),
                  label: Text(t.mlCallNumber(p.phone)),
                ),
              ],
            ),
      body: p == null
          ? profile.hasError
                ? ListView(
                    padding: const EdgeInsets.all(BmSpace.lg),
                    children: [
                      MarketCallBanner(
                        profile.error!,
                        onRetry: () =>
                            ref.invalidate(marketProfileProvider(key)),
                      ),
                    ],
                  )
                : LoadingState(label: t.loadingLabel)
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                BmSpace.lg,
                0,
                BmSpace.lg,
                BmSpace.xxl,
              ),
              children: [
                ProfileCard(profile: p),
                const SizedBox(height: BmSpace.md),
                if (p.crops.isNotEmpty)
                  _Line(t.mlFieldCrops, cropsText(p.crops, lang)),
                if (p.markets.isNotEmpty)
                  _Line(t.mlMarkets, p.markets.join(', ')),
                if (p.areas.isNotEmpty) _Line(t.mlAreas, p.areas.join(', ')),
                if (p.vehicleNumbers.isNotEmpty)
                  _Line(t.mlFieldVehicles, p.vehicleNumbers.join(', ')),
                if (p.capacityT case final cap?)
                  _Line(t.mlFieldCapacity, formatDecimal(cap, lang)),
                if (p.address case final address?)
                  _Line(t.mlFieldAddress, address),
                if (p.stars.isNotEmpty) ...[
                  const SizedBox(height: BmSpace.sm),
                  Text(t.mlRatingsTitle, style: BmType.section),
                  for (final s in p.stars)
                    _Line(
                      questionLabel(t, s.questionKey),
                      t.mlStars(
                        formatDecimal(s.average, lang),
                        formatInt(s.count, lang),
                      ),
                    ),
                ],
                if (p.tags.isNotEmpty) ...[
                  const SizedBox(height: BmSpace.sm),
                  Wrap(
                    spacing: BmSpace.xs,
                    runSpacing: BmSpace.xs,
                    children: [
                      for (final tag in p.tags)
                        Chip(
                          label: Text(
                            '${tag.label(lang)} · ${formatInt(tag.count, lang)}',
                            style: BmType.meta.copyWith(
                              color: tag.polarity == 'positive'
                                  ? c.brandStrong
                                  : c.danger,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: BmSpace.md),
                InfoNote(t.mlBadgeNote),
              ],
            ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: BmSpace.xs),
    child: BmCard(
      elevated: false,
      radius: BmRadius.tile,
      padding: const EdgeInsets.all(BmSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: BmType.meta),
          Text(value, style: BmType.bodyStrong),
        ],
      ),
    ),
  );
}
