import 'package:chopper/chopper.dart';
import 'package:flutter/material.dart';

import '../api/generated/bagmitra.enums.swagger.dart' as enums;
import '../api/generated/bagmitra.swagger.dart';
import '../design_system/cards.dart';
import '../design_system/empty_state.dart';
import '../design_system/glyphs.dart';
import '../theme/app_theme.dart';
import 'kb_admin_repository.dart' show KbAdminException;
import 'market_link_safety_pages.dart' show OpenPhoto, adminDate, launchPhoto;

/// Role that reads the in-app feedback (API `/v1/admin/feedback`).
const feedbackAdminRole = 'feedback_admin';

abstract interface class FeedbackAdminRepository {
  /// [status] null: every message, newest first.
  Future<List<FeedbackOut>> list({String? status});
  Future<FeedbackOut> mark(String id, String status);
}

class ApiFeedbackAdminRepository implements FeedbackAdminRepository {
  const ApiFeedbackAdminRepository(this._api);
  final Bagmitra _api;

  static T _ok<T>(Response<T> res) {
    final body = res.body;
    if (res.isSuccessful && body != null) return body;
    throw KbAdminException('HTTP ${res.statusCode}');
  }

  @override
  Future<List<FeedbackOut>> list({String? status}) async =>
      _ok(await _api.v1AdminFeedbackGet(status: status)).feedback;

  @override
  Future<FeedbackOut> mark(String id, String status) async => _ok(
    await _api.v1AdminFeedbackFeedbackIdPut(
      feedbackId: id,
      body: StatusIn(status: enums.StatusInStatus.values.byName(status)),
    ),
  );
}

/// Admin-web-only words (Marathi first, English fallback), like the package strings.
String feedbackText(BuildContext context, String key) {
  final lang = Localizations.localeOf(context).languageCode;
  return (_text[lang] ?? _text['en']!)[key] ?? _text['en']![key] ?? key;
}

const _text = {
  'mr': {
    'section': 'अभिप्राय',
    'new': 'नवीन',
    'seen': 'पाहिले',
    'done': 'पूर्ण',
    'all': 'सर्व',
    'problem': 'अडचण',
    'suggestion': 'सूचना',
    'question': 'प्रश्न',
    'screenshot': 'screenshot पाहा',
    'empty': 'या यादीत अभिप्राय शिल्लक नाही.',
  },
  'en': {
    'section': 'Feedback',
    'new': 'New',
    'seen': 'Seen',
    'done': 'Done',
    'all': 'All',
    'problem': 'Problem',
    'suggestion': 'Suggestion',
    'question': 'Question',
    'screenshot': 'Open screenshot',
    'empty': 'This list is clear.',
  },
};

/// The feedback list: newest first, filter by state, open the screenshot, mark seen / done.
class FeedbackAdminPage extends StatefulWidget {
  const FeedbackAdminPage({required this.repo, this.openPhoto, super.key});
  final FeedbackAdminRepository repo;
  final OpenPhoto? openPhoto;

  @override
  State<FeedbackAdminPage> createState() => _FeedbackAdminPageState();
}

class _FeedbackAdminPageState extends State<FeedbackAdminPage> {
  String? _status = 'new';
  List<FeedbackOut>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.repo.list(status: _status);
      if (mounted) setState(() => _items = items);
    } on KbAdminException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _mark(FeedbackOut f, String status) async {
    await widget.repo.mark(f.id, status);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    String s(String k) => feedbackText(context, k);
    final c = context.bm;
    if (_error case final e?) return Text(e, style: BmType.body);
    final items = _items;
    final colors = {
      'problem': c.danger,
      'suggestion': c.brandStrong,
      'question': c.warnTitle,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: BmSpace.sm,
          children: [
            for (final status in ['new', 'seen', 'done', null])
              ChoiceChip(
                key: Key('fb-filter-${status ?? 'all'}'),
                label: Text(s(status ?? 'all')),
                selected: _status == status,
                onSelected: (_) {
                  setState(() {
                    _status = status;
                    _items = null;
                  });
                  _load();
                },
              ),
          ],
        ),
        const SizedBox(height: BmSpace.md),
        Expanded(
          child: items == null
              ? LoadingState(label: s('section'))
              : items.isEmpty
              ? EmptyState(glyph: BmGlyph.home, title: s('empty'), message: '')
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: BmSpace.sm),
                  itemBuilder: (context, i) {
                    final f = items[i];
                    return BmCard(
                      key: Key('fb-${f.id}'),
                      elevated: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s(f.kind)} · ${adminDate(f.createdAt)} · ${s(f.status)}',
                            style: BmType.bodyStrong.copyWith(
                              color: colors[f.kind] ?? c.ink,
                            ),
                          ),
                          const SizedBox(height: BmSpace.xxs),
                          SelectableText(f.text, style: BmType.body),
                          const SizedBox(height: BmSpace.xxs),
                          Text(
                            '${f.device} · ${f.appVersion}',
                            style: BmType.meta.copyWith(color: c.inkMuted),
                          ),
                          Wrap(
                            spacing: BmSpace.sm,
                            children: [
                              if (f.screenshotUrl case final url?)
                                TextButton.icon(
                                  icon: const Icon(Icons.image_outlined),
                                  label: Text(s('screenshot')),
                                  onPressed: () =>
                                      (widget.openPhoto ?? launchPhoto)(
                                        Uri.parse(url),
                                      ),
                                ),
                              for (final next in ['seen', 'done'])
                                if (f.status != next)
                                  TextButton(
                                    key: Key('fb-${f.id}-$next'),
                                    onPressed: () => _mark(f, next),
                                    child: Text(s(next)),
                                  ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
