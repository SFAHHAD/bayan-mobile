import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/rate_limit_result.dart';

/// Provides dynamic rate-limiting and mock read-replica routing to handle
/// burst traffic (e.g. celebrity host joins).
class RateLimiterService {
  final SupabaseClient _client;

  RateLimiterService(this._client);

  // -------------------------------------------------------------------------
  // Rate limiting — calls check_rate_limit RPC
  // -------------------------------------------------------------------------

  /// Checks whether [action] for [bucketKey] is within the allowed rate.
  ///
  /// Returns a [RateLimitResult] describing whether the action is allowed,
  /// how many hits remain, and when the window resets.
  Future<RateLimitResult> checkLimit({
    required String bucketKey,
    required String action,
    int limit = 10,
    int windowSeconds = 60,
  }) async {
    try {
      final raw = await _client.rpc(
        'check_rate_limit',
        params: {
          'p_bucket_key': bucketKey,
          'p_action': action,
          'p_limit': limit,
          'p_window_secs': windowSeconds,
        },
      );
      if (raw == null) return RateLimitResult.open();
      return RateLimitResult.fromMap(Map<String, dynamic>.from(raw as Map));
    } catch (_) {
      return RateLimitResult.open();
    }
  }

  /// Convenience: check rate limit keyed by [userId] and [action].
  Future<RateLimitResult> checkUserLimit({
    required String userId,
    required String action,
    int limit = 10,
    int windowSeconds = 60,
  }) => checkLimit(
    bucketKey: 'user:$userId:$action',
    action: action,
    limit: limit,
    windowSeconds: windowSeconds,
  );

  /// Convenience: check rate limit keyed by [diwanId] for join events.
  Future<RateLimitResult> checkDiwanJoinLimit({
    required String diwanId,
    int limit = 500,
    int windowSeconds = 60,
  }) => checkLimit(
    bucketKey: 'diwan:$diwanId',
    action: 'join',
    limit: limit,
    windowSeconds: windowSeconds,
  );

  /// Enables burst mode for a diwan when a celebrity host joins.
  Future<void> enableBurstMode(String diwanId, {int multiplier = 5}) async {
    try {
      await _client.rpc(
        'enable_burst_mode',
        params: {'p_diwan_id': diwanId, 'p_multiplier': multiplier},
      );
    } catch (_) {}
  }

  // -------------------------------------------------------------------------
  // Mock read-replica routing
  // -------------------------------------------------------------------------

  /// Returns the replica ID that should handle this read.
  Future<String> getBestReplica() async {
    try {
      final raw = await _client.rpc('get_best_replica');
      return (raw as String?) ?? 'replica-primary';
    } catch (_) {
      return 'replica-primary';
    }
  }

  /// Mock: returns a simulated replica URL for the given replica ID.
  /// In production this would be replaced by a real PgBouncer / pgpool URL.
  String replicaUrl(String replicaId) {
    const urls = {
      'replica-primary': 'postgresql://primary.db.bayan.app:5432/bayan',
      'replica-us-west': 'postgresql://us-west.db.bayan.app:5432/bayan',
      'replica-eu-west': 'postgresql://eu-west.db.bayan.app:5432/bayan',
      'replica-ap-south': 'postgresql://ap-south.db.bayan.app:5432/bayan',
    };
    return urls[replicaId] ?? urls['replica-primary']!;
  }
}
