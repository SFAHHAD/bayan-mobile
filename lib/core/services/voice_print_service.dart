import 'dart:typed_data';
import 'package:bayan/core/models/voice_print.dart';
import 'package:bayan/core/repositories/voice_print_repository.dart';
import 'package:bayan/core/services/e2e_service.dart';

/// Captures, encrypts, and persists a user's 5-second Acoustic Identity.
///
/// ## Encryption model (E2E on-device)
/// 1. A fresh AES-256 key is generated per recording.
/// 2. Raw PCM/M4A bytes are encrypted with AES-GCM-256 before leaving the
///    device (via [E2EService.encryptBytes]).
/// 3. The ciphertext is stored in the `voice_prints` Supabase table.
/// 4. The key bytes are kept ONLY in the local Hive `acoustic_identity` box —
///    the server never receives the plaintext or the key.
///
/// ## Audio capture
/// This service operates on raw `Uint8List` bytes.  The actual microphone
/// recording is responsibility of the UI layer (using `record` or
/// `livekit_client`).  Separating capture from encryption keeps this service
/// fully testable without hardware.
class VoicePrintService {
  final E2EService _e2e;
  final VoicePrintRepository _repository;

  const VoicePrintService(this._e2e, this._repository);

  // -------------------------------------------------------------------------
  // Constants
  // -------------------------------------------------------------------------

  static const int targetDurationSeconds = 5;
  static const int maxDurationSeconds = 30;
  static const int minAudioBytes = 1;

  // -------------------------------------------------------------------------
  // Create / Replace
  // -------------------------------------------------------------------------

  /// Encrypts [audioBytes] and stores the Acoustic Identity for [userId].
  ///
  /// [durationSeconds] is stored as metadata; it must be between 1 and 30.
  /// Returns the persisted [VoicePrint].
  ///
  /// Throws [VoicePrintException] on validation failure.
  Future<VoicePrint> createVoicePrint({
    required String userId,
    required Uint8List audioBytes,
    int durationSeconds = targetDurationSeconds,
  }) async {
    _validate(audioBytes, durationSeconds);

    // 1. Generate a fresh AES-256 encryption key
    final keyBytes = await _e2e.generateRandomKeyBytes();
    final secretKey = await _e2e.secretKeyFromBytes(keyBytes);

    // 2. Encrypt the audio
    final encryptedAudio = await _e2e.encryptBytes(
      audioBytes.toList(),
      secretKey,
    );

    // 3. Persist ciphertext to Supabase + key to Hive
    return _repository.store(
      userId: userId,
      encryptedAudio: encryptedAudio,
      durationSeconds: durationSeconds,
      encryptionKeyBytes: keyBytes,
    );
  }

  // -------------------------------------------------------------------------
  // Decrypt (playback / analysis on this device)
  // -------------------------------------------------------------------------

  /// Retrieves and decrypts the voice print for the current device.
  ///
  /// Returns `null` if no voice print exists or the key is unavailable.
  Future<Uint8List?> decryptMyVoicePrint() async {
    try {
      final print = await _repository.getMyVoicePrint();
      if (print == null) return null;

      final keyBytes = await _repository.getLocalKey(print.id);
      if (keyBytes == null) return null;

      final secretKey = await _e2e.secretKeyFromBytes(keyBytes);
      final plainBytes = await _e2e.decryptBytes(
        print.encryptedAudio,
        secretKey,
      );
      return Uint8List.fromList(plainBytes);
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Check existence
  // -------------------------------------------------------------------------

  /// Returns `true` if the user already has an Acoustic Identity stored.
  Future<bool> hasVoicePrint() async {
    final print = await _repository.getMyVoicePrint();
    return print != null;
  }

  // -------------------------------------------------------------------------
  // Delete
  // -------------------------------------------------------------------------

  /// Permanently removes the user's Acoustic Identity (server + local key).
  Future<void> deleteVoicePrint() => _repository.deleteMyVoicePrint();

  // -------------------------------------------------------------------------
  // Private
  // -------------------------------------------------------------------------

  void _validate(Uint8List audioBytes, int durationSeconds) {
    if (audioBytes.length < minAudioBytes) {
      throw const VoicePrintException('Audio bytes must not be empty');
    }
    if (durationSeconds <= 0 || durationSeconds > maxDurationSeconds) {
      throw VoicePrintException(
        'Duration must be 1–$maxDurationSeconds seconds '
        '(got $durationSeconds)',
      );
    }
  }
}

/// Thrown by [VoicePrintService] on validation or encryption failures.
class VoicePrintException implements Exception {
  final String message;
  const VoicePrintException(this.message);

  @override
  String toString() => 'VoicePrintException: $message';
}
