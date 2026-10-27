import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';

/// A few swipeable pages, shown once on a new phone, saying in plain words what the app does.
/// Facts about the app only: no farming advice and no promises.
class WalkthroughScreen extends ConsumerStatefulWidget {
  const WalkthroughScreen({super.key});

  @override
  ConsumerState<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends ConsumerState<WalkthroughScreen> {
  final _pages = PageController();
  var _page = 0;
  var _leaving = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_leaving) return;
    _leaving = true;
    await ref.read(walkthroughSeenProvider.notifier).markSeen();
    if (!mounted) return;
    // Opened again from settings: back to where it came from. First run: on to sign-in/setup.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final pages = [
      (Icons.calendar_month, t.walkthroughPlotsTitle, t.walkthroughPlotsBody),
      (
        Icons.cloud_outlined,
        t.walkthroughWeatherTitle,
        t.walkthroughWeatherBody,
      ),
      (Icons.storefront, t.walkthroughMarketTitle, t.walkthroughMarketBody),
      (Icons.receipt_long, t.walkthroughRecordsTitle, t.walkthroughRecordsBody),
    ];
    final last = _page == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BmSpace.xl),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: BmSpace.tapTarget,
                  child: last
                      ? null
                      : TextButton(
                          key: const Key('walkthrough-skip'),
                          onPressed: _finish,
                          child: Text(t.walkthroughSkip, style: BmType.label),
                        ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    for (final (icon, title, body) in pages)
                      _Page(icon: icon, title: title, body: body),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(
                        horizontal: BmSpace.xxs,
                      ),
                      width: i == _page ? BmSpace.lg : BmSpace.xs,
                      height: BmSpace.xs,
                      decoration: BoxDecoration(
                        color: i == _page ? c.brand : c.line,
                        borderRadius: BorderRadius.circular(BmSpace.xxs),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: BmSpace.xl),
              if (last)
                FilledButton(
                  key: const Key('walkthrough-start'),
                  onPressed: _finish,
                  child: Text(t.walkthroughStart),
                )
              else
                FilledButton(
                  key: const Key('walkthrough-next'),
                  onPressed: () => _pages.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  ),
                  child: Text(t.walkthroughNext),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.bm;
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: BmSpace.xxl),
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: c.brandSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: c.brand),
          ),
          const SizedBox(height: BmSpace.xxl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: BmType.title.copyWith(color: c.brand),
          ),
          const SizedBox(height: BmSpace.md),
          Text(body, textAlign: TextAlign.center, style: BmType.body),
        ],
      ),
    );
  }
}
