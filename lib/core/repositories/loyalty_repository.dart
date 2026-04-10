import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/user_activity_metrics.dart';

class LoyaltyRepository {
  final SupabaseClient _client;

  const LoyaltyRepository(this._client);

  static const _table = 'user_activity_metrics';

  // -------------------------------------------------------------------------
  // Metrics
  // -------------------------------------------------------------------------

  Future<UserActivityMetrics?> fetchMyMetrics() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final data = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) return null;
    return UserActivityMetrics.fromMap(data);
  }

  Stream<UserActivityMetrics?> watchMyMetrics() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();
    return _client
        .from(_table)
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map(
          (rows) =>
              rows.isEmpty ? null : UserActivityMetrics.fromMap(rows.first),
        );
  }

  // -------------------------------------------------------------------------
  // Daily check-in
  // -------------------------------------------------------------------------

  Future<CheckinResult> dailyCheckin() async {
    final raw = await _client.rpc('daily_checkin');
    final map = Map<String, dynamic>.from(raw as Map);
    return CheckinResult.fromMap(map);
  }

  // -------------------------------------------------------------------------
  // XP / activity
  // -------------------------------------------------------------------------

  Future<void> addMinutesListened(int minutes) async {
    if (minutes <= 0) return;
    await _client.rpc('add_minutes_listened', params: {'p_minutes': minutes});
  }

  Future<Map<String, dynamic>?> addEngagementXp(
    int xp, {
    String source = 'activity',
  }) async {
    if (xp <= 0) return null;
    final raw = await _client.rpc(
      'add_engagement_xp',
      params: {'p_xp': xp, 'p_source': source},
    );
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  // -------------------------------------------------------------------------
  // Leaderboard
  // -------------------------------------------------------------------------

  Future<List<UserActivityMetrics>> fetchLeaderboard({int limit = 20}) async {
    final data = await _client
        .from(_table)
        .select(
          'user_id, engagement_xp, current_level, daily_streak, prestige_tokens, updated_at',
        )
        .order('engagement_xp', ascending: false)
        .limit(limit);
    return (data as List)
        .map(
          (r) => UserActivityMetrics.fromMap({
            ...r as Map<String, dynamic>,
            'total_minutes_listened': 0,
            'longest_streak': 0,
          }),
        )
        .toList();
  }
}
