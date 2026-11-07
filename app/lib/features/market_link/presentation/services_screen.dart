import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design_system/app_bar_title.dart';
import '../../../design_system/empty_state.dart';
import '../../../design_system/info_note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/registration_api.dart';
import '../domain/registration.dart';
import 'people_screen.dart';
import 'profile_widgets.dart';

typedef ServicesQuery = ({
  ProviderKind? kind,
  String? taluka,
  String? district,
  String? plotId,
});

final marketServicesProvider =
    FutureProvider.family<List<MarketProfile>, ServicesQuery>(
      (ref, q) => ref
          .read(registrationApiProvider)
          .providers(
            kind: q.kind,
            taluka: q.taluka,
            district: q.district,
            plotId: q.plotId,
          ),
    );

/// The service directory near a plot (spec v1.5 §3 step 6): verified weighbridges,
/// transporters, labour gangs and crate suppliers, nearest first, with a phone number to
/// call. No booking: they agree and pay among themselves.
class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  ProviderKind? _kind;
  AreaScope _scope = AreaScope.all;
  String? _plotId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final plots = ref.watch(plotsProvider).value ?? const [];
    final plotId =
        _plotId ?? plots.where((p) => p.centroidLat != null).firstOrNull?.id;
    final area = areaFilter(ref, _scope);
    final query = (
      kind: _kind,
      taluka: area.taluka,
      district: area.district,
      plotId: plotId,
    );
    final services = ref.watch(marketServicesProvider(query));
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.mlServicesTitle)),
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
              ChoiceChip(
                key: const Key('ml-type-all'),
                label: Text(t.directoryAll),
                selected: _kind == null,
                onSelected: (_) => setState(() => _kind = null),
              ),
              for (final k in ProviderKind.values)
                ChoiceChip(
                  key: Key('ml-type-${k.api}'),
                  label: Text(providerKindLabel(t, k)),
                  selected: _kind == k,
                  onSelected: (_) => setState(() => _kind = k),
                ),
            ],
          ),
          const SizedBox(height: BmSpace.xs),
          AreaChips(scope: _scope, onPick: (s) => setState(() => _scope = s)),
          if (plots.length > 1) ...[
            const SizedBox(height: BmSpace.xs),
            Wrap(
              spacing: BmSpace.xs,
              runSpacing: BmSpace.xs,
              children: [
                for (final p in plots)
                  ChoiceChip(
                    key: Key('ml-plot-${p.id}'),
                    label: Text(t.mlNearPlot(p.name)),
                    selected: plotId == p.id,
                    onSelected: (_) => setState(() => _plotId = p.id),
                  ),
              ],
            ),
          ],
          const SizedBox(height: BmSpace.md),
          if (services.error case final error?)
            MarketCallBanner(
              error,
              onRetry: () => ref.invalidate(marketServicesProvider(query)),
            )
          else if (!services.hasValue)
            LoadingState(label: t.loadingLabel)
          else if (services.value!.isEmpty)
            EmptyNote(t.mlServicesEmpty)
          else
            for (final p in services.value!) ...[
              ProfileCard(profile: p),
              const SizedBox(height: BmSpace.sm),
            ],
          const SizedBox(height: BmSpace.sm),
          InfoNote(t.mlServicesNote),
        ],
      ),
    );
  }
}
