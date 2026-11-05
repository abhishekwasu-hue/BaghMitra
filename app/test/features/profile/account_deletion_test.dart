// S-10 / Play account deletion: the server is erased first (a failure leaves everything as
// it was), then the phone's records, outbox and photos, then the session ends.
import 'dart:convert';
import 'dart:io';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/features/auth/data/demo_auth_repository.dart';
import 'package:bagmitra/features/profile/data/account_deletion.dart';
import 'package:bagmitra/features/walkthrough/data/walkthrough_flag.dart';
import 'package:bagmitra/sync/account_guard.dart';
import 'package:bagmitra/sync/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/test_db.dart';
import '../../sync/account_guard_test.dart' show first, seedFirstAccount;

HttpAccountDeletionApi _api(MockClientHandler handler) =>
    HttpAccountDeletionApi(
      createApi(
        baseUrl: Uri.parse('https://api.example.test'),
        token: () => 'tok',
        httpClient: MockClient(handler),
      ),
    );

class RecordingApi implements AccountDeletionApi {
  RecordingApi({this.fail = false});
  final bool fail;
  var calls = 0;

  @override
  Future<void> eraseServerAccount() async {
    calls++;
    if (fail) throw const AccountDeletionException('http 502');
  }
}

void main() {
  test('the API call is DELETE /v1/me with the token', () async {
    final seen = <http.Request>[];
    await _api((request) async {
      seen.add(request);
      return http.Response(
        jsonEncode({
          'rows_deleted': 3,
          'photos_deleted': 0,
          'sign_in_account_removed': true,
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }).eraseServerAccount();
    expect(seen.single.method, 'DELETE');
    expect(seen.single.url.path, '/v1/me');
    expect(seen.single.headers['Authorization'], 'Bearer tok');
  });

  test('a refusal or no network is an AccountDeletionException', () async {
    await expectLater(
      _api((_) async => http.Response('{}', 502)).eraseServerAccount(),
      throwsA(
        isA<AccountDeletionException>().having(
          (e) => e.reason,
          'reason',
          'http 502',
        ),
      ),
    );
    await expectLater(
      _api((_) async => throw const SocketException('offline'))
          .eraseServerAccount(),
      throwsA(isA<AccountDeletionException>()),
    );
    expect(
      const AccountDeletionException('x').toString(),
      contains('AccountDeletionException'),
    );
  });

  test('demo builds have no server to erase', () async {
    await const NoServerAccountDeletionApi().eraseServerAccount();
  });

  test('erasing clears everything, unsent writes too, and signs out', () async {
    final db = memoryDb();
    addTearDown(db.close);
    await seedFirstAccount(db, sent: false);
    var photosDeleted = false;
    final guard = AccountGuard(
      db,
      deletePhotos: () async => photosDeleted = true,
    );
    final auth = DemoAuthRepository(initial: first);
    final api = RecordingApi();

    await AccountDeletion(api: api, guard: guard, auth: auth).run();

    expect(api.calls, 2, reason: 'once more after the local wipe');
    expect(await db.select(db.plots).get(), isEmpty);
    expect(await db.select(db.outboxEntries).get(), isEmpty);
    expect(await db.readMeta(SyncEngine.cursorKey), isNull);
    expect(await db.readMeta(AccountGuard.ownerKey), isNull);
    expect(await WalkthroughFlag(db).seen(), isTrue, reason: 'phone-level');
    expect(photosDeleted, isTrue);
    expect(auth.current, isNull);
  });

  test('a server failure leaves the phone and the session untouched', () async {
    final db = memoryDb();
    addTearDown(db.close);
    await seedFirstAccount(db, sent: false);
    final auth = DemoAuthRepository(initial: first);
    await expectLater(
      AccountDeletion(
        api: RecordingApi(fail: true),
        guard: AccountGuard(db),
        auth: auth,
      ).run(),
      throwsA(isA<AccountDeletionException>()),
    );
    expect(await db.select(db.plots).get(), hasLength(1));
    expect(await db.select(db.outboxEntries).get(), hasLength(1));
    expect(auth.current, first);
  });

  test('a failing second call does not stop the sign-out', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final auth = DemoAuthRepository(initial: first);
    await AccountDeletion(
      api: _SecondFails(),
      guard: AccountGuard(db),
      auth: auth,
    ).run();
    expect(auth.current, isNull);
  });

  test('Android backup is off for app data (S-09)', () {
    const main = 'android/app/src/main';
    final manifest = File('$main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
    final rules = File('$main/res/xml/data_extraction_rules.xml')
        .readAsStringSync();
    for (final section in ['cloud-backup', 'device-transfer']) {
      expect(rules, contains('<$section>'));
    }
    for (final domain in ['root', 'file', 'database', 'sharedpref']) {
      expect(rules, contains('domain="$domain" path="."'));
      expect(
        File('$main/res/xml/backup_rules.xml').readAsStringSync(),
        contains('domain="$domain" path="."'),
      );
    }
  });
}

class _SecondFails implements AccountDeletionApi {
  var _calls = 0;

  @override
  Future<void> eraseServerAccount() async {
    if (++_calls > 1) throw const AccountDeletionException('network');
  }
}
