import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/models/app_notification.dart';
import 'package:bayan/core/models/deep_link.dart';

class NotificationService {
  final SupabaseClient _client;

  const NotificationService(this._client);

  // -------------------------------------------------------------------------
  // FCM token management
  // -------------------------------------------------------------------------

  /// Registers (or refreshes) the device FCM token for the current user.
  /// [platform] must be 'android', 'ios', or 'web'.
  Future<void> registerFcmToken(String token, String platform) async {
    await _client.rpc(
      'upsert_fcm_token',
      params: {'p_token': token, 'p_platform': platform},
    );
  }

  /// Deactivates a FCM token (on logout or token rotation).
  Future<void> revokeFcmToken(String token) async {
    await _client.rpc('revoke_fcm_token', params: {'p_token': token});
  }

  /// Returns active FCM tokens for the current user (for server fanout).
  Future<List<String>> fetchMyFcmTokens() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from('user_fcm_tokens')
        .select('token')
        .eq('user_id', userId)
        .eq('is_active', true);
    return (data as List)
        .map((r) => (r as Map<String, dynamic>)['token'] as String)
        .toList();
  }

  static const _table = 'notifications';

  // Interactive notification action types
  // These map to the `action_type` column added in migration 010
  static const actionOpen = 'open';
  static const actionJoinDiwan = 'join_diwan';
  static const actionViewProfile = 'view_profile';
  static const actionViewSeries = 'view_series';

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
  // Interactive action routing
  // -------------------------------------------------------------------------

  /// Converts a notification's [actionUrl] into a typed [DeepLink].
  /// Returns `null` if the URL cannot be parsed.
  DeepLink? resolveActionLink(AppNotification notification) {
    final url = notification.actionUrl;
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    return DeepLink.fromUri(uri);
  }

  /// Handles a tap on an interactive notification action.
  /// Marks the notification as read and returns the resolved [DeepLink].
  Future<DeepLink?> handleNotificationTap(AppNotification notification) async {
    await markAsRead(notification.id);
    return resolveActionLink(notification);
  }

  // -------------------------------------------------------------------------
  // Insert helpers (called server-side or from Edge Functions)
  // -------------------------------------------------------------------------

  /// Inserts a single in-app notification with optional action metadata.
  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? actionUrl,
    String actionType = actionOpen,
    Map<String, dynamic> metadata = const {},
  }) async {
    await _client.from(_table).insert({
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'action_url': actionUrl,
      'action_type': actionType,
      'metadata': metadata,
    });
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
