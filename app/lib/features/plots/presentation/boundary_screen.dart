import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../design_system/bottom_actions.dart';
import '../../../design_system/cards.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/location_service.dart';
import '../domain/geo.dart';

/// Marks a block's boundary by standing at each corner and tapping once. The position is read
/// only when the grower taps (nothing is tracked in the background). Returns the corners.
class BoundaryScreen extends ConsumerStatefulWidget {
  const BoundaryScreen({super.key});

  @override
  ConsumerState<BoundaryScreen> createState() => _BoundaryScreenState();
}

class _BoundaryScreenState extends ConsumerState<BoundaryScreen> {
  final _corners = <LatLon>[];
  final _accuracies = <double?>[];
  LocationProblem? _problem;
  var _reading = false;

  Future<void> _add() async {
    if (_reading) return;
    setState(() => _reading = true);
    final r = await ref.read(locationServiceProvider).current();
    if (!mounted) return;
    setState(() {
      _reading = false;
      _problem = r.problem;
      if (r.position != null) {
        _corners.add(r.position!);
        _accuracies.add(r.accuracyM);
      }
    });
  }

  void _undo() => setState(() {
    _corners.removeLast();
    _accuracies.removeLast();
    _problem = null;
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final lang = Localizations.localeOf(context).languageCode;
    final problemText = switch (_problem) {
      LocationProblem.serviceOff => t.boundaryServiceOff,
      LocationProblem.denied => t.boundaryDenied,
      LocationProblem.deniedForever => t.boundaryDeniedForever,
      LocationProblem.failed => t.boundaryFailed,
      null => null,
    };
    return Scaffold(
      appBar: AppBar(title: Text(t.boundaryTitle)),
      body: ListView(
        padding: const EdgeInsets.all(BmSpace.lg),
        children: [
          Text(t.boundaryHelp, style: BmType.body),
          const SizedBox(height: BmSpace.md),
          BmCard(
            elevated: false,
            radius: BmRadius.card,
            padding: const EdgeInsets.all(BmSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.boundaryCorners(_corners.length),
                  style: BmType.section.copyWith(color: c.brand),
                ),
                if (_corners.length >= 3)
                  Text(
                    t.boundaryArea(
                      formatDecimal(sqMToAcres(polygonAreaSqM(_corners)), lang),
                    ),
                    style: BmType.body,
                  ),
                for (final a in _accuracies)
                  if (a != null)
                    Text(
                      t.boundaryAccuracy(
                        formatDecimal(a.roundToDouble(), lang),
                      ),
                      style: BmType.label.copyWith(color: c.inkMuted),
                    ),
              ],
            ),
          ),
          if (problemText != null) ...[
            const SizedBox(height: BmSpace.md),
            Text(problemText, style: BmType.body.copyWith(color: c.danger)),
          ],
        ],
      ),
      bottomNavigationBar: BottomActions(
        stacked: true,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _corners.isEmpty ? null : _undo,
                  child: Text(t.boundaryUndo),
                ),
              ),
              const SizedBox(width: BmSpace.sm),
              Expanded(
                child: FilledButton(
                  onPressed: _reading ? null : _add,
                  child: Text(t.boundaryAdd),
                ),
              ),
            ],
          ),
          FilledButton(
            onPressed: _corners.length >= 3
                ? () => context.pop(List<LatLon>.of(_corners))
                : null,
            child: Text(t.boundaryDone),
          ),
        ],
      ),
    );
  }
}
