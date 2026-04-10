import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/voice_print.dart';

/// Manages storage of [VoicePrint] records.
///
/// ## Security guarantee
/// The AES-GCM-256 encryption key for each voice print is stored **only** in
/// the local Hive box (`acoustic_identity` box, keyed by print ID).
/// The Supabase `voice_prints` table receives only the opaque ciphertext.
/// Neither the server nor any other client can recover the raw audio.
class VoicePrintRepository {
  final SupabaseClient _client;

  const VoicePrintRepository(this._client);

  static const _table = 'voice_prints';
  static const _boxName = 'acoustic_identity';

  // -------------------------------------------------------------------------
  // Store
  // -------------------------------------------------------------------------

  /// Upserts a voice print ciphertext in Supabase and saves the encryption
  /// key locally.  Returns the persisted [VoicePrint].
  Future<VoicePrint> store({
    required String userId,
    required String encryptedAudio,
    required int durationSeconds,
    required List<int> encryptionKeyBytes,
  }) async {
    final response = await _client
        .from(_table)
        .upsert({
          'user_id': userId,
          'encrypted_audio': encryptedAudio,
          'duration_seconds': durationSeconds,
        })
        .select()
        .single();

    final print = VoicePrint.fromMap(response);
    await _saveKeyLocally(print.id, encryptionKeyBytes);
    return print;
  }

  // -------------------------------------------------------------------------
  // Read
  // -------------------------------------------------------------------------

  /// Returns the user's current voice print, or `null` if none exists.
  Future<VoicePrint?> getMyVoicePrint() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final data = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) return null;
    return VoicePrint.fromMap(data);
  }

  /// Retrieves the locally stored encryption key for [voicePrintId].
  /// Returns `null` if the key is absent (e.g. on a new device).
  Future<List<int>?> getLocalKey(String voicePrintId) async {
    final box = await _openBox();
    final raw = box.get(voicePrintHiveKey(voicePrintId)) as String?;
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List).cast<int>();
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Delete
  // -------------------------------------------------------------------------

  /// Deletes the voice print row from Supabase AND wipes the local key.
  Future<void> deleteMyVoicePrint() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final existing = await getMyVoicePrint();
    if (existing != null) {
      await _deleteKeyLocally(existing.id);
    }
    await _client.from(_table).delete().eq('user_id', userId);
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  Future<void> _saveKeyLocally(String voicePrintId, List<int> keyBytes) async {
    final box = await _openBox();
    await box.put(voicePrintHiveKey(voicePrintId), jsonEncode(keyBytes));
  }

  Future<void> _deleteKeyLocally(String voicePrintId) async {
    final box = await _openBox();
    await box.delete(voicePrintHiveKey(voicePrintId));
  }

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }
}
