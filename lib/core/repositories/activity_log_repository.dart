import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/activity_log.dart';

class ActivityLogRepository {
  final SupabaseClient _client;

  const ActivityLogRepository(this._client);

  static const _table = 'activity_logs';

  // -------------------------------------------------------------------------
  // Write
  // -------------------------------------------------------------------------

  Future<void> log(
    ActivityLogType type, {
    Map<String, dynamic> metadata = const {},
  }) async {
    await _client.rpc(
      'log_activity',
      params: {
        'p_action_type': ActivityLog.typeToString(type),
        'p_metadata': metadata,
      },
    );
  }

  Future<void> logJoinedDiwan(String diwanId, {String? seriesId}) async {
    await log(
      ActivityLogType.joinedDiwan,
      metadata: {'diwan_id': diwanId, 'series_id': seriesId},
    );
  }

  Future<void> logPurchasedTicket(String diwanId, int price) async {
    await log(
      ActivityLogType.purchasedTicket,
      metadata: {'diwan_id': diwanId, 'price': price},
    );
  }

  Future<void> logFollowedUser(String targetUserId) async {
    await log(
      ActivityLogType.followedUser,
      metadata: {'target_user_id': targetUserId},
    );
  }

  Future<void> logUnfollowedUser(String targetUserId) async {
    await log(
      ActivityLogType.unfollowedUser,
      metadata: {'target_user_id': targetUserId},
    );
  }

  // -------------------------------------------------------------------------
  // Read
  // -------------------------------------------------------------------------

  Future<List<ActivityLog>> getMyHistory({
    int limit = 100,
    ActivityLogType? filterType,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    var query = _client.from(_table).select().eq('user_id', userId);

    if (filterType != null) {
      query = query.eq('action_type', ActivityLog.typeToString(filterType));
    }

    final data = await query.order('created_at', ascending: false).limit(limit);
    return (data as List)
        .map((r) => ActivityLog.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Privacy controls
  // -------------------------------------------------------------------------

  /// Permanently deletes all activity logs for the current user.
  Future<void> clearHistory() async {
    await _client.rpc('clear_activity_history');
  }
}
