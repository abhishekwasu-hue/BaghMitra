import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/features/photo_analysis/data/offline_leaf_model.dart';
import 'package:bagmitra/features/photo_analysis/data/photo_analysis_api.dart';
import 'package:bagmitra/features/photo_analysis/domain/photo_analysis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../plots/plots_screen_test.dart' show settle;
import '../scouting/scouting_test.dart' show FakePhotos;
import 'offline_check_test.dart' show FakeLeafModel, fakeCheck;

/// The seen signs as the server sends them, per language.
const seenSigns = {
  'en': ['raised brown spots', 'yellow halo'],
  'mr': ['उठावदार तपकिरी ठिपके', 'पिवळी कडा'],
  'hi': ['उभरे भूरे धब्बे', 'पीला घेरा'],
};

/// Only English seen signs (Marathi and Hindi empty): the screen falls back to English.
const englishOnlySigns = {
  'en': ['raised brown spots', 'yellow halo'],
  'mr': <String>[],
  'hi': <String>[],
};

const noSigns = {'en': <String>[], 'mr': <String>[], 'hi': <String>[]};

/// One candidate as the server sends it.
Map<String, Object?> candidate(
  String key, {
  double confidence = 0.82,
  String mr = 'कँकर',
  String explanationMr =
      'पानावर उठावदार तपकिरी ठिपके दिसतात. कार्ड उघडून झाड तपासा.',
  Map<String, List<String>> signs = seenSigns,
}) => {
  'key': key,
  'name': {'en': 'Canker', 'mr': mr, 'hi': 'कैंकर'},
  'confidence': confidence,
  'signs': signs,
  'explanation': {
    'en': 'Raised brown spots on the leaf. Open the card to check the tree.',
    'mr': explanationMr,
    'hi': 'पत्ती पर उभरे भूरे धब्बे दिखते हैं। कार्ड खोलकर पेड़ जाँचें।',
  },
};

String analysisJson({
  List<Map<String, Object?>>? candidates,
  bool unsure = false,
  String photoId = 'ph-1',
}) => jsonEncode({
  'candidates': candidates ?? [candidate('canker')],
  'unsure': unsure,
  'photo_id': photoId,
});

String limitJson(String kind, {String max = '5', String resets = ''}) =>
    jsonEncode({
      'error': {
        'code': 'analysis_limit',
        'message': '$kind photo limit reached',
        'details': {'limit': kind, 'max': max, 'resets_at': resets},
      },
    });

/// The server, as the test wants it to answer; remembers every request.
class FakeAnalysisServer {
  FakeAnalysisServer(this.answer);

  Future<http.Response> Function(http.Request) answer;
  final requests = <http.Request>[];

  late final client = MockClient((r) {
    requests.add(r);
    return answer(r);
  });

  PhotoAnalysisApi get api => HttpPhotoAnalysisApi(
    createApi(
      baseUrl: Uri.parse('http://localhost:8000'),
      token: () => 't',
      httpClient: client,
    ),
  );

  List<http.Request> get posts => [
    for (final r in requests)
      if (r.method == 'POST') r,
  ];
}

http.Response json(String body, int status) => http.Response.bytes(
  utf8.encode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

final fakeJpeg = Uint8List.fromList(
  img.encodeJpg(
    img.Image(width: 8, height: 8)..clear(img.ColorRgb8(90, 140, 60)),
  ),
);

List<Override> photoOverrides(
  FakeAnalysisServer server, {
  FakeLeafModel? onPhone,
}) => [
  photoAnalysisApiProvider.overrideWithValue(server.api),
  photoPreparerProvider.overrideWithValue((_) async => fakeJpeg),
  if (onPhone != null)
    offlineLeafCheckProvider.overrideWithValue(fakeCheck(onPhone)),
];

Future<void> openAndPick(
  WidgetTester tester,
  FakeAnalysisServer server, {
  FakePhotos? photos,
  Locale locale = const Locale('mr'),
  FakeLeafModel? onPhone,
}) async {
  await pumpApp(
    tester,
    locale: locale,
    initialLocation: '/plots/p1/photo-check',
    seed: seedPlot,
    photos: photos ?? FakePhotos(),
    overrides: photoOverrides(server, onPhone: onPhone),
  );
  await settle(tester);
  await tester.tap(find.byKey(const Key('photo-check-camera')));
  await settle(tester);
}

Future<void> identify(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('photo-check-run')));
  await settle(tester);
}

void main() {
  group('the API client', () {
    test('sends one multipart photo with the part and scouting item', () async {
      final server = FakeAnalysisServer((_) async => json(analysisJson(), 200));
      final result = await server.api.analyse(
        plotId: 'p1',
        photo: fakeJpeg,
        part: PhotoPart.leaf,
        scoutingItem: 'psylla',
      );
      final r = server.requests.single;
      expect(r.method, 'POST');
      expect(r.url.path, '/v1/plots/p1/photo-analysis');
      expect(r.headers['authorization'], 'Bearer t');
      expect(r.headers['content-type'], startsWith('multipart/form-data'));
      final body = latin1.decode(r.bodyBytes);
      expect(body, contains('name="photo"; filename="photo.jpg"'));
      expect(body, contains('name="part"\r\n\r\nleaf'));
      expect(body, contains('name="scouting_item"\r\n\r\npsylla'));
      expect(body, isNot(contains('name="body"')));
      expect(result.photoId, 'ph-1');
      expect(result.candidates.single.key, 'canker');
      expect(result.candidates.single.nameIn('mr'), 'कँकर');
      expect(result.candidates.single.signs, seenSigns);
    });

    test('leaves out the optional fields when not chosen', () async {
      final server = FakeAnalysisServer((_) async => json(analysisJson(), 200));
      await server.api.analyse(plotId: 'p1', photo: fakeJpeg);
      final body = latin1.decode(server.requests.single.bodyBytes);
      expect(body, isNot(contains('name="part"')));
      expect(body, isNot(contains('name="scouting_item"')));
    });

    test('reads the limit, when it resets and which one', () async {
      final server = FakeAnalysisServer(
        (_) async => json(
          limitJson('monthly', max: '50', resets: '2026-11-30T18:30:00Z'),
          429,
        ),
      );
      await expectLater(
        server.api.analyse(plotId: 'p1', photo: fakeJpeg),
        throwsA(
          isA<PhotoLimitException>()
              .having((e) => e.kind, 'kind', PhotoLimitKind.monthly)
              .having((e) => e.max, 'max', 50)
              .having(
                (e) => e.resetsAt,
                'resets',
                DateTime.utc(2026, 11, 30, 18, 30),
              ),
        ),
      );
    });

    for (final (status, problem) in [
      (503, PhotoProblem.unavailable),
      (502, PhotoProblem.failed),
      (404, PhotoProblem.failed),
      (413, PhotoProblem.refused),
      (415, PhotoProblem.refused),
      (401, PhotoProblem.signedOut),
    ]) {
      test('$status is told as ${problem.name}', () async {
        final server = FakeAnalysisServer(
          (_) async => json('{"error":{"code":"x","message":"x"}}', status),
        );
        await expectLater(
          server.api.analyse(plotId: 'p1', photo: fakeJpeg),
          throwsA(
            isA<PhotoProblemException>().having(
              (e) => e.problem,
              'problem',
              problem,
            ),
          ),
        );
      });
    }

    test('no network is offline', () async {
      final server = FakeAnalysisServer(
        (_) async => throw const SocketException('no route'),
      );
      await expectLater(
        server.api.analyse(plotId: 'p1', photo: fakeJpeg),
        throwsA(
          isA<PhotoProblemException>().having(
            (e) => e.problem,
            'problem',
            PhotoProblem.offline,
          ),
        ),
      );
    });

    test('delete calls DELETE for the photo; gone already counts', () async {
      for (final status in [204, 404]) {
        final server = FakeAnalysisServer(
          (_) async => http.Response('', status),
        );
        await server.api.delete('ph-9');
        expect(server.requests.single.method, 'DELETE');
        expect(server.requests.single.url.path, '/v1/photo-analysis/ph-9');
      }
      final failing = FakeAnalysisServer((_) async => http.Response('', 502));
      await expectLater(
        failing.api.delete('ph-9'),
        throwsA(isA<PhotoProblemException>()),
      );
    });
  });

  group('the photo before upload', () {
    test('a large PNG becomes a JPEG of at most 1600 px', () async {
      final big = img.Image(width: 3200, height: 2400, numChannels: 4);
      for (final p in big) {
        p
          ..r = p.x % 256
          ..g = p.y % 256
          ..b = (p.x * p.y) % 256
          ..a = 255;
      }
      final out = await preparePhoto(img.encodePng(big));
      expect(out.sublist(0, 2), [0xff, 0xd8]);
      expect(out.length, lessThan(PhotoLimits.maxBytes));
      final back = img.decodeJpg(out)!;
      expect(back.width, PhotoLimits.maxSide);
      expect(back.height, 1200);
    });

    test('a small JPEG keeps its size', () async {
      final out = await preparePhoto(
        img.encodeJpg(img.Image(width: 800, height: 600)),
      );
      final back = img.decodeJpg(out)!;
      expect((back.width, back.height), (800, 600));
    });

    test('bytes that are no image are refused on the phone', () async {
      await expectLater(
        preparePhoto([1, 2, 3, 4]),
        throwsA(isA<PhotoUnreadableException>()),
      );
    });
  });

  test('confidence reads as a calm word', () {
    expect(Likelihood.of(0.9), Likelihood.high);
    expect(Likelihood.of(0.7), Likelihood.high);
    expect(Likelihood.of(0.55), Likelihood.medium);
    expect(Likelihood.of(0.4), Likelihood.medium);
    expect(Likelihood.of(0.2), Likelihood.low);
  });

  group('the screen', () {
    testWidgets('success: names, calm likelihood, explanation and the card', (
      tester,
    ) async {
      final server = FakeAnalysisServer(
        (_) async => json(
          analysisJson(
            candidates: [
              candidate('canker'),
              candidate('greening', confidence: 0.45, mr: 'ग्रीनिंग'),
            ],
          ),
          200,
        ),
      );
      await openAndPick(tester, server);
      // The camera opened straight away: no consent question of our own (privacy policy).
      expect(find.byType(AlertDialog), findsNothing);
      await tester.tap(find.byKey(const Key('photo-part-leaf')));
      await settle(tester);
      await identify(tester);

      expect(server.posts, hasLength(1));
      expect(
        latin1.decode(server.posts.single.bodyBytes),
        contains('name="part"\r\n\r\nleaf'),
      );
      expect(find.text('कँकर'), findsOneWidget);
      expect(find.text('जास्त शक्यता · ८२%'), findsOneWidget);
      expect(find.text('मध्यम शक्यता · ४५%'), findsOneWidget);
      expect(
        find.text('पानावर उठावदार तपकिरी ठिपके दिसतात. कार्ड उघडून झाड तपासा.'),
        findsNWidgets(2),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('photo-check-note')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('photo-check-note')), findsOneWidget);
      // One result per photo: no second call for the same photo.
      expect(find.byKey(const Key('photo-check-run')), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('photo-card-canker')));
      await tester.tap(find.byKey(const Key('photo-card-canker')));
      await settle(tester);
      // The practices guide, opened at the canker section.
      expect(find.byKey(const Key('practices-see-canker')), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('the seen signs come in Marathi under a plain fold label', (
      tester,
    ) async {
      final server = FakeAnalysisServer((_) async => json(analysisJson(), 200));
      await openAndPick(tester, server);
      await identify(tester);
      expect(find.text('फोटोत दिसलेले'), findsOneWidget);
      expect(find.text('फोटोत दिसलेले (इंग्रजीत)'), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('photo-signs-canker')));
      await tester.tap(find.byKey(const Key('photo-signs-canker')));
      await settle(tester);
      expect(find.text('• उठावदार तपकिरी ठिपके'), findsOneWidget);
      expect(find.text('• पिवळी कडा'), findsOneWidget);
      expect(find.text('• raised brown spots'), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('no Marathi signs: the English ones, said to be in English', (
      tester,
    ) async {
      final server = FakeAnalysisServer(
        (_) async => json(
          analysisJson(
            candidates: [candidate('canker', signs: englishOnlySigns)],
          ),
          200,
        ),
      );
      await openAndPick(tester, server);
      await identify(tester);
      expect(find.text('फोटोत दिसलेले (इंग्रजीत)'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('photo-signs-canker')));
      await tester.tap(find.byKey(const Key('photo-signs-canker')));
      await settle(tester);
      expect(find.text('• raised brown spots'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('Hindi signs in Hindi; English shows them open', (
      tester,
    ) async {
      final hindi = FakeAnalysisServer((_) async => json(analysisJson(), 200));
      await openAndPick(tester, hindi, locale: const Locale('hi'));
      await identify(tester);
      expect(find.text('फ़ोटो में दिखा'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('photo-signs-canker')));
      await tester.tap(find.byKey(const Key('photo-signs-canker')));
      await settle(tester);
      expect(find.text('• उभरे भूरे धब्बे'), findsOneWidget);
      await unmountApp(tester);

      final english = FakeAnalysisServer(
        (_) async => json(analysisJson(), 200),
      );
      await openAndPick(tester, english, locale: const Locale('en'));
      await identify(tester);
      expect(find.text('Seen in the photo'), findsOneWidget);
      expect(find.text('• yellow halo'), findsOneWidget);
      expect(find.byKey(const Key('photo-signs-canker')), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('unsure: a calm line about a clearer photo', (tester) async {
      final server = FakeAnalysisServer(
        (_) async => json(
          analysisJson(
            unsure: true,
            candidates: [candidate('canker', confidence: 0.3)],
          ),
          200,
        ),
      );
      await openAndPick(tester, server);
      await identify(tester);
      expect(find.byKey(const Key('photo-check-unsure')), findsOneWidget);
      expect(find.text('कमी शक्यता · ३०%'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('healthy reads positively, with no card to open', (
      tester,
    ) async {
      final server = FakeAnalysisServer(
        (_) async => json(
          analysisJson(
            candidates: [
              candidate(
                'healthy',
                confidence: 0.9,
                mr: 'निरोगी दिसते',
                signs: noSigns,
              ),
            ],
          ),
          200,
        ),
      );
      await openAndPick(tester, server);
      await identify(tester);
      expect(find.byKey(const Key('photo-check-healthy')), findsOneWidget);
      expect(find.text('निरोगी दिसते'), findsOneWidget);
      expect(find.byKey(const Key('photo-card-healthy')), findsNothing);
      expect(find.byKey(const Key('photo-check-unsure')), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('429 daily: today\'s photos are used, back tomorrow', (
      tester,
    ) async {
      // The test clock is 13 Oct 2026, 06:00 UTC and the phone's zone is UTC.
      final server = FakeAnalysisServer(
        (_) async =>
            json(limitJson('daily', resets: '2026-10-14T00:00:00Z'), 429),
      );
      await openAndPick(tester, server);
      await identify(tester);
      expect(
        find.text('आजचे ५ फोटो पूर्ण झाले; उद्या पुन्हा वापरता येईल.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('photo-check-run')), findsNothing);
      expect(find.byKey(const Key('photo-check-cards')), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('429 monthly and total read calmly too', (tester) async {
      var kind = 'monthly';
      final server = FakeAnalysisServer(
        (_) async => json(
          limitJson(kind, max: '50', resets: '2026-11-01T00:00:00Z'),
          429,
        ),
      );
      await openAndPick(tester, server);
      await identify(tester);
      expect(
        find.textContaining('या महिन्याचे ५० फोटो पूर्ण झाले'),
        findsOneWidget,
      );
      await unmountApp(tester);

      kind = 'total';
      server.answer = (_) async => json(
        limitJson(kind, max: '900', resets: '2026-10-14T00:00:00Z'),
        429,
      );
      await openAndPick(tester, server);
      await identify(tester);
      expect(find.byKey(const Key('photo-check-limit')), findsOneWidget);
      expect(find.textContaining('९००'), findsNothing);
      expect(find.textContaining('उद्या पुन्हा वापरता येईल'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets(
      'offline: says the internet is needed, keeps the photo, one-tap '
      'retry',
      (tester) async {
        final server = FakeAnalysisServer(
          (_) async => throw const SocketException('no route'),
        );
        await openAndPick(tester, server);
        await identify(tester);
        expect(find.byKey(const Key('photo-check-offline')), findsOneWidget);
        expect(find.byKey(const Key('photo-check-preview')), findsOneWidget);

        server.answer = (_) async => json(analysisJson(), 200);
        await identify(tester);
        expect(server.posts, hasLength(2));
        expect(find.byKey(const Key('photo-check-offline')), findsNothing);
        expect(find.text('कँकर'), findsOneWidget);
        await unmountApp(tester);
      },
    );

    testWidgets('a server failure is not called offline', (tester) async {
      final server = FakeAnalysisServer(
        (_) async => json('{"error":{"code":"analysis_failed"}}', 502),
      );
      await openAndPick(tester, server);
      await identify(tester);
      expect(find.byKey(const Key('photo-check-failed')), findsOneWidget);
      expect(find.byKey(const Key('photo-check-offline')), findsNothing);
      expect(find.byKey(const Key('photo-check-run')), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('delete: the analysed photo is deleted on the server', (
      tester,
    ) async {
      final server = FakeAnalysisServer(
        (r) async => r.method == 'DELETE'
            ? http.Response('', 204)
            : json(analysisJson(photoId: 'ph-42'), 200),
      );
      await openAndPick(tester, server);
      await identify(tester);
      await tester.ensureVisible(find.byKey(const Key('photo-check-delete')));
      await tester.tap(find.byKey(const Key('photo-check-delete')));
      await settle(tester);
      final delete = server.requests.last;
      expect(delete.method, 'DELETE');
      expect(delete.url.path, '/v1/photo-analysis/ph-42');
      expect(find.byKey(const Key('photo-check-deleted')), findsOneWidget);
      expect(find.byKey(const Key('photo-check-delete')), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('delete offline: a calm line, and the action stays', (
      tester,
    ) async {
      final server = FakeAnalysisServer(
        (r) async => r.method == 'DELETE'
            ? throw const SocketException('no route')
            : json(analysisJson(), 200),
      );
      await openAndPick(tester, server);
      await identify(tester);
      await tester.ensureVisible(find.byKey(const Key('photo-check-delete')));
      await tester.tap(find.byKey(const Key('photo-check-delete')));
      await settle(tester);
      expect(
        find.byKey(const Key('photo-check-delete-failed')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('photo-check-delete')), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('the picked photo from this screen is removed afterwards', (
      tester,
    ) async {
      final photos = FakePhotos();
      final server = FakeAnalysisServer((_) async => json(analysisJson(), 200));
      await openAndPick(tester, server, photos: photos);
      await tester.tap(find.byKey(const Key('photo-check-change')));
      await settle(tester);
      expect(photos.discarded, ['/tmp/picked.jpg']);
      await unmountApp(tester);
    });
  });

  group('entry points', () {
    testWidgets('the scouting log opens the photo check', (tester) async {
      final server = FakeAnalysisServer((_) async => json(analysisJson(), 200));
      await pumpApp(
        tester,
        initialLocation: '/plots/p1/scouting',
        seed: seedPlot,
        photos: FakePhotos(),
        overrides: photoOverrides(server),
      );
      await settle(tester);
      await tester.tap(find.byKey(const Key('photo-check-open')));
      await settle(tester);
      expect(find.byKey(const Key('photo-check-camera')), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('the pest / disease photo form checks its own photo with the '
        'chosen item', (tester) async {
      final photos = FakePhotos();
      final server = FakeAnalysisServer((_) async => json(analysisJson(), 200));
      await pumpApp(
        tester,
        initialLocation: '/plots/p1/scouting/new?item=psylla',
        seed: seedPlot,
        photos: photos,
        overrides: photoOverrides(server),
      );
      await settle(tester);
      // Before a photo there is nothing to check.
      expect(find.byKey(const Key('scouting-photo-check')), findsNothing);
      await tester.tap(find.text('कॅमेरा'));
      await settle(tester);
      await tester.ensureVisible(find.byKey(const Key('scouting-photo-check')));
      await tester.tap(find.byKey(const Key('scouting-photo-check')));
      await settle(tester);
      // The same photo, no second camera trip.
      expect(photos.sources, hasLength(1));
      expect(find.byKey(const Key('photo-check-preview')), findsOneWidget);
      await identify(tester);
      expect(
        latin1.decode(server.posts.single.bodyBytes),
        contains('name="scouting_item"\r\n\r\npsylla'),
      );
      // Back to the form: its photo is still there to save with the record.
      await tester.tap(find.byKey(const Key('photo-check-back')));
      await settle(tester);
      expect(find.byKey(const Key('scouting-photo-check')), findsOneWidget);
      expect(photos.discarded, isEmpty);
      await unmountApp(tester);
    });

    testWidgets('a new block form never leads to the photo check', (
      tester,
    ) async {
      await pumpApp(tester, initialLocation: '/plots/new');
      await settle(tester);
      expect(find.byKey(const Key('photo-check-open')), findsNothing);
      expect(find.byKey(const Key('scouting-photo-check')), findsNothing);
      await unmountApp(tester);
    });
  });

  group('offline: the phone\'s leaf model', () {
    FakeAnalysisServer noNetwork() => FakeAnalysisServer(
      (_) async => throw const SocketException('no route'),
    );

    Future<void> scrollTo(WidgetTester tester, String key) =>
        tester.scrollUntilVisible(
          find.byKey(Key(key)),
          200,
          scrollable: find.byType(Scrollable).first,
        );

    testWidgets('a calm estimate with its card; photo and retry stay', (
      tester,
    ) async {
      final server = noNetwork();
      final model = FakeLeafModel([0.65, 0.2, 0.1, 0.05]);
      await openAndPick(tester, server, onPhone: model);
      await identify(tester);

      expect(model.inputs, hasLength(1));
      expect(
        find.text(
          'फोनवरच्या प्राथमिक तपासणीनुसार: कँकरसारखी लक्षणे (मध्यम शक्यता)',
        ),
        findsOneWidget,
      );
      // The estimate replaces the plain "internet needed" line; it never says it is sure.
      expect(find.byKey(const Key('photo-check-offline')), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.byKey(const Key('photo-offline-pcr')), findsNothing);
      await scrollTo(tester, 'photo-offline-note');
      expect(
        find.text('फोनवरचा अंदाज; इंटरनेट आल्यावर पूर्ण तपासणी करता येईल.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('photo-check-preview')), findsOneWidget);
      expect(find.text('पुन्हा तपासा'), findsOneWidget);
      // Nothing is stored on the server, so nothing to delete; one call only.
      expect(find.byKey(const Key('photo-check-delete')), findsNothing);
      expect(server.posts, hasLength(1));

      await tester.ensureVisible(
        find.byKey(const Key('photo-offline-card-canker')),
      );
      await tester.tap(find.byKey(const Key('photo-offline-card-canker')));
      await settle(tester);
      expect(find.byKey(const Key('practices-see-canker')), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('greening: two lines, the PCR line and both cards', (
      tester,
    ) async {
      final model = FakeLeafModel([0.27, 0.66, 0.05, 0.02]);
      await openAndPick(tester, noNetwork(), onPhone: model);
      await identify(tester);
      expect(
        find.text(
          'फोनवरच्या प्राथमिक तपासणीनुसार: ग्रीनिंगसारखी लक्षणे (मध्यम शक्यता)',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'ग्रीनिंगची खात्री फक्त प्रयोगशाळेतील PCR चाचणीने होते; ग्रीनिंग कार्ड पाहा.',
        ),
        findsOneWidget,
      );
      await scrollTo(tester, 'photo-offline-card-canker');
      expect(find.text('किंवा: कँकरसारखी लक्षणे (कमी शक्यता)'), findsOneWidget);
      expect(
        find.byKey(const Key('photo-offline-card-greening')),
        findsOneWidget,
      );
      await unmountApp(tester);
    });

    testWidgets('healthy reads positively', (tester) async {
      final model = FakeLeafModel([0.05, 0.1, 0.8, 0.05]);
      await openAndPick(tester, noNetwork(), onPhone: model);
      await identify(tester);
      expect(find.byKey(const Key('photo-offline-healthy')), findsOneWidget);
      expect(
        find.text('फोनवरच्या प्राथमिक तपासणीनुसार: पान निरोगी दिसते.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('photo-offline-note')), findsOneWidget);
      expect(find.textContaining('कार्ड उघडा'), findsNothing);
      await unmountApp(tester);
    });

    for (final (name, probabilities) in [
      ('below the threshold', [0.5, 0.3, 0.1, 0.1]),
      ('other', [0.02, 0.05, 0.03, 0.9]),
    ]) {
      testWidgets('$name: not clear, the full check runs online', (
        tester,
      ) async {
        final model = FakeLeafModel(probabilities);
        await openAndPick(tester, noNetwork(), onPhone: model);
        await identify(tester);
        expect(find.byKey(const Key('photo-offline-unclear')), findsOneWidget);
        expect(find.byKey(const Key('photo-offline-result')), findsNothing);
        expect(find.textContaining('कार्ड उघडा'), findsNothing);
        expect(find.byKey(const Key('photo-check-offline')), findsNothing);
        expect(find.text('पुन्हा तपासा'), findsOneWidget);
        await unmountApp(tester);
      });
    }

    testWidgets('a fruit photo is not run through the leaf model', (
      tester,
    ) async {
      final model = FakeLeafModel([0.9, 0.05, 0.03, 0.02]);
      await openAndPick(tester, noNetwork(), onPhone: model);
      await tester.tap(find.byKey(const Key('photo-part-fruit')));
      await settle(tester);
      await identify(tester);
      expect(model.inputs, isEmpty);
      expect(find.byKey(const Key('photo-offline-unclear')), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('the model cannot run: the plain internet line', (
      tester,
    ) async {
      final model = FakeLeafModel([0.9, 0, 0, 0.1], fails: true);
      await openAndPick(tester, noNetwork(), onPhone: model);
      await identify(tester);
      expect(model.inputs, hasLength(1));
      expect(find.byKey(const Key('photo-check-offline')), findsOneWidget);
      expect(find.byKey(const Key('photo-offline-result')), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('back online, "check again" gives the full answer', (
      tester,
    ) async {
      final server = noNetwork();
      final model = FakeLeafModel([0.65, 0.2, 0.1, 0.05]);
      await openAndPick(tester, server, onPhone: model);
      await identify(tester);
      expect(find.byKey(const Key('photo-offline-result')), findsOneWidget);

      server.answer = (_) async => json(analysisJson(), 200);
      await identify(tester);
      expect(server.posts, hasLength(2));
      expect(model.inputs, hasLength(1));
      expect(find.byKey(const Key('photo-offline-result')), findsNothing);
      expect(find.byKey(const Key('photo-offline-note')), findsNothing);
      expect(find.text('कँकर'), findsOneWidget);
      expect(find.text('जास्त शक्यता · ८२%'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('online: the server answers and the model never runs', (
      tester,
    ) async {
      final server = FakeAnalysisServer((_) async => json(analysisJson(), 200));
      final model = FakeLeafModel([0.05, 0.9, 0.03, 0.02]);
      await openAndPick(tester, server, onPhone: model);
      await identify(tester);
      expect(model.inputs, isEmpty);
      expect(server.posts, hasLength(1));
      expect(find.text('कँकर'), findsOneWidget);
      expect(find.byKey(const Key('photo-offline-result')), findsNothing);
      expect(find.byKey(const Key('photo-offline-note')), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('a server failure or a limit does not run the model', (
      tester,
    ) async {
      final server = FakeAnalysisServer(
        (_) async => json('{"error":{"code":"analysis_failed"}}', 502),
      );
      final model = FakeLeafModel([0.05, 0.9, 0.03, 0.02]);
      await openAndPick(tester, server, onPhone: model);
      await identify(tester);
      expect(find.byKey(const Key('photo-check-failed')), findsOneWidget);
      server.answer = (_) async => json(limitJson('daily'), 429);
      await identify(tester);
      expect(find.byKey(const Key('photo-check-limit')), findsOneWidget);
      expect(model.inputs, isEmpty);
      await unmountApp(tester);
    });
  });

  group('signs in the app language', () {
    PhotoCandidate cand(Map<String, List<String>> signs) => PhotoCandidate(
      key: 'canker',
      name: const {'en': 'Canker'},
      confidence: 0.5,
      signs: signs,
      explanation: const {},
    );

    test('own language first, English only when it has none', () {
      // A record compares its lists by identity, so it is read field by field.
      void expectSigns(
        ({List<String> signs, bool english}) got,
        List<String> signs, {
        bool english = false,
      }) {
        expect(got.signs, signs);
        expect(got.english, english);
      }

      final both = cand(seenSigns);
      for (final lang in ['en', 'mr', 'hi']) {
        expectSigns(both.signsIn(lang), seenSigns[lang]!);
      }
      final enOnly = cand({
        'en': [' yellow halo ', ''],
        'mr': [' '],
      });
      expectSigns(enOnly.signsIn('mr'), ['yellow halo'], english: true);
      expectSigns(enOnly.signsIn('hi'), ['yellow halo'], english: true);
      expectSigns(enOnly.signsIn('en'), ['yellow halo']);
      expectSigns(cand(noSigns).signsIn('mr'), []);
    });
  });
}
