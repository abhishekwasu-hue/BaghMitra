import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Why a call to the server did not bring an answer, in the three cases the grower is told
/// apart: the phone has no network, the server is unavailable (5xx, timeout, a broken
/// answer), or the session ended and he must sign in again (401 / 403).
enum NetFailure { offline, server, signedOut }

/// Classifies an HTTP status that is not a success. 401 / 403 mean signed out; every other
/// failing status is the server's side.
NetFailure netFailureForStatus(int status) =>
    status == 401 || status == 403 ? NetFailure.signedOut : NetFailure.server;

/// Classifies an error thrown by an API call. A socket error (no route, DNS, refused, the
/// connect timeout) is offline; a timeout waiting for the answer, a TLS error or anything
/// else is the server's side.
NetFailure netFailureForError(Object error) => switch (error) {
  SocketException() => NetFailure.offline,
  TimeoutException() => NetFailure.server,
  TlsException() => NetFailure.server,
  http.ClientException() => NetFailure.offline,
  _ => NetFailure.server,
};
