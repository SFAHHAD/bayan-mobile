import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/user_stats.dart';

class AnalyticsRepository {
  final SupabaseClient _client;

  const AnalyticsRepository(this._client);

  // -------------------------------------------------------------------------
  // User stats
  // -------------------------------------------------------------------------

  /// Fetches the prestige/analytics stats for [userId] via `get_user_stats` RPC.
  Future<UserStats> getUserStats(String userId) async {
    final data =
        await _client.rpc('get_user_stats', params: {'p_user_id': userId})
            as List<dynamic>;

    if (data.isEmpty) return UserStats.empty(userId);
    return UserStats.fromMap(data.first as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // Diwan-level stats
  // -------------------------------------------------------------------------

  /// Returns key metrics for a specific diwan (peak listeners, host minutes).
  Future<Map<String, dynamic>> getDiwanStats(String diwanId) async {
    final data = await _client
        .from('diwans')
        .select(
          'id, title, listener_count, voice_count, peak_listener_count, host_minutes',
        )
        .eq('id', diwanId)
        .maybeSingle();

    return data ?? {};
  }

  // -------------------------------------------------------------------------
  // Leaderboard helpers
  // -------------------------------------------------------------------------

  /// Returns the top [limit] profiles by influence score (follower_count*3 + voice_count*5).
  Future<List<UserStats>> getTopByInfluence({int limit = 10}) async {
    final data = await _client
        .from('user_stats')
        .select()
        .order('influence_score', ascending: false)
        .limit(limit);

    return (data as List)
        .map((r) => UserStats.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Returns the top [limit] profiles by peak listeners ever.
  Future<List<UserStats>> getTopByPeakListeners({int limit = 10}) async {
    final data = await _client
        .from('user_stats')
        .select()
        .order('peak_listeners_ever', ascending: false)
        .limit(limit);

    return (data as List)
        .map((r) => UserStats.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}
