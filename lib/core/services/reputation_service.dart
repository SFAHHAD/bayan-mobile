import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/trust_score.dart';

/// Calculates and caches a user's Trust Score using the
/// [calculate_trust_score] SQL RPC.
class ReputationService {
  final SupabaseClient _client;

  ReputationService(this._client);

  // In-memory cache: userId → TrustScore
  final Map<String, TrustScore> _cache = {};

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Fetches (or returns cached) Trust Score for [userId].
  Future<TrustScore> getTrustScore(String userId) async {
    if (_cache.containsKey(userId)) return _cache[userId]!;
    return _refreshScore(userId);
  }

  /// Forces a fresh calculation from the DB.
  Future<TrustScore> refreshTrustScore(String userId) async {
    return _refreshScore(userId);
  }

  /// Convenience: fetch the current user's own Trust Score.
  Future<TrustScore?> getMyTrustScore() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    return getTrustScore(uid);
  }

  /// Returns the [TrustTier] for [userId] without exposing the raw score.
  Future<TrustTier> getTrustTier(String userId) async {
    final ts = await getTrustScore(userId);
    return ts.tier;
  }

  /// Evicts the cache for [userId] (call after any activity that changes score).
  void invalidate(String userId) => _cache.remove(userId);

  /// Clears the entire in-memory cache.
  void clearCache() => _cache.clear();

  // -------------------------------------------------------------------------
  // Internal
  // -------------------------------------------------------------------------

  Future<TrustScore> _refreshScore(String userId) async {
    try {
      final raw = await _client.rpc(
        'calculate_trust_score',
        params: {'p_user_id': userId},
      );
      if (raw == null) {
        final zero = TrustScore.zero(userId);
        _cache[userId] = zero;
        return zero;
      }
      final score = TrustScore.fromMap(
        userId,
        Map<String, dynamic>.from(raw as Map),
      );
      _cache[userId] = score;
      return score;
    } catch (_) {
      final zero = TrustScore.zero(userId);
      _cache[userId] = zero;
      return zero;
    }
  }
}
