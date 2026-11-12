// Reactions after reading (owner 2026-11-12, Q146): tap, change, remove, the offline outbox
// (one waiting choice per target, sent later), refusals, counts shown at once, and the
// HTTP calls (PUT / DELETE / GET with `qa:<id>` targets).
import 'dart:convert';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/features/feedback/data/feedback_outbox.dart'
    show SendResult;
import 'package:bagmitra/features/reactions/data/reaction_server.dart';
import 'package:bagmitra/features/reactions/data/reaction_store.dart';
import 'package:bagmitra/features/reactions/domain/reaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/test_db.dart';

/// A server that counts like the API (one reaction per reader) for [others] plus this
/// reader, or stays unreachable while [online] is false.
class FakeReactionServer implements ReactionServer {
  FakeReactionServer({
    this.online = true,
    Map<String, Map<Reaction, int>>? others,
  }) : others = others ?? {};

  bool online;

  /// Status to answer instead of a success (e.g. 404 for a withdrawn item).
  int? refuseWith;
  final Map<String, Map<Reaction, int>> others;
  final mine = <String, Reaction>{};
  final sent = <(String, Reaction?)>[];
  var fetches = 0;

  ReactionSummary summary(String target) {
    final counts = Map<Reaction, int>.of(others[target] ?? const {});
    final m = mine[target];
    if (m != null) counts[m] = (counts[m] ?? 0) + 1;
    return ReactionSummary(counts: counts, mine: m);
  }

  @override
  Future<ReactionSent> send(String target, Reaction? reaction) async {
    if (!online) return (result: SendResult.retryLater, summary: null);
    if (refuseWith != null) return (result: SendResult.refused, summary: null);
    sent.add((target, reaction));
    if (reaction == null) {
      mine.remove(target);
    } else {
      mine[target] = reaction;
    }
    return (result: SendResult.sent, summary: summary(target));
  }

  @override
  Future<Map<String, ReactionSummary>> fetch(List<String> targets) async {
    if (!online) throw Exception('offline');
    fetches++;
    return {for (final t in targets) t: summary(t)};
  }
}

void main() {
  test('tap sets, another tap changes, the same tap removes', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final server = FakeReactionServer(
      others: {
        'i1': {Reaction.useful: 2, Reaction.unclear: 1},
      },
    );
    final store = ReactionStore(db, server);

    var v = await store.tap('i1', Reaction.useful);
    expect(
      (v.mine, v.count(Reaction.useful), v.pending),
      (Reaction.useful, 3, false),
    );
    v = await store.tap('i1', Reaction.thanks);
    expect(v.mine, Reaction.thanks);
    expect(v.count(Reaction.useful), 2, reason: 'the old choice moves');
    expect(v.count(Reaction.thanks), 1);
    v = await store.tap('i1', Reaction.thanks);
    expect((v.mine, v.count(Reaction.thanks), v.pending), (null, 0, false));
    expect(server.sent, [
      ('i1', Reaction.useful),
      ('i1', Reaction.thanks),
      ('i1', null),
    ]);
  });

  test(
    'offline: shown at once, one waiting choice per target, sent later',
    () async {
      final db = memoryDb();
      addTearDown(db.close);
      final server = FakeReactionServer(
        online: false,
        others: {
          'i1': {Reaction.useful: 4},
        },
      );
      final store = ReactionStore(db, server);
      // The phone knew the server's counts from an earlier visit.
      server.online = true;
      await store.refresh(['i1']);
      server.online = false;

      var v = await store.tap('i1', Reaction.useful);
      expect(
        (v.mine, v.count(Reaction.useful), v.pending),
        (Reaction.useful, 5, true),
      );
      v = await store.tap('i1', Reaction.unclear);
      v = await store.tap(qaReactionTarget('seed-psylla'), Reaction.liked);
      expect(v.pending, isTrue);
      final waiting = (await store.load()).pending;
      expect(waiting, {
        'i1': Reaction.unclear,
        'qa:seed-psylla': Reaction.liked,
      });
      final shown = (await store.load()).view('i1');
      expect(shown.count(Reaction.useful), 4);
      expect(shown.count(Reaction.unclear), 1);

      // A refresh while offline keeps the saved copy and the waiting choices.
      await expectLater(store.refresh(['i1']), throwsException);
      expect((await store.load()).pending, hasLength(2));

      server.online = true;
      expect(await store.flush(), 2);
      expect(server.sent, [
        ('i1', Reaction.unclear),
        ('qa:seed-psylla', Reaction.liked),
      ]);
      final after = (await store.load()).view('i1');
      expect(
        (after.mine, after.pending, after.count(Reaction.unclear)),
        (Reaction.unclear, false, 1),
      );
      expect((await store.load()).pending, isEmpty);
    },
  );

  test('removing offline queues a delete; a refused one is dropped', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final server = FakeReactionServer();
    final store = ReactionStore(db, server);
    await store.tap('i1', Reaction.okay);
    server.online = false;
    final v = await store.tap('i1', Reaction.okay);
    expect((v.mine, v.pending, v.count(Reaction.okay)), (null, true, 0));
    expect((await store.load()).pending, {'i1': null});

    server
      ..online = true
      ..refuseWith = 404;
    expect(await store.flush(), 1);
    expect((await store.load()).pending, isEmpty, reason: 'never retried');
  });

  test(
    'the saved state survives a restart and a broken copy is dropped',
    () async {
      final db = memoryDb();
      addTearDown(db.close);
      final server = FakeReactionServer(online: false);
      await ReactionStore(db, server).tap('i9', Reaction.thanks);
      final again = ReactionStore(db, server);
      expect((await again.load()).view('i9').mine, Reaction.thanks);
      await db.writeMeta(ReactionStore.key, '{not json');
      expect((await again.load()).pending, isEmpty);
    },
  );

  test('HTTP: PUT, DELETE and GET with qa targets', () async {
    final calls = <String>[];
    http.Response summary(String target, {String? mine}) => http.Response(
      jsonEncode({
        'target': target,
        'counts': [
          for (final r in Reaction.values)
            {'reaction': r.value, 'count': r.value == mine ? 1 : 0},
        ],
        'mine': mine,
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
    final api = createApi(
      baseUrl: Uri.parse('http://api.test'),
      token: () => 'tok',
      httpClient: MockClient((req) async {
        calls.add('${req.method} ${req.url.path}?${req.url.query} ${req.body}');
        if (req.method == 'GET') {
          return http.Response(
            jsonEncode({
              'reactions': [
                jsonDecode(summary('qa:seed-a', mine: 'liked').body),
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (req.method == 'DELETE') return summary('qa:seed-a');
        return summary('qa:seed-a', mine: 'useful');
      }),
    );
    final server = ApiReactionServer(api);
    final put = await server.send('qa:seed-a', Reaction.useful);
    expect(put.result, SendResult.sent);
    expect(put.summary?.mine, Reaction.useful);
    expect(put.summary?.count(Reaction.useful), 1);
    final del = await server.send('qa:seed-a', null);
    expect(del.summary?.mine, isNull);
    final got = await server.fetch(['qa:seed-a', 'i1']);
    expect(got['qa:seed-a']?.mine, Reaction.liked);
    expect(calls[0], contains('PUT /v1/reactions/qa'));
    expect(calls[0], contains('"reaction":"useful"'));
    expect(calls[1], startsWith('DELETE /v1/reactions/qa'));
    expect(calls[2], contains('target=qa%3Aseed-a&target=i1'));

    final down = ApiReactionServer(
      createApi(
        baseUrl: Uri.parse('http://api.test'),
        token: () => 'tok',
        httpClient: MockClient((_) async => http.Response('{}', 503)),
      ),
    );
    expect(
      (await down.send('i1', Reaction.okay)).result,
      SendResult.retryLater,
    );
  });
}
