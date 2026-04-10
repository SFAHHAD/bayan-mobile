import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/voice_clip.dart';

class TranscriptionRepository {
  final SupabaseClient _client;

  const TranscriptionRepository(this._client);

  static const _table = 'voices';

  // -------------------------------------------------------------------------
  // Fetch a single clip with its transcript
  // -------------------------------------------------------------------------

  Future<VoiceClip?> fetchClipWithTranscript(String clipId) async {
    final data = await _client
        .from(_table)
        .select()
        .eq('id', clipId)
        .maybeSingle();
    if (data == null) return null;
    return VoiceClip.fromMap(data);
  }

  // -------------------------------------------------------------------------
  // Full-text search through transcripts (SQL RPC)
  // -------------------------------------------------------------------------

  Future<List<VoiceClip>> searchByTranscript(
    String query, {
    String? diwanId,
    int limit = 20,
  }) async {
    final raw = await _client.rpc(
      'search_transcripts',
      params: {'p_query': query, 'p_diwan_id': diwanId, 'p_limit': limit},
    );
    return (raw as List)
        .map((r) => VoiceClip.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Fetch all clips for a diwan, optionally filtered by status
  // -------------------------------------------------------------------------

  Future<List<VoiceClip>> fetchClipsForDiwan(
    String diwanId, {
    TranscriptionStatus? status,
  }) async {
    final base = _client.from(_table).select().eq('diwan_id', diwanId);
    final data = status != null
        ? await base
              .eq('transcription_status', VoiceClip.statusToString(status))
              .order('created_at', ascending: false)
        : await base.order('created_at', ascending: false);
    return (data as List)
        .map((r) => VoiceClip.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Trigger transcription (calls the Edge Function)
  // -------------------------------------------------------------------------

  Future<Map<String, dynamic>> triggerTranscription(String clipId) async {
    final result = await _client.functions.invoke(
      'transcribe-diwan-clip',
      body: {'voice_clip_id': clipId},
    );
    if (result.status != 200) {
      throw Exception('Transcription trigger failed: ${result.status}');
    }
    return Map<String, dynamic>.from(result.data as Map);
  }

  // -------------------------------------------------------------------------
  // Poll transcription status (for UI progress tracking)
  // -------------------------------------------------------------------------

  Stream<VoiceClip?> watchClip(String clipId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('id', clipId)
        .map((rows) => rows.isEmpty ? null : VoiceClip.fromMap(rows.first));
  }

  // -------------------------------------------------------------------------
  // Batch trigger for all pending clips of a diwan
  // -------------------------------------------------------------------------

  Future<int> triggerPendingClips(String diwanId) async {
    final pending = await fetchClipsForDiwan(
      diwanId,
      status: TranscriptionStatus.pending,
    );
    int triggered = 0;
    for (final clip in pending) {
      try {
        await triggerTranscription(clip.id);
        triggered++;
      } catch (_) {
        // Continue even if one fails
      }
    }
    return triggered;
  }
}
