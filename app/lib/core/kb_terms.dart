/// Crop, pest, disease and stage names that article reading marks in bold colour
/// (design_system/article_reading.dart). Every term is taken from the app's own cards and
/// config (label_targets.json, practice_cards.json, bahars.json, crops.json,
/// stage_templates.json); test/design_system/article_reading_test.dart checks that each one
/// is still there. Matched at the start of a word, so Marathi / Hindi endings are included
/// (सायलाच्या). Short words that are also everyday words (हस्त, मृग alone) are listed only with
/// "बहार".
const kbTerms = <String>[
  // Marathi
  'संत्रा', 'मोसंबी', 'आंबिया', 'मृग बहार', 'हस्त बहार', 'नवती',
  'सायला', 'ग्रीनिंग', 'कँकर', 'डिंक्या', 'खोडकूज', 'मूळकूज', 'फायटोफ्थोरा',
  'भुरी', 'ॲन्थ्रॅकनोज', 'फांदीमर', 'ट्रिस्टेझा', 'काळी बुरशी', 'फळगळ',
  'फुलकिडे', 'मावा', 'काळी माशी', 'पिठ्या ढेकूण', 'खवले कीड', 'फळमाशी',
  'पाने पोखरणारी अळी', 'लिंबू फुलपाखरू', 'साल खाणारी अळी', 'सूत्रकृमी',
  'गोगलगाय',
  // Hindi
  'संतरा', 'मौसंबी', 'अंबिया', 'सिल्ला', 'कैंकर', 'गोंदिया', 'फाइटोफ्थोरा',
  'एन्थ्रेक्नोज', 'डाइबैक', 'ट्रिस्टेज़ा', 'थ्रिप्स', 'माहू', 'मिलीबग',
  'काली मक्खी', 'फल मक्खी', 'सूत्रकृमि', 'घोंघा',
  // English
  'santra', 'mosambi', 'Ambia', 'Mrig bahar', 'Hasta bahar', 'psylla',
  'greening', 'canker', 'gummosis', 'Phytophthora', 'powdery mildew',
  'anthracnose', 'dieback', 'tristeza', 'sooty mould', 'thrips', 'aphids',
  'mealybug', 'black fly', 'leaf miner', 'fruit fly', 'nematode',
];
