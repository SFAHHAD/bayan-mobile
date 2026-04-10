import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/invitation.dart';

class InvalidInvitationException implements Exception {
  final String message;
  const InvalidInvitationException(this.message);
  @override
  String toString() => 'InvalidInvitationException: $message';
}

class InvitationRepository {
  final SupabaseClient _client;

  const InvitationRepository(this._client);

  static const _table = 'invitations';

  /// Returns the invitation if the code is valid and unused, throws otherwise.
  Future<Invitation> validateCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    final data = await _client
        .from(_table)
        .select()
        .eq('code', trimmed)
        .eq('is_used', false)
        .maybeSingle();

    if (data == null) {
      throw const InvalidInvitationException(
        'رمز الدعوة غير صحيح أو مستخدم مسبقاً',
      );
    }

    final invitation = Invitation.fromMap(data);
    if (invitation.isExpired) {
      throw const InvalidInvitationException('رمز الدعوة منتهي الصلاحية');
    }
    return invitation;
  }

  /// Marks the code as used by [userId].
  /// The DB trigger auto-deletes the row after this update.
  Future<void> redeemCode(String code, String userId) async {
    await _client
        .from(_table)
        .update({'used_by': userId, 'is_used': true})
        .eq('code', code.trim().toUpperCase())
        .eq('is_used', false);
  }

  /// Returns all invitation codes that were generated for [userId] (as founder).
  Future<List<Invitation>> getMyGeneratedCodes(String userId) async {
    final data = await _client
        .from(_table)
        .select()
        .eq('created_by', userId)
        .order('created_at', ascending: false);
    return data.map(Invitation.fromMap).toList();
  }

  /// Calls the server-side RPC to generate 3 founder codes.
  /// Returns the new codes.
  Future<List<String>> generateFounderCodes(String userId) async {
    final data =
        await _client.rpc(
              'generate_founder_codes',
              params: {'p_user_id': userId},
            )
            as List<dynamic>;
    return data.map((e) => e as String).toList();
  }
}
