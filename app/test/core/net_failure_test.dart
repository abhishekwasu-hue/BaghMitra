import 'dart:async';
import 'dart:io';

import 'package:bagmitra/core/net_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test(
    'statuses: 401 / 403 are signed out, every other failure is the server',
    () {
      expect(netFailureForStatus(401), NetFailure.signedOut);
      expect(netFailureForStatus(403), NetFailure.signedOut);
      for (final s in [400, 404, 413, 422, 429, 500, 502, 503, 504]) {
        expect(netFailureForStatus(s), NetFailure.server, reason: '$s');
      }
    },
  );

  test(
    'errors: no network is offline; a slow or broken answer is the server',
    () {
      expect(
        netFailureForError(const SocketException('no route')),
        NetFailure.offline,
      );
      expect(
        netFailureForError(http.ClientException('connection refused')),
        NetFailure.offline,
      );
      expect(netFailureForError(TimeoutException('slow')), NetFailure.server);
      expect(
        netFailureForError(const HandshakeException('tls')),
        NetFailure.server,
      );
      expect(
        netFailureForError(const FormatException('bad json')),
        NetFailure.server,
      );
    },
  );
}
