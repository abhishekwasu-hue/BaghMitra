import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;

import 'generated/bagmitra.swagger.dart';
import 'http_client_stub.dart'
    if (dart.library.io) 'http_client_io.dart'
    as platform;

/// Supplies the current access token, or null when signed out.
typedef TokenProvider = FutureOr<String?> Function();

/// How long an API call may take: [connect] to reach the server, [receive] for the whole
/// answer once the request is sent. A slow server then ends in a [TimeoutException] the
/// screens can show, instead of an endless spinner.
class ApiTimeouts {
  const ApiTimeouts({
    this.connect = const Duration(seconds: 10),
    this.receive = const Duration(seconds: 20),
  });

  final Duration connect;
  final Duration receive;
}

class AuthHeaderInterceptor implements Interceptor {
  const AuthHeaderInterceptor(this._token);
  final TokenProvider _token;

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(
    Chain<BodyType> chain,
  ) async {
    final token = await _token();
    final request = token == null
        ? chain.request
        : applyHeader(chain.request, 'Authorization', 'Bearer $token');
    return chain.proceed(request);
  }
}

/// Ends any call whose answer takes longer than [timeout] with a [TimeoutException].
class TimeoutInterceptor implements Interceptor {
  const TimeoutInterceptor(this.timeout);
  final Duration timeout;

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(Chain<BodyType> chain) =>
      Future.value(chain.proceed(chain.request)).timeout(timeout);
}

Bagmitra createApi({
  required Uri baseUrl,
  required TokenProvider token,
  http.Client? httpClient,
  ApiTimeouts timeouts = const ApiTimeouts(),
}) => Bagmitra.create(
  baseUrl: baseUrl,
  httpClient: httpClient ?? platform.defaultHttpClient(timeouts.connect),
  interceptors: [
    TimeoutInterceptor(timeouts.receive),
    AuthHeaderInterceptor(token),
  ],
);
