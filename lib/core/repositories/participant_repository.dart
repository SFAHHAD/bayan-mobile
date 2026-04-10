import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/speak_request.dart';
import 'package:bayan/features/diwan/domain/models/room_role.dart';

class ParticipantRepository {
  final SupabaseClient _client;

  const ParticipantRepository(this._client);

  static const _participantsTable = 'diwan_participants';
  static const _requestsTable = 'speak_requests';

  // -------------------------------------------------------------------------
  // LiveKit token
  // -------------------------------------------------------------------------

  /// Calls the Edge Function to obtain a signed LiveKit token for [userId]
  /// in [diwanId]. The Edge Function validates the user's role via RLS and
  /// returns a token with matching publish/subscribe permissions.
  Future<String> getLiveKitToken(String diwanId) async {
    final response = await _client.functions.invoke(
      'get-livekit-token',
      body: {'diwan_id': diwanId},
    );
    final token = (response.data as Map<String, dynamic>)['token'] as String?;
    if (token == null) {
      throw Exception('Failed to obtain LiveKit token');
    }
    return token;
  }

  // -------------------------------------------------------------------------
  // Participants
  // -------------------------------------------------------------------------

  Future<void> joinDiwan(String diwanId, String userId, RoomRole role) async {
    await _client.from(_participantsTable).upsert({
      'diwan_id': diwanId,
      'user_id': userId,
      'role': role.value,
    });
  }

  Future<void> leaveDiwan(String diwanId, String userId) async {
    await _client
        .from(_participantsTable)
        .delete()
        .eq('diwan_id', diwanId)
        .eq('user_id', userId);
  }

  Future<RoomRole> getMyRole(String diwanId, String userId) async {
    final data = await _client
        .from(_participantsTable)
        .select('role')
        .eq('diwan_id', diwanId)
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) return RoomRole.listener;
    return RoomRoleX.fromString(data['role'] as String? ?? 'listener');
  }

  Future<void> updateRole(
    String diwanId,
    String userId,
    RoomRole newRole,
  ) async {
    await _client
        .from(_participantsTable)
        .update({'role': newRole.value})
        .eq('diwan_id', diwanId)
        .eq('user_id', userId);
  }

  // -------------------------------------------------------------------------
  // Speak requests
  // -------------------------------------------------------------------------

  Future<void> requestToSpeak(String diwanId, String userId) async {
    await _client.from(_requestsTable).upsert({
      'diwan_id': diwanId,
      'user_id': userId,
      'status': 'pending',
    });
  }

  Future<void> approveSpeakRequest(
    String requestId,
    String diwanId,
    String userId,
  ) async {
    await _client
        .from(_requestsTable)
        .update({'status': 'approved'})
        .eq('id', requestId);
    await updateRole(diwanId, userId, RoomRole.speaker);
  }

  Future<void> rejectSpeakRequest(String requestId) async {
    await _client
        .from(_requestsTable)
        .update({'status': 'rejected'})
        .eq('id', requestId);
  }

  // -------------------------------------------------------------------------
  // Host controls: kick & ban
  // -------------------------------------------------------------------------

  static const _bansTable = 'diwan_bans';

  /// Removes [userId] from the active diwan session (temporary — they can rejoin).
  Future<void> kickParticipant(String diwanId, String userId) async {
    await _client
        .from(_participantsTable)
        .delete()
        .eq('diwan_id', diwanId)
        .eq('user_id', userId);
  }

  /// Permanently bans [userId] from [diwanId].
  /// Kicks them first, then records a permanent ban entry.
  Future<void> banFromDiwan(
    String diwanId,
    String userId, {
    String? reason,
  }) async {
    await kickParticipant(diwanId, userId);
    await _client.from(_bansTable).upsert({
      'diwan_id': diwanId,
      'user_id': userId,
      'banned_by': _client.auth.currentUser?.id,
      'reason': reason,
    });
  }

  /// Lifts the permanent ban for [userId] in [diwanId].
  Future<void> unbanFromDiwan(String diwanId, String userId) async {
    await _client
        .from(_bansTable)
        .delete()
        .eq('diwan_id', diwanId)
        .eq('user_id', userId);
  }

  /// Returns true if [userId] is permanently banned from [diwanId].
  Future<bool> isBanned(String diwanId, String userId) async {
    final data = await _client
        .from(_bansTable)
        .select('user_id')
        .eq('diwan_id', diwanId)
        .eq('user_id', userId)
        .maybeSingle();
    return data != null;
  }

  /// Returns all banned user IDs for [diwanId] (host use only).
  Future<List<String>> getBannedUsers(String diwanId) async {
    final data = await _client
        .from(_bansTable)
        .select('user_id')
        .eq('diwan_id', diwanId);
    return (data as List).map((r) => r['user_id'] as String).toList();
  }

  // -------------------------------------------------------------------------
  // Speak requests
  // -------------------------------------------------------------------------

  /// Real-time stream of pending speak requests for a diwan (host use only).
  Stream<List<SpeakRequest>> watchSpeakRequests(String diwanId) {
    return _client
        .from(_requestsTable)
        .stream(primaryKey: ['id'])
        .order('requested_at')
        .map(
          (rows) => rows
              .where(
                (r) => r['diwan_id'] == diwanId && r['status'] == 'pending',
              )
              .map(SpeakRequest.fromMap)
              .toList(),
        );
  }
}
