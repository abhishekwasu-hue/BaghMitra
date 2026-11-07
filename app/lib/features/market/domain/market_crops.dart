/// The fruits a grower can pick on the market-prices screen, in the owner's order, with their
/// names. The key is the crop key the price API takes (`market_commodities` on the server).
/// Adding a fruit is one line here; a fruit the server has no prices for yet shows a short
/// "prices will show here soon" line until the scheduled pull brings them.
library;

typedef MarketCrop = ({String key, String en, String mr, String hi});

/// Owner: santra stays the default; the grower selects any other fruit.
const defaultMarketCrop = 'santra';

const List<MarketCrop> marketCrops = [
  (key: 'santra', en: 'Santra (orange)', mr: 'संत्रा', hi: 'संतरा'),
  (key: 'mosambi', en: 'Mosambi (sweet lime)', mr: 'मोसंबी', hi: 'मौसंबी'),
  (key: 'banana', en: 'Banana', mr: 'केळी', hi: 'केला'),
  (key: 'guava', en: 'Guava', mr: 'पेरू', hi: 'अमरूद'),
  (key: 'pomegranate', en: 'Pomegranate', mr: 'डाळिंब', hi: 'अनार'),
  (key: 'grapes', en: 'Grapes', mr: 'द्राक्ष', hi: 'अंगूर'),
  (key: 'papaya', en: 'Papaya', mr: 'पपई', hi: 'पपीता'),
  (key: 'lemon', en: 'Lemon', mr: 'लिंबू', hi: 'नींबू'),
  (key: 'apple', en: 'Apple', mr: 'सफरचंद', hi: 'सेब'),
];

/// A market crop's name in [lang] (English for any other language); the key itself when
/// the crop is not listed.
String marketCropName(String key, String lang) {
  for (final c in marketCrops) {
    if (c.key == key) {
      return switch (lang) {
        'mr' => c.mr,
        'hi' => c.hi,
        _ => c.en,
      };
    }
  }
  return key;
}
