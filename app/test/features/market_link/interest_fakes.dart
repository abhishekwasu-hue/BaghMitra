import 'package:bagmitra/features/market_link/data/interest_api.dart';
import 'package:bagmitra/features/market_link/domain/deal_rating.dart';
import 'package:bagmitra/features/market_link/domain/interest.dart';
import 'package:bagmitra/features/market_link/domain/registration.dart';

import 'market_link_fakes.dart';

BuyerLot sampleBuyerLot({String id = 'l1'}) => BuyerLot(
  id: id,
  crop: 'santra',
  variety: 'नागपुरी',
  quantityT: 12.5,
  quality: 'मोठी · ए ग्रेड',
  harvestFrom: DateTime(2026, 12),
  harvestTo: DateTime(2026, 12, 20),
  basis: 'per_tonne',
  askingRatePaise: 3000000,
  village: 'वरुड',
  taluka: 'वरुड',
  district: 'अमरावती',
);

Interest sampleInterest({
  String id = 'i1',
  int ratePaise = 3200000,
  InterestStatus status = InterestStatus.open,
  bool viaBroker = false,
  String? dealId,
}) => Interest(
  id: id,
  lotId: 'l1',
  basis: 'per_tonne',
  ratePaise: ratePaise,
  quantityT: 12,
  harvestDate: DateTime(2026, 12, 5),
  status: status,
  viaBroker: viaBroker,
  dealId: dealId,
);

const sampleLotBrief = LotBrief(
  id: 'l1',
  crop: 'santra',
  variety: 'नागपुरी',
  quantityT: 12.5,
  basis: 'per_tonne',
  village: 'वरुड',
  taluka: 'वरुड',
  district: 'अमरावती',
  status: 'published',
);

/// A checked trader's own profile (the sender acts as a trader).
MarketProfile ownTrader({String status = 'approved'}) => MarketProfile(
  subjectType: 'buyer',
  id: 'b-me',
  kind: 'trader',
  name: 'मी',
  phone: '+919800000009',
  district: 'अमरावती',
  status: status,
);

MarketProfile ownBroker() => const MarketProfile(
  subjectType: 'broker',
  id: 'k-me',
  kind: 'broker',
  name: 'मी',
  phone: '+919800000009',
  district: 'अमरावती',
  status: 'approved',
);

class FakeInterestApi implements InterestApi {
  FakeInterestApi({
    this.buyerLots = const [],
    this.sentList = const [],
    this.onLotList = const [],
    this.error,
    this.acceptError,
    Introduction? intro,
    this.dealRatings,
    this.tags = const [],
  }) : intro = intro ?? sampleIntroduction();

  List<BuyerLot> buyerLots;
  List<SentInterest> sentList;
  List<LotInterest> onLotList;
  Object? error;
  Object? acceptError;
  final sent = <(String, InterestDraft)>[];
  final accepted = <String>[];
  Introduction intro;
  DealRatings? dealRatings;
  List<RatingTagItem> tags;
  final doneTaps = <String>[];
  final rated = <(DealRole, List<RatingAnswer>)>[];

  void _fail() {
    if (error != null) throw error!;
  }

  @override
  Future<List<BuyerLot>> lots() async {
    _fail();
    return buyerLots;
  }

  @override
  Future<Interest> send(String lotId, InterestDraft draft) async {
    _fail();
    sent.add((lotId, draft));
    return sampleInterest();
  }

  @override
  Future<List<SentInterest>> mine() async {
    _fail();
    return sentList;
  }

  @override
  Future<List<LotInterest>> onLot(String lotId) async {
    _fail();
    return onLotList;
  }

  @override
  Future<String> accept(String interestId) async {
    if (acceptError != null) throw acceptError!;
    accepted.add(interestId);
    return 'd1';
  }

  @override
  Future<Introduction> introduction(String dealId) async {
    _fail();
    return intro;
  }

  @override
  Future<Introduction> dealDone(String dealId) async {
    _fail();
    doneTaps.add(dealId);
    return intro = sampleIntroduction(
      state: sampleState(
        grower: true,
        trader: intro.state.traderDoneAt != null,
      ),
    );
  }

  @override
  Future<DealRatings> ratings(String dealId) async {
    _fail();
    return dealRatings ?? sampleRatings();
  }

  @override
  Future<DealRatings> rate(
    String dealId,
    DealRole ratee,
    List<RatingAnswer> answers,
  ) async {
    _fail();
    rated.add((ratee, answers));
    final before = dealRatings ?? sampleRatings();
    return dealRatings = DealRatings(
      state: before.state,
      questions: before.questions,
      given: {...before.given, ratee: answers},
    );
  }

  @override
  Future<List<RatingTagItem>> ratingTags() async {
    _fail();
    return tags;
  }
}

final _done = DateTime.utc(2026, 12, 10, 6);

/// The caller's state: grower by default, nothing tapped.
DealState sampleState({
  DealRole role = DealRole.grower,
  bool grower = false,
  bool trader = false,
  bool locked = false,
}) => DealState(
  myRole: role,
  rates: role == DealRole.grower
      ? const [DealRole.trader, DealRole.broker]
      : const [DealRole.grower],
  growerDoneAt: grower ? _done : null,
  traderDoneAt: trader ? _done : null,
  completedAt: grower && trader ? _done : null,
  ratingUntil: grower && trader ? _done.add(const Duration(days: 7)) : null,
  ratingLocked: locked,
);

DealRatings sampleRatings({
  DealState? state,
  Map<DealRole, List<RatingAnswer>> given = const {},
}) => DealRatings(
  state: state ?? sampleState(grower: true, trader: true),
  questions: const {
    DealRole.trader: [
      'trader_on_date',
      'trader_weighing_correct',
      'trader_paid_as_agreed',
      'trader_kept_conditions',
    ],
    DealRole.broker: ['broker_honest', 'broker_trader_kept_deal'],
    DealRole.grower: ['grower_produce_matched', 'grower_ready_on_date'],
  },
  given: given,
);

RatingTagItem sampleTag(
  String id,
  String question,
  String mr, {
  bool good = true,
}) => RatingTagItem(
  id: id,
  questionKey: question,
  polarity: good ? 'positive' : 'negative',
  labels: {'mr': mr, 'hi': mr, 'en': id},
);

final sampleTags = [
  sampleTag('t1', 'trader_on_date', 'ठरलेल्या तारखेला आले'),
  sampleTag('t2', 'trader_on_date', 'उशिरा आले', good: false),
  sampleTag('t3', 'trader_paid_as_agreed', 'उचल व बाकी पैसे ठरल्याप्रमाणे'),
  sampleTag('t4', 'trader_paid_as_agreed', 'पैसे उशिरा', good: false),
  sampleTag('t5', 'broker_honest', 'व्यवहार प्रामाणिकपणे सांगितला'),
];

Introduction sampleIntroduction({bool broker = true, DealState? state}) =>
    Introduction(
      dealId: 'd1',
      acceptedAt: DateTime.utc(2026, 11, 7, 6),
      lot: sampleLotBrief,
      interest: sampleInterest(status: InterestStatus.accepted, dealId: 'd1'),
      grower: const Contact(name: 'रमेश पाटील', phone: '+919812345678'),
      growerPlace: 'वरुड, अमरावती',
      plotName: 'घराजवळची बाग',
      pin: (lat: 21.2751, lon: 78.5853),
      trader: const Contact(
        name: 'सुनील शिंदे',
        firm: 'शिंदे फ्रुट्स',
        phone: '+919800000001',
      ),
      broker: broker
          ? const Contact(name: 'सुरेश वानखडे', phone: '+919800000002')
          : null,
      state: state ?? sampleState(),
    );

/// Keeps the import of the shared fakes used (sample people for the pickers).
final samplePeople = [sampleTrader(), sampleBroker()];
