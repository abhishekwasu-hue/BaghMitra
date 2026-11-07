import 'package:bagmitra/features/market_link/data/interest_api.dart';
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
  });

  List<BuyerLot> buyerLots;
  List<SentInterest> sentList;
  List<LotInterest> onLotList;
  Object? error;
  final sent = <(String, InterestDraft)>[];

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
}

/// Keeps the import of the shared fakes used (sample people for the pickers).
final samplePeople = [sampleTrader(), sampleBroker()];
