import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/app_notification.dart';

class NotificationService {
  final SupabaseClient _client;

  const NotificationService(this._client);

  static const _table = 'notifications';

  // -------------------------------------------------------------------------
  // Fetch
  // -------------------------------------------------------------------------

  Future<List<AppNotification>> fetchNotifications(
    String userId, {
    int limit = 50,
  }) async {
    final data = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((r) => AppNotification.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount(String userId) async {
    final data = await _client
        .from(_table)
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
    return (data as List).length;
  }

  // -------------------------------------------------------------------------
  // Mark as read
  // -------------------------------------------------------------------------

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from(_table)
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _client
        .from(_table)
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  // -------------------------------------------------------------------------
  // Real-time stream
  // -------------------------------------------------------------------------

  /// Streams all notifications for [userId], newest first.
  /// Updates automatically when new notifications are inserted or read status changes.
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map(
          (rows) =>
              rows.map(AppNotification.fromMap).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }
}
