import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/verification_request.dart';

class VerificationRepository {
  final SupabaseClient _client;

  const VerificationRepository(this._client);

  static const _table = 'verification_requests';

  // -------------------------------------------------------------------------
  // Submit / update
  // -------------------------------------------------------------------------

  /// Submits (or re-submits) a verification request for the current user.
  /// Uses the `submit_verification_request` RPC which upserts on user_id.
  Future<bool> submitRequest({
    required List<String> documentsUrls,
    required String professionalTitle,
    required String verifiedCategory,
  }) async {
    final result =
        await _client.rpc(
              'submit_verification_request',
              params: {
                'p_documents_urls': documentsUrls,
                'p_professional_title': professionalTitle,
                'p_verified_category': verifiedCategory,
              },
            )
            as Map<String, dynamic>;
    return result['success'] == true;
  }

  // -------------------------------------------------------------------------
  // Queries
  // -------------------------------------------------------------------------

  Future<VerificationRequest?> getMyRequest() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) return null;
    return VerificationRequest.fromMap(data);
  }

  Future<VerificationRequest?> getRequestByUserId(String userId) async {
    final data = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) return null;
    return VerificationRequest.fromMap(data);
  }

  // -------------------------------------------------------------------------
  // Admin: review (calls SECURITY DEFINER RPC)
  // -------------------------------------------------------------------------

  Future<bool> adminReview({
    required String requestId,
    required String decision, // 'approved' | 'rejected'
    String? notes,
  }) async {
    final result =
        await _client.rpc(
              'admin_review_verification',
              params: {
                'p_request_id': requestId,
                'p_decision': decision,
                'p_notes': notes,
              },
            )
            as Map<String, dynamic>;
    return result['success'] == true;
  }

  /// Fetches all pending verification requests (admin use-case).
  Future<List<VerificationRequest>> getPendingRequests() async {
    final data = await _client
        .from(_table)
        .select()
        .inFilter('status', ['pending', 'under_review'])
        .order('created_at', ascending: true);
    return (data as List)
        .map((r) => VerificationRequest.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Real-time stream (user watches their own request status)
  // -------------------------------------------------------------------------

  Stream<VerificationRequest?> watchMyRequest() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _client.from(_table).stream(primaryKey: ['id']).map((rows) {
      final match = rows.where((r) => r['user_id'] == userId).toList();
      if (match.isEmpty) return null;
      return VerificationRequest.fromMap(match.first);
    });
  }
}
