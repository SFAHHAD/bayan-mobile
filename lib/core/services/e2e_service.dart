import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// E2E Encryption Foundation using X25519 (key agreement) + AES-GCM-256 (cipher).
///
/// Key exchange flow:
///   1. User generates an X25519 key pair on first login.
///   2. Public key is published to `e2e_public_keys` in Supabase.
///   3. Private key is held in memory during the session.
///   4. To encrypt/decrypt messages with another user, compute a shared secret
///      using X25519, then use AES-GCM with that secret.
class E2EService {
  final SupabaseClient _client;

  E2EService(this._client);

  static const _table = 'e2e_public_keys';

  // Cached in-memory key pair for the current session
  SimpleKeyPair? _sessionKeyPair;

  // -------------------------------------------------------------------------
  // Key management
  // -------------------------------------------------------------------------

  /// Generates a fresh X25519 key pair, publishes the public key to Supabase,
  /// and caches the pair for this session.
  Future<String> generateAndPublishKeyPair(String userId) async {
    final algorithm = X25519();
    final keyPair = await algorithm.newKeyPair();
    _sessionKeyPair = keyPair;

    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBase64 = base64Encode(publicKey.bytes);

    await _client.from(_table).upsert({
      'user_id': userId,
      'public_key_x25519': publicKeyBase64,
      'updated_at': DateTime.now().toIso8601String(),
    });

    return publicKeyBase64;
  }

  /// Fetches the stored public key for [userId] from Supabase.
  Future<String?> getPublicKey(String userId) async {
    final data = await _client
        .from(_table)
        .select('public_key_x25519')
        .eq('user_id', userId)
        .maybeSingle();
    return data?['public_key_x25519'] as String?;
  }

  // -------------------------------------------------------------------------
  // Shared secret derivation
  // -------------------------------------------------------------------------

  /// Derives a shared secret using the cached session key pair and the
  /// remote user's Base64-encoded X25519 public key.
  Future<SecretKey> computeSharedSecret(String remotePublicKeyBase64) async {
    final pair = _sessionKeyPair;
    if (pair == null) {
      throw StateError(
        'Session key pair not initialised. Call generateAndPublishKeyPair first.',
      );
    }

    final remoteBytes = base64Decode(remotePublicKeyBase64);
    final remotePublicKey = SimplePublicKey(
      remoteBytes,
      type: KeyPairType.x25519,
    );

    return X25519().sharedSecretKey(
      keyPair: pair,
      remotePublicKey: remotePublicKey,
    );
  }

  // -------------------------------------------------------------------------
  // Encryption / Decryption
  // -------------------------------------------------------------------------

  /// Encrypts [plaintext] using AES-GCM-256 with [sharedSecret].
  ///
  /// Output format (Base64): `<12-byte nonce> || <ciphertext> || <16-byte MAC>`
  Future<String> encryptMessage(
    String plaintext,
    SecretKey sharedSecret,
  ) async {
    final aesGcm = AesGcm.with256bits();
    final sharedBytes = await sharedSecret.extractBytes();

    // Derive a 256-bit AES key from the shared secret bytes
    final aesKey = await aesGcm.newSecretKeyFromBytes(
      sharedBytes.sublist(0, 32),
    );

    final nonce = aesGcm.newNonce();
    final box = await aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: aesKey,
      nonce: nonce,
    );

    final combined = Uint8List.fromList([
      ...nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);

    return base64Encode(combined);
  }

  /// Decrypts a Base64-encoded ciphertext produced by [encryptMessage].
  Future<String> decryptMessage(
    String cipherBase64,
    SecretKey sharedSecret,
  ) async {
    final combined = base64Decode(cipherBase64);

    const nonceLen = 12;
    const macLen = 16;

    if (combined.length < nonceLen + macLen) {
      throw ArgumentError('Ciphertext too short to be valid');
    }

    final nonce = combined.sublist(0, nonceLen);
    final mac = combined.sublist(combined.length - macLen);
    final cipherText = combined.sublist(nonceLen, combined.length - macLen);

    final aesGcm = AesGcm.with256bits();
    final sharedBytes = await sharedSecret.extractBytes();
    final aesKey = await aesGcm.newSecretKeyFromBytes(
      sharedBytes.sublist(0, 32),
    );

    final plainBytes = await aesGcm.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
      secretKey: aesKey,
    );

    return utf8.decode(plainBytes);
  }

  // -------------------------------------------------------------------------
  // Raw-bytes helpers (used by E2EChatRepository for diwan session keys)
  // -------------------------------------------------------------------------

  /// Generates 32 cryptographically random bytes suitable for an AES-256 key.
  Future<List<int>> generateRandomKeyBytes() async {
    final key = await AesGcm.with256bits().newSecretKey();
    return key.extractBytes();
  }

  /// AES-GCM encrypts raw [data] bytes with [secretKey].
  /// Output format (Base64): `<12-byte nonce> || <ciphertext> || <16-byte MAC>`
  Future<String> encryptBytes(List<int> data, SecretKey secretKey) async {
    final aesGcm = AesGcm.with256bits();
    final nonce = aesGcm.newNonce();
    final box = await aesGcm.encrypt(data, secretKey: secretKey, nonce: nonce);
    final combined = Uint8List.fromList([
      ...nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
    return base64Encode(combined);
  }

  /// Decrypts a Base64-encoded payload produced by [encryptBytes].
  Future<List<int>> decryptBytes(
    String cipherBase64,
    SecretKey secretKey,
  ) async {
    final combined = base64Decode(cipherBase64);
    const nonceLen = 12;
    const macLen = 16;
    if (combined.length < nonceLen + macLen) {
      throw ArgumentError('Ciphertext too short');
    }
    final nonce = combined.sublist(0, nonceLen);
    final mac = combined.sublist(combined.length - macLen);
    final cipherText = combined.sublist(nonceLen, combined.length - macLen);
    return AesGcm.with256bits().decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
      secretKey: secretKey,
    );
  }

  /// Creates an AES-256 [SecretKey] from raw [bytes].
  Future<SecretKey> secretKeyFromBytes(List<int> bytes) async {
    return AesGcm.with256bits().newSecretKeyFromBytes(bytes.sublist(0, 32));
  }

  // -------------------------------------------------------------------------
  // Session lifecycle
  // -------------------------------------------------------------------------

  /// Clears the in-memory key pair (call on logout).
  void clearSession() => _sessionKeyPair = null;

  bool get hasActiveSession => _sessionKeyPair != null;
}
