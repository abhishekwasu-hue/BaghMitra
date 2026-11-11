import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glyphs.dart';

/// Risk alert. The icon tile pulses gently to draw the eye unless reduced motion is on.
/// With [onToggle] the ⚠ tile is also a 48 dp button that switches this alert type off
/// (owner Q133); [AlertOffLine] then takes the card's place.
class AlertBanner extends StatefulWidget {
  const AlertBanner({
    super.key,
    required this.title,
    required this.body,
    this.onTap,
    this.actions,
    this.onToggle,
    this.toggleLabel,
    this.toggleKey,
  });

  final String title;
  final String body;
  final VoidCallback? onTap;

  /// Switches this alert type off; null keeps the tile a plain icon.
  final VoidCallback? onToggle;

  /// Read aloud for the ⚠ button, e.g. "हा अलर्ट बंद करा".
  final String? toggleLabel;
  final Key? toggleKey;

  /// Small actions under the text (read aloud, share), right-aligned.
  final Widget? actions;

  @override
  State<AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<AlertBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: BmMotion.pulse,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced || TickerMode.valuesOf(context).enabled == false) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    return Semantics(
      liveRegion: true,
      button: widget.onTap != null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(BmSpace.md, 14, BmSpace.md, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: c.warnBg,
              ),
              border: Border.all(color: c.warnBorder, width: 1.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tile(c),
                const SizedBox(width: BmSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: BmType.alertTitle.copyWith(color: c.warnTitle),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.body,
                        style: BmType.meta.copyWith(
                          color: c.warnBody,
                          height: 1.4,
                        ),
                      ),
                      if (widget.actions case final actions?)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: actions,
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
  }

  Widget _tile(BmColors c) {
    final tile = ScaleTransition(
      scale: Tween(
        begin: 1.0,
        end: 1.08,
      ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
      child: Container(
        width: 42,
        height: 42,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: c.accent,
          borderRadius: BorderRadius.circular(BmRadius.chip),
        ),
        child: const GlyphIcon(BmGlyph.warning),
      ),
    );
    return switch (widget.onToggle) {
      final toggle? => _AlertToggle(
        key: widget.toggleKey,
        label: widget.toggleLabel ?? '',
        onTap: toggle,
        child: tile,
      ),
      null => tile,
    };
  }
}

/// What stays of an alert type the grower switched off: one muted line, with the same
/// button (an "alerts off" icon) to switch it on again.
class AlertOffLine extends StatelessWidget {
  const AlertOffLine({
    super.key,
    required this.label,
    required this.toggleLabel,
    required this.onToggle,
    this.toggleKey,
  });

  /// E.g. "सायला अलर्ट बंद".
  final String label;

  /// Read aloud for the button, e.g. "हा अलर्ट चालू करा".
  final String toggleLabel;
  final VoidCallback onToggle;
  final Key? toggleKey;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    return Row(
      children: [
        _AlertToggle(
          key: toggleKey,
          label: toggleLabel,
          onTap: onToggle,
          child: Icon(
            Icons.notifications_off_outlined,
            size: 22,
            color: c.inkMuted,
          ),
        ),
        const SizedBox(width: BmSpace.xxs),
        Expanded(
          child: Text(label, style: BmType.meta.copyWith(color: c.inkMuted)),
        ),
      ],
    );
  }
}

/// The on / off button: [child] centred in a 48 dp tap target, read as [label].
class _AlertToggle extends StatelessWidget {
  const _AlertToggle({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: label,
    onTap: onTap,
    excludeSemantics: true,
    child: InkResponse(
      onTap: onTap,
      radius: BmSpace.tapTarget / 2,
      child: SizedBox.square(
        dimension: BmSpace.tapTarget,
        child: Center(child: child),
      ),
    ),
  );
}
