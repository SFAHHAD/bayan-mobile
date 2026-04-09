class Diwan {
  final String id;
  final String title;
  final String? description;
  final String? ownerId;
  final String? hostName;
  final bool isPublic;
  final bool isLive;
  final int listenerCount;
  final int voiceCount;
  final String? coverUrl;
  final DateTime? lastActivityAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Diwan({
    required this.id,
    required this.title,
    this.description,
    this.ownerId,
    this.hostName,
    this.isPublic = true,
    this.isLive = false,
    this.listenerCount = 0,
    this.voiceCount = 0,
    this.coverUrl,
    this.lastActivityAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Diwan.fromMap(Map<String, dynamic> map) {
    return Diwan(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      ownerId: map['owner_id'] as String?,
      hostName: map['host_name'] as String?,
      isPublic: (map['is_public'] as bool?) ?? true,
      isLive: (map['is_live'] as bool?) ?? false,
      listenerCount: (map['listener_count'] as int?) ?? 0,
      voiceCount: (map['voice_count'] as int?) ?? 0,
      coverUrl: map['cover_url'] as String?,
      lastActivityAt: map['last_activity_at'] != null
          ? DateTime.parse(map['last_activity_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'owner_id': ownerId,
      'host_name': hostName,
      'is_public': isPublic,
      'is_live': isLive,
      'listener_count': listenerCount,
      'voice_count': voiceCount,
      'cover_url': coverUrl,
    };
  }

  Diwan copyWith({
    String? id,
    String? title,
    String? description,
    String? ownerId,
    String? hostName,
    bool? isPublic,
    bool? isLive,
    int? listenerCount,
    int? voiceCount,
    String? coverUrl,
    DateTime? lastActivityAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Diwan(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      hostName: hostName ?? this.hostName,
      isPublic: isPublic ?? this.isPublic,
      isLive: isLive ?? this.isLive,
      listenerCount: listenerCount ?? this.listenerCount,
      voiceCount: voiceCount ?? this.voiceCount,
      coverUrl: coverUrl ?? this.coverUrl,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
