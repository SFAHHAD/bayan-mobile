enum NotificationType {
  diwanLive,
  newFollower,
  speakApproved,
  speakRejected,
  voiceClipShared,
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    this.data = const {},
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
      default:
        return NotificationType.diwanLive;
    }
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      data: data,
      createdAt: createdAt,
    );
  }
}
