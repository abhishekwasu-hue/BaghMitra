import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/feed_repository.dart';
import '../domain/feed_check.dart';

/// "Check this message": the grower pastes a forwarded message and the server looks for
/// official items that match. It only says whether an official GR was found; it never
/// calls a message fake. The text lives in this screen's memory only, never on the phone.
class FeedCheckScreen extends ConsumerStatefulWidget {
  const FeedCheckScreen({super.key});

  @override
  ConsumerState<FeedCheckScreen> createState() => _FeedCheckScreenState();
}

class _FeedCheckScreenState extends ConsumerState<FeedCheckScreen> {
  final _text = TextEditingController();
  FeedCheckResult? _result;
  bool _checking = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = data?.text;
    if (pasted == null || pasted.isEmpty || !mounted) return;
    _text.text = pasted;
  }

  Future<void> _check() async {
    final lang = Localizations.localeOf(context).languageCode;
    setState(() {
      _checking = true;
      _failed = false;
      _result = null;
    });
    try {
      final result = await ref
          .read(feedRepositoryProvider)
          .check(_text.text.trim(), lang: lang);
      if (mounted) setState(() => _result = result);
    } on FeedUnavailableException {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final result = _result;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.feedCheckTitle,
          style: BmType.section.copyWith(color: c.brand),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(BmSpace.lg),
        children: [
          Text(t.feedCheckIntro, style: BmType.body),
          const SizedBox(height: BmSpace.sm),
          TextField(
            key: const Key('feed-check-text'),
            controller: _text,
            minLines: 4,
            maxLines: 10,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: t.feedCheckHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: BmSpace.xxs),
          Text(t.feedCheckPrivacy, style: BmType.meta),
          const SizedBox(height: BmSpace.sm),
          Wrap(
            spacing: BmSpace.xs,
            runSpacing: BmSpace.xs,
            children: [
              OutlinedButton.icon(
                key: const Key('feed-check-paste'),
                icon: const Icon(Icons.content_paste),
                label: Text(t.feedCheckPaste),
                onPressed: _paste,
              ),
              FilledButton.icon(
                key: const Key('feed-check-go'),
                icon: const Icon(Icons.search),
                label: Text(t.feedCheckButton),
                onPressed: _checking || _text.text.trim().isEmpty
                    ? null
                    : _check,
              ),
            ],
          ),
          if (_checking)
            const Padding(
              padding: EdgeInsets.all(BmSpace.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_failed)
            Padding(
              key: const Key('feed-check-failed'),
              padding: const EdgeInsets.only(top: BmSpace.md),
              child: Text(
                t.feedCheckFailed,
                style: BmType.body.copyWith(color: c.warnTitle),
              ),
            ),
          if (result != null) ...[
            const SizedBox(height: BmSpace.md),
            _ResultCard(result: result),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final FeedCheckResult result;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    final verdict = result.verdict;
    final official = verdict == FeedCheckVerdict.officialMatch;
    final headline = switch (verdict) {
      FeedCheckVerdict.officialMatch => t.feedCheckOfficial,
      FeedCheckVerdict.possibleMatch => t.feedCheckPossible,
      FeedCheckVerdict.noOfficialMatch =>
        result.note.isEmpty ? t.feedCheckNoMatch : result.note,
    };
    return Container(
      key: Key('feed-check-result-${verdict.value}'),
      padding: const EdgeInsets.all(BmSpace.md),
      decoration: BoxDecoration(
        color: official ? c.brandSoft : c.card,
        borderRadius: BorderRadius.circular(BmRadius.tile),
        border: Border.all(color: official ? c.brand : c.warnBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                official ? Icons.verified_outlined : Icons.info_outline,
                color: official ? c.brandStrong : c.warnTitle,
              ),
              const SizedBox(width: BmSpace.xs),
              Expanded(child: Text(headline, style: BmType.cardTitle)),
            ],
          ),
          if (verdict != FeedCheckVerdict.noOfficialMatch)
            for (final m in result.matches) _MatchTile(match: m),
          if (verdict != FeedCheckVerdict.noOfficialMatch &&
              result.note.isNotEmpty) ...[
            const SizedBox(height: BmSpace.xs),
            Text(result.note, style: BmType.meta),
          ],
          if (verdict != FeedCheckVerdict.officialMatch) ...[
            const SizedBox(height: BmSpace.xs),
            Text(
              t.feedCheckPortal,
              key: const Key('feed-check-portal'),
              style: BmType.bodyStrong,
            ),
          ],
        ],
      ),
    );
  }
}

/// One matching official item: title, GR number and date, its link and a copy button.
class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match});

  final FeedCheckMatch match;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final meta = [
      if (match.grNumber case final n?) t.feedGrNumber(n),
      if (match.publishedAt case final d?) formatDate(d.toLocal(), lang),
    ].join(' · ');
    return Padding(
      key: Key('feed-check-match-${match.id}'),
      padding: const EdgeInsets.only(top: BmSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(match.title, style: BmType.bodyStrong),
          if (meta.isNotEmpty) Text(meta, style: BmType.meta),
          SelectableText(t.feedSource(match.url), style: BmType.meta),
          TextButton.icon(
            key: Key('feed-check-copy-${match.id}'),
            icon: const Icon(Icons.link),
            label: Text(t.feedCopyLink),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: match.url));
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(t.feedLinkCopied)));
              }
            },
          ),
        ],
      ),
    );
  }
}
