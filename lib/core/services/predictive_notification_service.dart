import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/notification_prediction.dart';

/// Analyzes user activity patterns and predicts the optimal hour to send
/// 'Live Now' push notifications for each user individually.
class PredictiveNotificationService {
  final SupabaseClient _client;

  PredictiveNotificationService(this._client);

  // In-memory cache: userId → prediction
  final Map<String, NotificationPrediction> _cache = {};

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Returns cached (or freshly fetched) prediction for [userId].
  Future<NotificationPrediction> getPrediction(String userId) async {
    if (_cache.containsKey(userId)) return _cache[userId]!;
    return _refreshPrediction(userId);
  }

  /// Forces a fresh prediction from the DB.
  Future<NotificationPrediction> refreshPrediction(String userId) =>
      _refreshPrediction(userId);

  /// Convenience: prediction for the currently signed-in user.
  Future<NotificationPrediction?> getMyPrediction() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    return getPrediction(uid);
  }

  /// Returns true if [at] falls within the optimal notification window
  /// (±1 hour of [bestHour]) for [userId].
  Future<bool> isWithinOptimalWindow(String userId, {DateTime? at}) async {
    final pred = await getPrediction(userId);
    return pred.isWithinOptimalWindow(at: at);
  }

  /// Pure-logic version — does not touch the network.
  /// Useful for UI previews and unit tests.
  static bool isTimeInOptimalWindow(int bestHour, DateTime at) {
    final diff = ((at.hour - bestHour) % 24).abs();
    return diff <= 1 || diff >= 23;
  }

  /// Batch: predict best hours for a list of user IDs.
  /// Returns a map of userId → [NotificationPrediction].
  Future<Map<String, NotificationPrediction>> batchPredict(
    List<String> userIds,
  ) async {
    final results = <String, NotificationPrediction>{};
    for (final uid in userIds) {
      results[uid] = await getPrediction(uid);
    }
    return results;
  }

  void invalidate(String userId) => _cache.remove(userId);
  void clearCache() => _cache.clear();

  // -------------------------------------------------------------------------
  // Internal
  // -------------------------------------------------------------------------

  Future<NotificationPrediction> _refreshPrediction(String userId) async {
    try {
      final raw = await _client.rpc(
        'predict_best_notification_hour',
        params: {'p_user_id': userId},
      );
      if (raw == null) {
        final def = NotificationPrediction.defaultPrediction();
        _cache[userId] = def;
        return def;
      }
      final pred = NotificationPrediction.fromMap(
        Map<String, dynamic>.from(raw as Map),
      );
      _cache[userId] = pred;
      return pred;
    } catch (_) {
      final def = NotificationPrediction.defaultPrediction();
      _cache[userId] = def;
      return def;
    }
  }
}
