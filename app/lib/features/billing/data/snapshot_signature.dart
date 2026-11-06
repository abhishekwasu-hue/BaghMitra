import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// The byte form the server signs (`billing/signing.py` `canonical`): JSON with keys sorted
/// at every level, no spaces, non-ASCII characters kept as they are.
List<int> canonicalJson(Object? value) =>
    utf8.encode(jsonEncode(_sorted(value)));

Object? _sorted(Object? value) => switch (value) {
  final Map<dynamic, dynamic> m => {
    for (final k in (m.keys.map((k) => k as String).toList()..sort()))
      k: _sorted(m[k]),
  },
  final List<dynamic> l => [for (final e in l) _sorted(e)],
  _ => value,
};

List<int>? _unb64(String text) {
  try {
    return base64Url.decode(base64Url.normalize(text));
  } on FormatException {
    return null;
  }
}

/// Checks the server's Ed25519 signature over a cached entitlement snapshot, so a snapshot
/// edited on the phone is not trusted. [publicKey] is the URL-safe base64 raw public key
/// (`--dart-define=ENTITLEMENT_PUBLIC_KEY=...`); without one nothing verifies.
class SnapshotVerifier {
  SnapshotVerifier(this.publicKey);

  final String publicKey;
  static final _algorithm = Ed25519();

  Future<bool> verify(Map<String, Object?> payload, String? signature) async {
    if (publicKey.isEmpty || signature == null || signature.isEmpty) {
      return false;
    }
    final key = _unb64(publicKey);
    final sig = _unb64(signature);
    if (key == null || key.length != 32 || sig == null || sig.length != 64) {
      return false;
    }
    try {
      return await _algorithm.verify(
        canonicalJson(payload),
        signature: Signature(
          sig,
          publicKey: SimplePublicKey(key, type: KeyPairType.ed25519),
        ),
      );
    } on Exception {
      return false;
    }
  }
}
