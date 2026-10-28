// Share (WhatsApp …) and read-aloud on risk alerts, mandi prices, tasks and feed items.
import 'dart:convert';

import 'package:bagmitra/app/providers.dart';
import 'package:bagmitra/data/local/database.dart';
import 'package:bagmitra/features/tasks/data/tasks_repository.dart';
import 'package:bagmitra/features/voice/data/on_device_speech.dart';
import 'package:bagmitra/features/voice/domain/speech.dart';
import 'package:bagmitra/features/weather/data/plot_weather_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../helpers/pump_app.dart';
import '../bahar/bahar_screen_test.dart' show seedPlot;
import '../feed/feed_data_test.dart' show FakeFeedRepository;
import '../feed/feed_screen_test.dart' show RecordingTextSharer, seedFeed;
import '../market/market_prices_test.dart' show seedPrices;
import '../plots/plots_screen_test.dart' show settle;
import '../tasks/tasks_test.dart' show task;
import '../weather/plot_weather_test.dart' show sampleWeather;

/// A phone's text-to-speech engine that has only the [voices] given.
class FakeTts extends Fake implements FlutterTts {
  FakeTts(this.voices);

  final Set<String> voices;
  String? language;
  final spoken = <String>[];

  @override
  Future<dynamic> isLanguageAvailable(String language) async =>
      voices.contains(language);

  @override
  Future<dynamic> setLanguage(String language) async =>
      this.language = language;

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    spoken.add(text);
    return 1;
  }

  @override
  Future<dynamic> stop() async => 1;
}

class RecordingSynthesizer implements SpeechSynthesizer {
  RecordingSynthesizer({this.hasVoice = true});

  final bool hasVoice;
  final spoken = <(String, String)>[];

  @override
  Future<bool> speak(String text, {required String localeId}) async {
    spoken.add((text, localeId));
    return hasVoice;
  }

  @override
  Future<void> stop() async {}
}

void main() {
  group('on-device voice', () {
    test('speaks in the app language when the phone has it', () async {
      final tts = FakeTts({'mr-IN', 'hi-IN'});
      final ok = await OnDeviceSpeechSynthesizer(engine: tts)
          .speak('नमस्कार', localeId: 'mr_IN');
      expect(ok, isTrue);
      expect(tts.language, 'mr-IN');
      expect(tts.spoken, ['नमस्कार']);
    });

    test('no Marathi voice: falls back to Hindi (same script)', () async {
      final tts = FakeTts({'hi-IN', 'en-IN'});
      expect(
        await OnDeviceSpeechSynthesizer(engine: tts)
            .speak('नमस्कार', localeId: 'mr_IN'),
        isTrue,
      );
      expect(tts.language, 'hi-IN');
    });

    test('no usable voice: nothing is spoken and it says so', () async {
      final tts = FakeTts({'en-IN'});
      expect(
        await OnDeviceSpeechSynthesizer(engine: tts)
            .speak('नमस्कार', localeId: 'mr_IN'),
        isFalse,
      );
      expect(tts.spoken, isEmpty);
    });
  });

  Future<(RecordingTextSharer, RecordingSynthesizer)> pump(
    WidgetTester tester, {
    required String location,
    Future<void> Function(AppDatabase db)? seed,
    Locale locale = const Locale('en'),
    bool hasVoice = true,
  }) async {
    final sharer = RecordingTextSharer();
    final voice = RecordingSynthesizer(hasVoice: hasVoice);
    await pumpApp(
      tester,
      locale: locale,
      initialLocation: location,
      seed: seed,
      overrides: [
        textSharerProvider.overrideWithValue(sharer),
        speechSynthesizerProvider.overrideWithValue(voice),
        feedRepositoryProvider.overrideWithValue(FakeFeedRepository(null)),
      ],
    );
    await settle(tester);
    return (sharer, voice);
  }

  testWidgets('a weather risk alert is shared with its day and source', (
    tester,
  ) async {
    final (sharer, voice) = await pump(
      tester,
      location: '/plots/p1',
      seed: (db) async {
        await seedPlot(db, lat: 21.2468, lon: 77.7512);
        await db.writeMeta(
          PlotWeatherCache.keyFor('p1', 'en'),
          jsonEncode({
            'saved_at': '2026-10-13T06:00:00.000Z',
            'weather': sampleWeather(),
          }),
        );
      },
    );
    const prefix = 'weather-alert-heat_fruit_drop';
    await tester.scrollUntilVisible(find.byKey(const Key(prefix)), 200);
    await tester.tap(find.byKey(const Key('$prefix-share')));
    await tester.tap(find.byKey(const Key('$prefix-speak')));
    await tester.pump();
    expect(sharer.shared.single.split('\n'), [
      '14 Oct 2026: Heat of 35 °C or more expected: risk of fruit drop.',
      'Source: ICAR-CCRI Nagpur monthly guidelines (March)',
      'Shared from the BagMitra app',
    ]);
    expect(voice.spoken.single.$2, 'en_IN');
    expect(voice.spoken.single.$1, isNot(contains('Shared from')));
    await unmountApp(tester);
  });

  testWidgets('a mandi price is shared exactly as published, in Marathi', (
    tester,
  ) async {
    final (sharer, voice) = await pump(
      tester,
      location: '/market',
      locale: const Locale('mr'),
      seed: seedPrices,
    );
    await tester.tap(
      find.byKey(const Key('market-Warud-2026-10-24T00:00:00.000-share')),
    );
    await tester.tap(
      find.byKey(const Key('market-Warud-2026-10-24T00:00:00.000-speak')),
    );
    await tester.pump();
    final text = sharer.shared.single;
    expect(text, startsWith('Warud: '));
    expect(text, contains('प्रति क्विंटल'));
    expect(text, contains('स्रोत: agmarknet'));
    expect(text, contains('Maharashtra · '));
    expect(voice.spoken.single.$2, 'mr_IN');
    await unmountApp(tester);
  });

  testWidgets('task details read aloud and share the task', (tester) async {
    final (sharer, voice) = await pump(
      tester,
      location: '/tasks',
      seed: (db) => TasksRepository(
        db,
        clock: () => DateTime.utc(2026, 10, 13, 6),
      ).save(task('t1', DateTime(2026, 10, 13))),
    );
    await tester.tap(find.byKey(const Key('task-details-t1')));
    await settle(tester);
    expect(find.byKey(const Key('task-sheet-t1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('task-t1-share')));
    await tester.tap(find.byKey(const Key('task-t1-speak')));
    await tester.pump();
    final lines = sharer.shared.single.split('\n');
    expect(lines.first, 'Task t1');
    expect(lines, contains('Due: 13 Oct 2026'));
    expect(lines.last, 'Shared from the BagMitra app');
    expect(voice.spoken.single.$1, startsWith('Task t1'));
    await unmountApp(tester);
  });

  testWidgets("home shares today's open tasks", (tester) async {
    final (sharer, _) = await pump(
      tester,
      location: '/',
      seed: (db) async {
        final repo = TasksRepository(
          db,
          clock: () => DateTime.utc(2026, 10, 13, 6),
        );
        await repo.save(task('a', DateTime(2026, 10, 13)));
        await repo.save(task('b', DateTime(2026, 10, 20)));
      },
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('home-tasks-share')),
      200,
    );
    await tester.tap(find.byKey(const Key('home-tasks-share')));
    await tester.pump();
    expect(sharer.shared.single.split('\n'), [
      "Today's tasks (13 Oct 2026)",
      '• Task a',
      'Shared from the BagMitra app',
    ]);
    await unmountApp(tester);
  });

  testWidgets('a feed item is read aloud without its link', (tester) async {
    final (_, voice) = await pump(
      tester,
      location: '/feed/gr1',
      seed: seedFeed,
    );
    await tester.tap(find.byKey(const Key('feed-speak')));
    await tester.pump();
    expect(voice.spoken.single.$1, startsWith('Title gr1'));
    expect(voice.spoken.single.$1, isNot(contains('https://')));
    await unmountApp(tester);
  });

  testWidgets('no voice on the phone: a short note says so', (tester) async {
    await pump(tester, location: '/feed/gr1', seed: seedFeed, hasVoice: false);
    await tester.tap(find.byKey(const Key('feed-speak')));
    await tester.pump();
    await tester.pump();
    expect(
      find.text('Reading aloud needs a voice for this language on this phone.'),
      findsOneWidget,
    );
    await unmountApp(tester);
  });
}
