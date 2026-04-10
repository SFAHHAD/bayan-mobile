class Follow {
  final String followerId;
  final String followingId;
  final DateTime createdAt;

  const Follow({
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  factory Follow.fromMap(Map<String, dynamic> map) {
    return Follow(
      followerId: map['follower_id'] as String,
      followingId: map['following_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'follower_id': followerId,
    'following_id': followingId,
    'created_at': createdAt.toIso8601String(),
  };
}
