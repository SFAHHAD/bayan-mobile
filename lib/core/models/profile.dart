class Profile {
  final String id;
  final String? username;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final bool isFounder;
  final int followerCount;
  final int followingCount;
  final int voiceCount;
  final DateTime createdAt;

  const Profile({
    required this.id,
    this.username,
    this.displayName,
    this.bio,
    this.avatarUrl,
    this.isFounder = false,
    this.followerCount = 0,
    this.followingCount = 0,
    this.voiceCount = 0,
    required this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      username: map['username'] as String?,
      displayName: map['display_name'] as String?,
      bio: map['bio'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      isFounder: (map['is_founder'] as bool?) ?? false,
      followerCount: (map['follower_count'] as int?) ?? 0,
      followingCount: (map['following_count'] as int?) ?? 0,
      voiceCount: (map['voice_count'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'display_name': displayName,
      'bio': bio,
      'avatar_url': avatarUrl,
    };
  }

  Profile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    bool? isFounder,
    int? followerCount,
    int? followingCount,
    int? voiceCount,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isFounder: isFounder ?? this.isFounder,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      voiceCount: voiceCount ?? this.voiceCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
