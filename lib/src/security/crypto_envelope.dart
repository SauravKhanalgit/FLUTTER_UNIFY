/// Encryption Envelope Abstraction (data + transport)
///
/// Provides layered encryption support for payloads before network transit or storage.
/// Roadmap: integrate with key rotation & platform secure storage.
import 'dart:convert';
import 'dart:math';

class EncryptionKey {
  final String id; // key identifier (rotating)
  final List<int> material; // raw key bytes (mock)
  final DateTime createdAt;
  final Duration ttl;
  EncryptionKey(this.id, this.material,
      {DateTime? createdAt, this.ttl = const Duration(days: 30)})
      : createdAt = createdAt ?? DateTime.now();
  bool get isExpired => DateTime.now().isAfter(createdAt.add(ttl));
}

class Envelope {
  final String keyId;
  final String algorithm;
  final String nonce;
  final String ciphertext; // base64
  final Map<String, dynamic>? aad; // additional authenticated data
  Envelope(
      {required this.keyId,
      required this.algorithm,
      required this.nonce,
      required this.ciphertext,
      this.aad});
  Map<String, dynamic> toJson() => {
        'k': keyId,
        'alg': algorithm,
        'n': nonce,
        'ct': ciphertext,
        if (aad != null) 'aad': aad,
      };
}

class CryptoEnvelopeService {
  CryptoEnvelopeService._();
  static CryptoEnvelopeService? _instance;
  static CryptoEnvelopeService get instance =>
      _instance ??= CryptoEnvelopeService._();

  final Map<String, EncryptionKey> _activeKeys = {};
  String? _currentKeyId;
  final _rng = Random.secure();

  // Mock key generation (NOT secure in production)
  EncryptionKey generateKey({int length = 32}) {
    final bytes = List<int>.generate(length, (_) => _rng.nextInt(256));
    final key =
        EncryptionKey('key_${DateTime.now().millisecondsSinceEpoch}', bytes);
    _activeKeys[key.id] = key;
    _currentKeyId = key.id;
    return key;
  }

  EncryptionKey _requireKey() {
    if (_currentKeyId == null || _activeKeys[_currentKeyId!]!.isExpired) {
      return generateKey();
    }
    return _activeKeys[_currentKeyId!]!;
  }

  Envelope seal(dynamic payload, {Map<String, dynamic>? aad}) {
    final key = _requireKey();
    final nonceBytes = List<int>.generate(12, (_) => _rng.nextInt(256));
    final nonce = base64Encode(nonceBytes);
    final raw = jsonEncode(payload);
    // Mock XOR cipher (placeholder) DO NOT USE FOR REAL SECURITY
    final cipherBytes = <int>[];
    for (int i = 0; i < raw.length; i++) {
      cipherBytes
          .add(raw.codeUnitAt(i) ^ key.material[i % key.material.length]);
    }
    final ct = base64Encode(cipherBytes);
    return Envelope(
        keyId: key.id,
        algorithm: 'MOCK-XOR',
        nonce: nonce,
        ciphertext: ct,
        aad: aad);
  }

  dynamic open(Envelope envelope) {
    final key = _activeKeys[envelope.keyId];
    if (key == null) throw StateError('Key not found: ${envelope.keyId}');
    final cipherBytes = base64Decode(envelope.ciphertext);
    final plainBytes = <int>[];
    for (int i = 0; i < cipherBytes.length; i++) {
      plainBytes.add(cipherBytes[i] ^ key.material[i % key.material.length]);
    }
    final jsonStr = utf8.decode(plainBytes);
    return jsonDecode(jsonStr);
  }

  // Key rotation (simplified)
  EncryptionKey rotateKey() => generateKey();

  List<EncryptionKey> listKeys() => List.unmodifiable(_activeKeys.values);
}
