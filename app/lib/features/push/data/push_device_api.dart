import '../../../api/generated/bagmitra.swagger.dart';
import '../domain/push.dart';

/// Thrown when the API did not accept a device call; the registrar logs it and retries later.
class PushDeviceException implements Exception {
  const PushDeviceException(this.statusCode);
  final int statusCode;

  @override
  String toString() => 'PushDeviceException($statusCode)';
}

class HttpPushDeviceApi implements PushDeviceApi {
  const HttpPushDeviceApi(this._api);
  final Bagmitra _api;

  @override
  Future<void> register(String token) async {
    final resp = await _api.v1MeDevicesPost(
      body: DeviceIn(token: token, platform: DeviceInPlatform.android),
    );
    if (!resp.isSuccessful) throw PushDeviceException(resp.statusCode);
  }

  @override
  Future<void> unregister(String token) async {
    final resp = await _api.v1MeDevicesDelete(body: DeviceOut(token: token));
    if (!resp.isSuccessful) throw PushDeviceException(resp.statusCode);
  }
}
