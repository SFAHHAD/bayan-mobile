import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/message.dart';
import 'package:bayan/core/repositories/message_repository.dart';
import 'package:bayan/core/services/e2e_service.dart';

/// End-to-End Encrypted Chat Repository.
///
/// Architecture:
///   - Each private Diwan has a random 256-bit **session key** (AES-256-GCM).
///   - The host generates this key and distributes it to every participant by
///     encrypting it with each participant's X25519 public key; the encrypted
///     copies are stored in `e2e_diwan_keys`.
///   - When a participant joins they fetch their encrypted copy, derive the
///     same X25519 shared-secret with the host's public key, and decrypt the
///     session key locally.  The raw key is held **only in memory**.
///   - All messages are encrypted with the session key before reaching
///     Supabase; `is_encrypted = true` signals receivers to decrypt.
class E2EChatRepository {
  final SupabaseClient _client;
  final E2EService _e2e;
  final MessageRepository _msgRepo;

  static const _keysTable = 'e2e_diwan_keys';

  /// In-memory cache: diwanId → AES-256 session key
  final Map<String, SecretKey> _diwanKeys = {};

  E2EChatRepository({
    required SupabaseClient client,
    required E2EService e2eService,
    required MessageRepository messageRepository,
  }) : _client = client,
       _e2e = e2eService,
       _msgRepo = messageRepository;

  // -------------------------------------------------------------------------
  // Key distribution (host)
  // -------------------------------------------------------------------------

  /// Called by the **host** when starting a private Diwan.
  /// Generates a fresh session key and distributes it (encrypted) to every
  /// [participantIds] including the host themselves.
  Future<void> distributeSessionKey({
    required String diwanId,
    required List<String> participantIds,
  }) async {
    final rawKey = await _e2e.generateRandomKeyBytes();
    final sessionKey = await _e2e.secretKeyFromBytes(rawKey);
    _diwanKeys[diwanId] = sessionKey;

    for (final userId in participantIds) {
      final pubKeyBase64 = await _e2e.getPublicKey(userId);
      if (pubKeyBase64 == null) continue;

      final sharedSecret = await _e2e.computeSharedSecret(pubKeyBase64);
      final encryptedKey = await _e2e.encryptBytes(rawKey, sharedSecret);

      await _client.from(_keysTable).upsert({
        'diwan_id': diwanId,
        'user_id': userId,
        'encrypted_key': encryptedKey,
      });
    }
  }

  // -------------------------------------------------------------------------
  // Key loading (participant)
  // -------------------------------------------------------------------------

  /// Called by a **participant** when joining a private Diwan.
  /// Fetches their encrypted session key from `e2e_diwan_keys`, derives the
  /// shared secret with [hostUserId]'s public key, and decrypts the session key.
  ///
  /// Returns `true` if the key was successfully loaded, `false` if no key
  /// has been distributed yet (host hasn't started E2E for this diwan).
  Future<bool> loadSessionKey({
    required String diwanId,
    required String myUserId,
    required String hostUserId,
  }) async {
    if (_diwanKeys.containsKey(diwanId)) return true;

    final row = await _client
        .from(_keysTable)
        .select('encrypted_key')
        .eq('diwan_id', diwanId)
        .eq('user_id', myUserId)
        .maybeSingle();

    if (row == null) return false;

    final hostPubKey = await _e2e.getPublicKey(hostUserId);
    if (hostPubKey == null) return false;

    final sharedSecret = await _e2e.computeSharedSecret(hostPubKey);
    final rawKey = await _e2e.decryptBytes(
      row['encrypted_key'] as String,
      sharedSecret,
    );

    _diwanKeys[diwanId] = await _e2e.secretKeyFromBytes(rawKey);
    return true;
  }

  // -------------------------------------------------------------------------
  // Send
  // -------------------------------------------------------------------------

  /// Encrypts [plaintext] with the diwan session key and sends it.
  /// Throws [StateError] if the session key hasn't been loaded yet.
  Future<Message> sendEncryptedMessage({
    required String diwanId,
    required String senderId,
    required String senderName,
    required String plaintext,
  }) async {
    final key = _diwanKeys[diwanId];
    if (key == null) {
      throw StateError(
        'Session key not loaded for diwan $diwanId. '
        'Call distributeSessionKey or loadSessionKey first.',
      );
    }

    final ciphertext = await _e2e.encryptMessage(plaintext, key);
    return _msgRepo.sendMessage(
      diwanId: diwanId,
      senderId: senderId,
      senderName: senderName,
      content: ciphertext,
      isEncrypted: true,
    );
  }

  // -------------------------------------------------------------------------
  // Receive
  // -------------------------------------------------------------------------

  /// Decrypts a single [message] if `isEncrypted == true` and the session
  /// key is loaded.  Returns the message unmodified if not encrypted or if
  /// decryption fails (e.g. key not yet available).
  Future<Message> decryptMessage(Message message) async {
    if (!message.isEncrypted) return message;

    final key = _diwanKeys[message.diwanId];
    if (key == null) return message;

    try {
      final plain = await _e2e.decryptMessage(message.content, key);
      return message.copyWith(content: plain, isEncrypted: false);
    } catch (_) {
      return message;
    }
  }

  /// Real-time stream of messages for [diwanId] with automatic decryption.
  Stream<List<Message>> watchDecryptedMessages(String diwanId) {
    return _msgRepo.watchMessages(diwanId).asyncMap((messages) async {
      final result = <Message>[];
      for (final msg in messages) {
        result.add(await decryptMessage(msg));
      }
      return result;
    });
  }

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  void clearDiwanKey(String diwanId) => _diwanKeys.remove(diwanId);

  void clearAll() => _diwanKeys.clear();

  bool hasKeyFor(String diwanId) => _diwanKeys.containsKey(diwanId);
}
