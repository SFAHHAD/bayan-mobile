class Profile {
  final String id;
  final String? username;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final DateTime createdAt;

  const Profile({
    required this.id,
    this.username,
    this.displayName,
    this.bio,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      username: map['username'] as String?,
      displayName: map['display_name'] as String?,
      bio: map['bio'] as String?,
      avatarUrl: map['avatar_url'] as String?,
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
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
