class Profile {
  final String id;
  final String? username;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final bool isFounder;
  final bool isVerified;
  final bool isSovereign;
  final int level;
  final String? professionalTitle;
  final String? verifiedCategory;
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
    this.isVerified = false,
    this.isSovereign = false,
    this.level = 0,
    this.professionalTitle,
    this.verifiedCategory,
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
      isVerified: (map['is_verified'] as bool?) ?? false,
      isSovereign: (map['is_sovereign'] as bool?) ?? false,
      level: (map['level'] as int?) ?? 0,
      professionalTitle: map['professional_title'] as String?,
      verifiedCategory: map['verified_category'] as String?,
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
    bool? isVerified,
    bool? isSovereign,
    int? level,
    String? professionalTitle,
    String? verifiedCategory,
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
      isVerified: isVerified ?? this.isVerified,
      isSovereign: isSovereign ?? this.isSovereign,
      level: level ?? this.level,
      professionalTitle: professionalTitle ?? this.professionalTitle,
      verifiedCategory: verifiedCategory ?? this.verifiedCategory,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      voiceCount: voiceCount ?? this.voiceCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
