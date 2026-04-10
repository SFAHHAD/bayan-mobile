import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/voice_clip.dart';

class VoiceRepository {
  final SupabaseClient _client;

  const VoiceRepository(this._client);

  static const _table = 'voices';
  static const _bucket = 'voice_clips';

  // -------------------------------------------------------------------------
  // Upload & create
  // -------------------------------------------------------------------------

  /// Upload [bytes] as an .m4a clip and persist metadata in `voices`.
  /// Returns the newly created [VoiceClip].
  Future<VoiceClip> uploadHighlight({
    required String diwanId,
    required String speakerId,
    required String title,
    required Uint8List bytes,
    required int durationSeconds,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$diwanId/$speakerId/$timestamp.m4a';

    // 1. Upload to Supabase Storage
    await _client.storage
        .from(_bucket)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'audio/m4a',
            upsert: false,
          ),
        );

    // 2. Get signed public URL (valid 10 years ≈ permanent for clips)
    final publicUrl = _client.storage.from(_bucket).getPublicUrl(storagePath);

    // 3. Persist metadata
    final response = await _client
        .from(_table)
        .insert({
          'diwan_id': diwanId,
          'speaker_id': speakerId,
          'title': title,
          'storage_path': storagePath,
          'public_url': publicUrl,
          'duration_seconds': durationSeconds,
        })
        .select()
        .single();

    return VoiceClip.fromMap(response);
  }

  // -------------------------------------------------------------------------
  // Read
  // -------------------------------------------------------------------------

  Future<List<VoiceClip>> getVoicesForDiwan(String diwanId) async {
    final data = await _client
        .from(_table)
        .select()
        .eq('diwan_id', diwanId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((r) => VoiceClip.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<VoiceClip>> getVoicesForSpeaker(String speakerId) async {
    final data = await _client
        .from(_table)
        .select()
        .eq('speaker_id', speakerId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((r) => VoiceClip.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Real-time stream of voice clips for a specific diwan.
  Stream<List<VoiceClip>> watchVoicesForDiwan(String diwanId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('diwan_id', diwanId)
        .order('created_at')
        .map((rows) => rows.map(VoiceClip.fromMap).toList());
  }

  // -------------------------------------------------------------------------
  // Delete
  // -------------------------------------------------------------------------

  Future<void> deleteVoice(VoiceClip clip) async {
    await _client.storage.from(_bucket).remove([clip.storagePath]);
    await _client.from(_table).delete().eq('id', clip.id);
  }

  // -------------------------------------------------------------------------
  // Signed URL (for private buckets)
  // -------------------------------------------------------------------------

  Future<String> getSignedUrl(
    String storagePath, {
    int expiresInSeconds = 3600,
  }) async {
    return _client.storage
        .from(_bucket)
        .createSignedUrl(storagePath, expiresInSeconds);
  }
}
