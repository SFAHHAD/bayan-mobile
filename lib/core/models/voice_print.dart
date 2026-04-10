/// Represents a user's stored Acoustic Identity — a 5-second intro voice clip
/// that has been AES-GCM-256 encrypted before leaving the device.
///
/// The encryption key is NEVER stored on the server.  It is kept exclusively
/// in the device's local Hive box so only the originating device can decrypt.
class VoicePrint {
  final String id;
  final String userId;

  /// Base64-encoded AES-GCM ciphertext: `nonce(12) || ciphertext || mac(16)`.
  final String encryptedAudio;

  final int durationSeconds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VoicePrint({
    required this.id,
    required this.userId,
    required this.encryptedAudio,
    required this.durationSeconds,
    required this.createdAt,
    required this.updatedAt,
  });

  // -------------------------------------------------------------------------
  // Serialisation
  // -------------------------------------------------------------------------

  factory VoicePrint.fromMap(Map<String, dynamic> map) {
    return VoicePrint(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      encryptedAudio: map['encrypted_audio'] as String,
      durationSeconds: (map['duration_seconds'] as int?) ?? 5,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'encrypted_audio': encryptedAudio,
    'duration_seconds': durationSeconds,
  };

  // -------------------------------------------------------------------------
  // Validation
  // -------------------------------------------------------------------------

  /// A legitimate voice print must be between 1 and 30 seconds and have a
  /// non-empty encrypted payload.
  bool get isValid =>
      durationSeconds > 0 && durationSeconds <= 30 && encryptedAudio.isNotEmpty;

  // -------------------------------------------------------------------------
  // Equality
  // -------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoicePrint && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Hive key used to store the per-print encryption key on-device.
/// Full key path: `voice_print_key_<voicePrintId>`.
String voicePrintHiveKey(String voicePrintId) =>
    'voice_print_key_$voicePrintId';
