import '../domain/feed_item.dart';
import 'feed_repository.dart';

/// A small built-in feed for demo and test builds, so the tab works with no backend. Every
/// entry is clearly a sample (no real GR, scheme or news claim) and every link points at
/// example.org. Dates are relative to [clock] so deadlines stay in the future.
class DemoFeedRepository implements FeedRepository {
  const DemoFeedRepository({required this.clock});

  final DateTime Function() clock;

  static String _pick(Map<String, String> m, String lang) =>
      m[lang] ?? m['en']!;

  static const _dept = {
    'en': 'Sample Agriculture Department',
    'mr': 'नमुना कृषी विभाग',
    'hi': 'नमूना कृषि विभाग',
  };

  static const _footer = {
    'en': 'Sample data only: not real orders, schemes or news.',
    'mr': 'ही फक्त नमुना माहिती आहे: खरे आदेश, योजना किंवा बातम्या नाहीत.',
    'hi': 'यह केवल नमूना जानकारी है: असली आदेश, योजनाएँ या ख़बरें नहीं.',
  };

  @override
  Future<FeedPage> fetch({required String lang, FeedFilter? filter}) async {
    final now = clock().toUtc();
    DateTime ago(int days) => now.subtract(Duration(days: days));
    DateTime ahead(int days) {
      final d = now.add(Duration(days: days));
      return DateTime(d.year, d.month, d.day);
    }

    String s(Map<String, String> m) => _pick(m, lang);
    final items = [
      FeedItem(
        id: 'sample-gr-1',
        type: 'gr',
        trust: 'official',
        title: s(const {
          'en': 'Sample GR: drip irrigation subsidy (demo)',
          'mr': 'नमुना GR: ठिबक सिंचन अनुदान (डेमो)',
          'hi': 'नमूना GR: ड्रिप सिंचाई अनुदान (डेमो)',
        }),
        summary: s(const {
          'en': 'This is sample text to show how a GR looks in the app. It is not a real order.',
          'mr': 'GR ॲपमध्ये कसा दिसतो हे दाखवण्यासाठी हा नमुना मजकूर आहे. हा खरा आदेश नाही.',
          'hi': 'GR ऐप में कैसा दिखता है यह दिखाने के लिए यह नमूना पाठ है. यह असली आदेश नहीं है.',
        }),
        department: s(_dept),
        grNumber: 'SAMPLE-0001',
        publishedAt: ago(1),
        url: 'https://example.org/sample/gr-0001',
        deadline: ahead(20),
        validTo: ahead(60),
        mayBeEligibleBecause: [
          s(const {
            'en': 'you grow fruit trees (sample reason)',
            'mr': 'तुमची फळबाग आहे (नमुना कारण)',
            'hi': 'आपका फलों का बाग है (नमूना कारण)',
          }),
        ],
      ),
      FeedItem(
        id: 'sample-scheme-1',
        type: 'scheme',
        trust: 'official',
        title: s(const {
          'en': 'Sample scheme: orchard insurance (demo)',
          'mr': 'नमुना योजना: फळबाग विमा (डेमो)',
          'hi': 'नमूना योजना: बाग बीमा (डेमो)',
        }),
        summary: s(const {
          'en': 'Sample scheme text. Real schemes appear here once the feed is connected.',
          'mr': 'नमुना योजनेचा मजकूर. फीड जोडल्यावर इथे खऱ्या योजना दिसतील.',
          'hi': 'नमूना योजना का पाठ. फीड जुड़ने पर यहाँ असली योजनाएँ दिखेंगी.',
        }),
        department: s(_dept),
        grNumber: 'SAMPLE-0002',
        publishedAt: ago(3),
        url: 'https://example.org/sample/scheme-0002',
        deadline: ahead(10),
        mayBeEligibleBecause: [
          s(const {
            'en': 'your district is in the sample list',
            'mr': 'तुमचा जिल्हा नमुना यादीत आहे',
            'hi': 'आपका ज़िला नमूना सूची में है',
          }),
        ],
      ),
      FeedItem(
        id: 'sample-circular-1',
        type: 'circular',
        trust: 'official',
        title: s(const {
          'en': 'Sample circular: old application form (demo)',
          'mr': 'नमुना परिपत्रक: जुना अर्ज नमुना (डेमो)',
          'hi': 'नमूना परिपत्र: पुराना आवेदन फॉर्म (डेमो)',
        }),
        summary: s(const {
          'en': 'Sample of a withdrawn circular.',
          'mr': 'मागे घेतलेल्या परिपत्रकाचा नमुना.',
          'hi': 'वापस लिए गए परिपत्र का नमूना.',
        }),
        department: s(_dept),
        grNumber: 'SAMPLE-0003',
        publishedAt: ago(9),
        url: 'https://example.org/sample/circular-0003',
        replacedBy: 'SAMPLE-0001',
      ),
      FeedItem(
        id: 'sample-alert-1',
        type: 'alert',
        trust: 'official',
        title: s(const {
          'en': 'Sample alert: weather advisory (demo)',
          'mr': 'नमुना सूचना: हवामान सल्ला (डेमो)',
          'hi': 'नमूना सूचना: मौसम सलाह (डेमो)',
        }),
        summary: s(const {
          'en': 'Sample alert text.',
          'mr': 'नमुना सूचनेचा मजकूर.',
          'hi': 'नमूना सूचना का पाठ.',
        }),
        department: s(_dept),
        publishedAt: ago(2),
        url: 'https://example.org/sample/alert-0004',
      ),
      FeedItem(
        id: 'sample-news-1',
        type: 'news',
        trust: 'news',
        title: s(const {
          'en': 'Sample news: mandi arrivals rise (demo)',
          'mr': 'नमुना बातमी: बाजारात आवक वाढली (डेमो)',
          'hi': 'नमूना ख़बर: मंडी में आवक बढ़ी (डेमो)',
        }),
        summary: s(const {
          'en': 'Sample news summary. News is not an official order.',
          'mr': 'नमुना बातमीचा सारांश. बातमी म्हणजे अधिकृत आदेश नाही.',
          'hi': 'नमूना ख़बर का सार. ख़बर आधिकारिक आदेश नहीं है.',
        }),
        publishedAt: ago(4),
        url: 'https://example.org/sample/news-0005',
      ),
    ];
    return FeedPage(
      items: [
        for (final i in items)
          if (filter == null || filter.matches(i)) i,
      ],
      footer: s(_footer),
    );
  }
}
