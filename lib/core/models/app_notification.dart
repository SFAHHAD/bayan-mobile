enum NotificationType {
  diwanLive,
  newFollower,
  speakApproved,
  speakRejected,
  voiceClipShared,
  seriesNewEpisode,
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final Map<String, dynamic> data;
  final String? actionUrl;
  final String? actionType;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    this.data = const {},
    this.actionUrl,
    this.actionType,
    this.metadata = const {},
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: _typeFromString(map['type'] as String? ?? ''),
      title: map['title'] as String,
      body: map['body'] as String? ?? '',
      isRead: (map['is_read'] as bool?) ?? false,
      data: (map['data'] as Map<String, dynamic>?) ?? {},
      actionUrl: map['action_url'] as String?,
      actionType: map['action_type'] as String?,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static NotificationType _typeFromString(String s) {
    switch (s) {
      case 'diwan_live':
        return NotificationType.diwanLive;
      case 'new_follower':
        return NotificationType.newFollower;
      case 'speak_approved':
        return NotificationType.speakApproved;
      case 'speak_rejected':
        return NotificationType.speakRejected;
      case 'voice_clip_shared':
        return NotificationType.voiceClipShared;
      case 'series_new_episode':
        return NotificationType.seriesNewEpisode;
      default:
        return NotificationType.diwanLive;
    }
  }

  AppNotification copyWith({bool? isRead, String? actionUrl}) {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      data: data,
      actionUrl: actionUrl ?? this.actionUrl,
      actionType: actionType,
      metadata: metadata,
      createdAt: createdAt,
    );
  }
}
